import Foundation
import Network
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LocalDiscovery")

/// Discovers Sentinel Mac instances on LAN via Bonjour (_sentinel._tcp)
/// and connects via raw TCP. Messages are newline-delimited JSON, same
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
    private var connection: NWConnection?
    private var buffer = Data()
    private var lastHost: String?
    private var lastPort: UInt16?
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
        let params = NWParameters.tcp
        connection = NWConnection(to: endpoint, using: params)

        connection?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                log.info("TCP connected to \(String(describing: endpoint))")
                Task { @MainActor in
                    self.isConnected = true
                    self.connectionError = nil
                    if case .service(let name, _, _, _) = endpoint {
                        self.discoveredHost = name
                    }
                }
                self.receiveLoop()
            case .failed(let error):
                log.error("TCP failed: \(error)")
                Task { @MainActor in
                    self.isConnected = false
                    self.connectionError = error.localizedDescription
                }
                self.scheduleReconnect()
            case .cancelled:
                Task { @MainActor in self.isConnected = false }
            default:
                break
            }
        }

        connection?.start(queue: .global(qos: .userInitiated))
    }

    /// Connect directly to IP:port (for manual entry)
    func connect(host: String, port: UInt16) {
        stopDiscovery()
        reconnectTask?.cancel()
        disconnect()

        lastHost = host
        lastPort = port

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            log.error("Invalid port: \(port)")
            Task { @MainActor in
                self.connectionError = "无效端口: \(port)"
            }
            return
        }
        let endpoint = NWEndpoint.hostPort(host: .init(host), port: nwPort)
        let params = NWParameters.tcp
        connection = NWConnection(to: endpoint, using: params)

        connection?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                log.info("TCP connected to \(host):\(port)")
                self.reconnectAttempts = 0
                Task { @MainActor in
                    self.isConnected = true
                    self.connectionError = nil
                    self.discoveredHost = host
                }
                self.receiveLoop()
            case .failed(let error):
                log.error("TCP connect failed: \(error)")
                Task { @MainActor in
                    self.isConnected = false
                    self.connectionError = error.localizedDescription
                }
                self.scheduleReconnect()
            case .cancelled:
                Task { @MainActor in self.isConnected = false }
            default:
                break
            }
        }

        connection?.start(queue: .global(qos: .userInitiated))
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

        reconnectTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self.connect(host: host, port: port)
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        connection?.cancel()
        connection = nil
        buffer = Data()
        Task { @MainActor in
            self.isConnected = false
            self.discoveredHost = nil
        }
    }

    // MARK: - Send (same JSON format as remote mode)

    func emit(_ event: String, dict: [String: Any]) {
        guard let connection, isConnected else { return }
        let msg: [String: Any] = ["event": event, "data": dict]
        guard var jsonData = try? JSONSerialization.data(withJSONObject: msg) else { return }
        jsonData.append(0x0A)
        connection.send(content: jsonData, completion: .contentProcessed({ error in
            if let error { log.error("Send failed: \(error)") }
        }))
    }

    // MARK: - Receive

    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }

            if let data = content {
                self.buffer.append(data)
                if self.buffer.count > Self.maxBufferSize {
                    log.error("Buffer exceeded \(Self.maxBufferSize) bytes, dropping connection")
                    self.buffer = Data()
                    self.connection?.cancel()
                    ErrorBus.shared.post( String(localized: "数据缓冲区溢出，连接已断开"),
                                         recovery: String(localized: "将自动重连"))
                    return
                }
                self.processBuffer()
            }

            if isComplete || error != nil {
                Task { @MainActor in self.isConnected = false }
                self.scheduleReconnect()
                return
            }

            self.receiveLoop()
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
