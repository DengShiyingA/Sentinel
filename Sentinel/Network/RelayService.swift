import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "RelayService")

@Observable
final class RelayService {
    private(set) var currentMode: ConnectionMode
    private(set) var isConnected = false
    var connectionError: String?

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
        transport?.disconnect()
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
        guard let local = local as? LocalDiscoveryService else { return }
        local.emit("user_message", dict: ["text": text])
        log.info("User message sent: \(text.prefix(50))")
    }

    func sendInterrupt() {
        guard let local = local as? LocalDiscoveryService else { return }
        local.emit("interrupt", dict: [:])
        log.info("Interrupt sent to Mac")
    }

    func sendSetModel(_ modelId: String) {
        guard let local = local as? LocalDiscoveryService else { return }
        local.emit("set_model", dict: ["model": modelId])
        log.info("Model change sent: \(modelId)")
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
