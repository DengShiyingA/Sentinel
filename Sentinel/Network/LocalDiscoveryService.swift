import Foundation
import Network
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LocalDiscovery")

/// Discovers Sentinel Mac instances on LAN via Bonjour (_sentinel._tcp)
/// and connects via WebSocket. Messages are newline-delimited JSON, same
/// event/data format as Socket.IO mode.
@Observable
final class LocalDiscoveryService {
    // MARK: - Public State

    var isConnected = false
    var isSearching = false
    var discoveredHost: String?
    var connectionError: String?

    // MARK: - Callbacks (same interface as SocketClient)

    var onEvent: ((String, Data) -> Void)?

    // MARK: - Private

    private var browser: NWBrowser?
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var buffer = Data()
    private var lastHost: String?
    private var lastPort: UInt16?
    private var lastScheme: String = "ws"
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    private static let maxBufferSize = SentinelConfig.maxBufferSize

    // MARK: - Discovery

    /// Start browsing for _sentinel._tcp Bonjour services
    func startDiscovery() {
        stopDiscovery()
        isSearching = true
        connectionError = nil

        let params = NWParameters()
        params.includePeerToPeer = true
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_sentinel._tcp", domain: nil)

        browser = NWBrowser(for: descriptor, using: params)

        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            for result in results {
                if case .service(let name, let type, let domain, _) = result.endpoint {
                    log.info("Found: \(name) (\(type).\(domain))")
                    self.resolveAndConnect(result: result)
                    return
                }
            }
        }

        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                log.info("Browsing for _sentinel._tcp")
            case .failed(let error):
                log.error("Browse failed: \(error)")
                Task { @MainActor in self.connectionError = error.localizedDescription }
            default:
                break
            }
        }

        browser?.start(queue: .main)
    }

    func stopDiscovery() {
        browser?.cancel()
        browser = nil
        isSearching = false
    }

    // MARK: - Connect

    private func resolveAndConnect(result: NWBrowser.Result) {
        stopDiscovery()

        let endpoint = result.endpoint
        // Probe the endpoint briefly just to get the resolved host:port
        let params = NWParameters.tcp
        let probe = NWConnection(to: endpoint, using: params)
        // Local flag shared by the state handler and the timeout task so that
        // whichever path resolves first wins and the other becomes a no-op.
        var resolved = false
        let timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            guard !resolved else { return }
            resolved = true
            log.error("Probe timed out after 5s")
            probe.cancel()
            self?.connectionError = String(localized: "无法解析服务地址")
        }
        probe.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if resolved { return }
                resolved = true
                timeoutTask.cancel()
                if case .hostPort(let host, let port) = probe.currentPath?.remoteEndpoint {
                    let hostStr = "\(host)"
                        .replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
                        // Strip the IPv6 zone suffix like "%en0" that Network framework adds
                        .split(separator: "%").first.map(String.init) ?? ""
                    probe.cancel()
                    Task { @MainActor in
                        self.connectWebSocket(host: hostStr, port: port.rawValue, scheme: "ws")
                    }
                } else {
                    probe.cancel()
                    Task { @MainActor in
                        self.connectionError = String(localized: "无法解析服务地址")
                    }
                }
            case .failed(let err):
                if resolved { return }
                resolved = true
                timeoutTask.cancel()
                log.error("Probe failed: \(err)")
                probe.cancel()
                Task { @MainActor in self.connectionError = err.localizedDescription }
            default:
                break
            }
        }
        probe.start(queue: .main)
    }

    /// Connect directly to IP:port (for manual entry)
    func connect(host: String, port: UInt16) {
        stopDiscovery()
        reconnectTask?.cancel()
        disconnect()
        connectWebSocket(host: host, port: port, scheme: "ws")
    }

    /// Connect directly to a WebSocket URL, bypassing Bonjour discovery.
    /// Used for remote access via Cloudflare Tunnel.
    /// - Parameters:
    ///   - urlString: Full URL like "wss://xxx.trycloudflare.com" (no path suffix required)
    ///   - publicKey: Optional base64 X25519 public key from pairing. Currently used only
    ///     as a log/verification hint; the actual handshake still happens over the WS the
    ///     same way LAN does. Remote peer verification is a future enhancement.
    func connectRemote(url urlString: String, publicKey: String? = nil) {
        stopDiscovery()
        reconnectTask?.cancel()
        disconnect()

        guard let url = URL(string: urlString) else {
            log.error("Invalid remote URL: \(urlString)")
            Task { @MainActor in
                self.connectionError = String(localized: "无效的远程地址")
            }
            return
        }

        // URL may or may not include explicit port. wss defaults to 443.
        let host = url.host ?? ""
        let port: UInt16 = UInt16(url.port ?? 443)
        let scheme = url.scheme ?? "wss"

        guard !host.isEmpty else {
            log.error("Remote URL missing host: \(urlString)")
            Task { @MainActor in
                self.connectionError = String(localized: "远程地址缺少主机名")
            }
            return
        }

        log.info("Connecting remote \(scheme)://\(host):\(port)")

        // Reuse the existing connectWebSocket helper.
        connectWebSocket(host: host, port: port, scheme: scheme)

        // publicKey is currently unused beyond logging. Remote peer verification
        // against the pairing key is a future enhancement; for now the handshake
        // still happens over the WebSocket the same way LAN does.
        if let publicKey {
            log.info("Remote peer public key hint: \(publicKey.prefix(16))...")
        }
    }

    private func connectWebSocket(host: String, port: UInt16, scheme: String) {
        guard let url = URL(string: "\(scheme)://\(host):\(port)/") else {
            log.error("Invalid URL: \(scheme)://\(host):\(port)")
            connectionError = "Invalid URL: \(scheme)://\(host):\(port)"
            return
        }
        log.info("Connecting WebSocket to \(url)")

        // Tear down any existing socket/session before creating a new one
        webSocket?.cancel(with: .goingAway, reason: nil)
        urlSession?.invalidateAndCancel()
        buffer = Data()

        let session = URLSession(configuration: .default)
        urlSession = session
        let task = session.webSocketTask(with: url)
        webSocket = task
        lastHost = host
        lastPort = port
        lastScheme = scheme
        task.resume()

        // NOTE: we do NOT set isConnected = true here. The WebSocket task is
        // resuming asynchronously and may still fail (DNS, TLS, refused
        // connection, etc). isConnected flips to true in receiveLoop() once
        // we actually receive our first frame from the server (the handshake).
        connectionError = nil
        discoveredHost = host
        reconnectAttempts = 0

        receiveLoop()
    }

    // MARK: - Auto Reconnect

    private func scheduleReconnect() {
        guard let host = lastHost, let port = lastPort else { return }
        guard reconnectAttempts < SentinelConfig.maxReconnectAttempts else {
            log.warning("Max reconnect attempts reached")
            return
        }

        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts - 1)), 30) // 1s, 2s, 4s, ... 30s

        log.info("Reconnecting in \(delay)s (attempt \(self.reconnectAttempts))")

        let scheme = lastScheme
        reconnectTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.connectWebSocket(host: host, port: port, scheme: scheme)
            }
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        buffer = Data()
        // Synchronous — disconnect() is already MainActor-isolated, so state
        // updates must happen immediately. A deferred Task { @MainActor in ... }
        // causes races where isConnected is still observed as true right after
        // disconnect() returns (e.g. in hybrid Phase1→Phase2 switch).
        isConnected = false
        discoveredHost = nil
    }

    // MARK: - Send (same JSON format as remote mode)

    func emit(_ event: String, dict: [String: Any]) {
        guard let webSocket, isConnected else { return }
        let msg: [String: Any] = ["event": event, "data": dict]
        guard var jsonData = try? JSONSerialization.data(withJSONObject: msg) else { return }
        jsonData.append(0x0A) // newline
        guard let text = String(data: jsonData, encoding: .utf8) else { return }
        webSocket.send(.string(text)) { error in
            if let error { log.error("Send failed: \(error)") }
        }
    }

    // MARK: - Receive

    private func receiveLoop() {
        guard let ws = webSocket else { return }
        ws.receive { [weak self] result in
            // URLSession delivers this on its own serial queue (not MainActor).
            // Bounce everything onto MainActor before touching `self` state.
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    // First successful frame means the server accepted our upgrade
                    // and is sending the handshake. Flip isConnected to true.
                    if !self.isConnected {
                        self.isConnected = true
                        self.connectionError = nil
                    }
                    var frameData: Data?
                    switch message {
                    case .string(let text):
                        frameData = text.data(using: .utf8)
                    case .data(let data):
                        frameData = data
                    @unknown default:
                        break
                    }
                    if let data = frameData {
                        self.buffer.append(data)
                        if self.buffer.count > Self.maxBufferSize {
                            log.error("Buffer exceeded \(Self.maxBufferSize) bytes, dropping connection")
                            self.buffer = Data()
                            self.webSocket?.cancel(with: .goingAway, reason: nil)
                            ErrorBus.shared.post(String(localized: "数据缓冲区溢出，连接已断开"),
                                                 recovery: String(localized: "将自动重连"))
                            self.isConnected = false
                            self.scheduleReconnect()
                            return
                        }
                        self.processBuffer()
                    }
                    self.receiveLoop()

                case .failure(let error):
                    log.error("WebSocket receive error: \(error.localizedDescription)")
                    self.isConnected = false
                    self.connectionError = error.localizedDescription
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func processBuffer() {
        // Split on newline (0x0A)
        while let newlineIndex = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer[buffer.startIndex..<newlineIndex]
            buffer = Data(buffer[(newlineIndex + 1)...])
            guard !lineData.isEmpty else { continue }

            // Try decrypt, then parse JSON
            var jsonDict: [String: Any]?
            if let lineStr = String(data: lineData, encoding: .utf8) {
                if lineStr.hasPrefix("{") {
                    // Plain JSON (handshake or unencrypted)
                    jsonDict = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
                } else if TransportEncryption.isEnabled, let decrypted = TransportEncryption.decrypt(lineStr) {
                    // Encrypted message
                    if let data = decrypted.data(using: .utf8) {
                        jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }
                }
            }

            guard let json = jsonDict, let event = json["event"] as? String else {
                continue
            }

            let payloadData: Data
            if let dataObj = json["data"] {
                payloadData = (try? JSONSerialization.data(withJSONObject: dataObj)) ?? Data()
            } else {
                payloadData = Data()
            }

            // Ensure callbacks run on MainActor for consistent threading
            let handler = onEvent
            Task { @MainActor in
                handler?(event, payloadData)
            }
        }
    }
}
