import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "RelayService")

@Observable
final class RelayService {
    private(set) var currentMode: ConnectionMode
    private(set) var isConnected = false
    var connectionError: String?
    /// Last IP discovered via Bonjour — reused for non-default-port terminals on the same Mac.
    var discoveredHost: String? { local.discoveredHost }

    private var transport: TransportProtocol?
    private var connectTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?

    private let socket: SocketClient
    private let local: LocalDiscoveryService
    private let pairing: PairingService

    var onRequest: ((ApprovalRequest) -> Void)?
    var onActivity: ((ActivityItem) -> Void)?
    var onDecisionSync: ((String) -> Void)?
    var onTerminal: ((String) -> Void)?
    var onWorkspaceInfo: ((_ cwd: String, _ hostname: String?) -> Void)?
    var onModel: ((String) -> Void)?
    var onBrowseResult: ((BrowseResult) -> Void)?

    init(socket: SocketClient, local: LocalDiscoveryService, pairing: PairingService) {
        self.socket = socket
        self.local = local
        self.pairing = pairing
        self.currentMode = ConnectionMode.current
    }

    func connectCurrentMode() {
        switchMode(currentMode)
    }

    func switchMode(_ mode: ConnectionMode) {
        // Cancel any pending connect and wait for teardown
        connectTask?.cancel()
        connectTask = nil

        // Tear down old — clear callbacks first to prevent stale events
        let oldTransport = transport
        oldTransport?.onRequest = nil
        oldTransport?.onActivity = nil
        oldTransport?.onDecisionSync = nil
        oldTransport?.onTerminal = nil
        oldTransport?.onWorkspaceInfo = nil
        oldTransport?.onModel = nil
        oldTransport?.onBrowseResult = nil
        oldTransport?.disconnect()
        transport = nil
        isConnected = false
        connectionError = nil

        // Update mode
        currentMode = mode
        ConnectionMode.current = mode

        // Create new transport
        let newTransport = TransportFactory.makeTransport(
            mode: mode,
            socket: socket,
            local: local,
            pairing: pairing
        )
        newTransport.onRequest = onRequest
        newTransport.onActivity = onActivity
        newTransport.onDecisionSync = onDecisionSync
        newTransport.onTerminal = onTerminal
        newTransport.onWorkspaceInfo = onWorkspaceInfo
        newTransport.onModel = onModel
        newTransport.onBrowseResult = onBrowseResult
        transport = newTransport

        // Connect async
        connectTask = Task { [weak self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await newTransport.connect() }
                    group.addTask {
                        try await Task.sleep(for: .seconds(SentinelConfig.connectTimeoutSeconds))
                        throw CancellationError()
                    }
                    try await group.next()
                    group.cancelAll()
                }
                await MainActor.run {
                    self?.isConnected = true
                    self?.startHeartbeat()
                }
                log.info("Connected via \(mode.rawValue)")
            } catch is CancellationError {
                log.warning("Connect timeout (\(mode.rawValue))")
                await MainActor.run { self?.connectionError = "连接超时" }
            } catch {
                log.error("Connect failed: \(error.localizedDescription)")
                await MainActor.run { self?.connectionError = error.localizedDescription }
            }
        }
    }

    func connectManual(host: String, port: UInt16) {
        connectTask?.cancel()

        // Clear callbacks on old transport first to prevent stale events
        let oldTransport = transport
        oldTransport?.onRequest = nil
        oldTransport?.onActivity = nil
        oldTransport?.onDecisionSync = nil
        oldTransport?.onTerminal = nil
        oldTransport?.onWorkspaceInfo = nil
        oldTransport?.onModel = nil
        oldTransport?.onBrowseResult = nil
        oldTransport?.disconnect()

        transport = nil
        isConnected = false
        connectionError = nil
        currentMode = .local
        ConnectionMode.current = .local

        let localTransport = LocalTransport(discovery: local)
        localTransport.onRequest = onRequest
        localTransport.onActivity = onActivity
        localTransport.onDecisionSync = onDecisionSync
        localTransport.onTerminal = onTerminal
        localTransport.onWorkspaceInfo = onWorkspaceInfo
        localTransport.onModel = onModel
        localTransport.onBrowseResult = onBrowseResult
        transport = localTransport

        local.connect(host: host, port: port)

        connectTask = Task { [weak self] in
            for _ in 0..<50 {
                if self?.local.isConnected == true {
                    await MainActor.run { self?.isConnected = true }
                    return
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
            await MainActor.run { self?.connectionError = "连接超时" }
        }
    }

    /// Connect to a terminal profile using the hybrid strategy:
    /// 1. If profile has LAN info (useBonjour or manual host), try that first for 5 seconds.
    /// 2. If LAN fails / times out AND profile has a remoteUrl, fall back to remote WSS.
    /// 3. If both fail, surface connectionError.
    func connectHybrid(profile: TerminalProfile) {
        // Cancel any pending connect
        connectTask?.cancel()
        connectTask = nil

        // Tear down existing transport — clear callbacks first to prevent stale events
        let oldTransport = transport
        oldTransport?.onRequest = nil
        oldTransport?.onActivity = nil
        oldTransport?.onDecisionSync = nil
        oldTransport?.onTerminal = nil
        oldTransport?.onWorkspaceInfo = nil
        oldTransport?.onModel = nil
        oldTransport?.onBrowseResult = nil
        oldTransport?.disconnect()
        transport = nil
        isConnected = false
        connectionError = nil
        currentMode = .local
        ConnectionMode.current = .local

        // Build a new LocalTransport wrapping the local discovery service
        let newTransport = LocalTransport(discovery: local)
        newTransport.onRequest = onRequest
        newTransport.onActivity = onActivity
        newTransport.onDecisionSync = onDecisionSync
        newTransport.onTerminal = onTerminal
        newTransport.onWorkspaceInfo = onWorkspaceInfo
        newTransport.onModel = onModel
        newTransport.onBrowseResult = onBrowseResult
        transport = newTransport

        connectTask = Task { [weak self] in
            guard let self else { return }

            // Phase 1: LAN attempt
            var lanTried = false
            if profile.useBonjour || !profile.host.isEmpty {
                lanTried = true
                await MainActor.run {
                    if profile.useBonjour {
                        self.local.startDiscovery()
                    } else {
                        let port = UInt16(profile.port)
                        self.local.connect(host: profile.host, port: port)
                    }
                }

                // Wait up to 5 seconds for LAN to connect
                for _ in 0..<50 {
                    if Task.isCancelled { return }
                    if self.local.isConnected {
                        await MainActor.run {
                            self.isConnected = true
                            self.connectionError = nil
                            self.startHeartbeat()
                        }
                        log.info("Hybrid: connected via LAN")
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }

                // LAN timed out — tear it down before trying remote
                await MainActor.run {
                    self.local.stopDiscovery()
                    self.local.disconnect()
                }
                log.warning("Hybrid: LAN attempt timed out")
            }

            // Phase 2: Remote fallback
            if let remoteUrl = profile.remoteUrl {
                await MainActor.run {
                    self.connectionError = lanTried
                        ? String(localized: "局域网未发现，正在尝试远程连接…")
                        : nil
                    self.local.connectRemote(url: remoteUrl, publicKey: profile.remotePublicKey)
                }

                for _ in 0..<50 {
                    if Task.isCancelled { return }
                    if self.local.isConnected {
                        await MainActor.run {
                            self.isConnected = true
                            self.connectionError = nil
                            self.startHeartbeat()
                        }
                        log.info("Hybrid: connected via remote WSS")
                        return
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }

            // Both failed (or remote not configured)
            if Task.isCancelled { return }
            await MainActor.run {
                self.connectionError = profile.hasRemote
                    ? String(localized: "无法连接终端（LAN 和远程均失败）")
                    : String(localized: "无法在局域网发现终端")
            }
            log.error("Hybrid: all connection attempts failed")
        }
    }

    func disconnect() {
        connectTask?.cancel()
        heartbeatTask?.cancel()
        heartbeatTask = nil
        transport?.disconnect()
        isConnected = false
        connectionError = nil
        log.info("Disconnected")
    }

    /// Periodically check if the transport is still alive.
    /// If the underlying connection drops without notification (zombie state),
    /// update isConnected so the UI reflects reality.
    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled, let self else { return }
                let transportAlive = self.transport?.isConnected ?? false
                if self.isConnected && !transportAlive {
                    await MainActor.run {
                        self.isConnected = false
                        self.connectionError = String(localized: "连接已断开")
                        log.warning("Heartbeat: transport dead, marking disconnected")
                    }
                    return
                }
            }
        }
    }

    func sendDecision(requestId: String, decision: Decision) {
        guard let transport else {
            Task { @MainActor in
                ErrorBus.shared.post("无法发送决策：未连接", source: "relay", recovery: "请检查连接状态")
            }
            return
        }
        Task {
            do {
                try await transport.sendDecision(requestId: requestId, decision: decision)
            } catch {
                await MainActor.run {
                    ErrorBus.shared.post("发送决策失败：\(error.localizedDescription)", source: "relay")
                }
            }
        }
    }

    func sendUserMessage(_ text: String) {
        local.emit("user_message", dict: ["text": text])
        log.info("User message sent: \(text.prefix(50))")
    }

    func sendInterrupt() {
        local.emit("interrupt", dict: [:])
        log.info("Interrupt sent to Mac")
    }

    func sendSetModel(_ modelId: String) {
        local.emit("set_model", dict: ["model": modelId])
        log.info("Model change sent: \(modelId)")
    }

    func sendSetCwd(_ path: String) {
        local.emit("set_cwd", dict: ["path": path])
        log.info("Directory change sent: \(path)")
    }

    func sendBrowseDir(_ path: String) {
        local.emit("browse_dir", dict: ["path": path])
    }

    func sendRulesUpdate(rules: [[String: Any]]) {
        guard let transport else { return }
        Task {
            do {
                try await transport.sendRulesUpdate(rules: rules)
                log.info("Rules synced to Mac (\(rules.count) rules)")
            } catch {
                await MainActor.run {
                    ErrorBus.shared.post("规则同步失败：\(error.localizedDescription)", source: "relay")
                }
            }
        }
    }
}
