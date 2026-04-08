import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "SocketClient")

/// Socket.IO protocol implementation over URLSessionWebSocketTask.
/// Handles EIO4 handshake, message framing (42["event", payload]), ping/pong, and auto-reconnect.
@Observable
final class SocketClient: NSObject {
    // MARK: - Public State

    var isConnected = false
    var connectionError: String?

    // MARK: - Callbacks

    var onEvent: ((String, Data) -> Void)?

    // MARK: - Private

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var serverURL: String = ""
    private var deviceId: String = ""

    private var pingInterval: TimeInterval = 25
    private var pingTimeout: TimeInterval = 20
    private var pingTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var intentionalDisconnect = false

    // Socket.IO session id
    private var sid: String?

    // MARK: - Connect

    func connect(serverURL: String, deviceId: String) {
        self.serverURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.deviceId = deviceId
        intentionalDisconnect = false
        reconnectAttempts = 0
        openWebSocket()
    }

    func disconnect() {
        intentionalDisconnect = true
        pingTask?.cancel()
        reconnectTask?.cancel()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        isConnected = false
        sid = nil
    }

    // MARK: - Emit

    /// Send a Socket.IO event: 42["event", payload]
    func emit(_ event: String, _ payload: any Encodable) {
        guard let webSocket else { return }

        do {
            let payloadData = try JSONEncoder.sentinelEncoder.encode(payload)
            guard let payloadString = String(data: payloadData, encoding: .utf8) else { return }

            // Socket.IO message format: 42["eventName",{payload}]
            let message = "42[\"\(event)\",\(payloadString)]"
            webSocket.send(.string(message)) { error in
                if let error {
                    log.error("Emit failed for \(event): \(error.localizedDescription)")
                }
            }
            log.debug("Emit: \(event)")
        } catch {
            log.error("Encode failed for \(event): \(error.localizedDescription)")
        }
    }

    /// Emit with raw dictionary
    func emit(_ event: String, dict: [String: Any]) {
        guard let webSocket else { return }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let message = "42[\"\(event)\",\(jsonString)]"
        webSocket.send(.string(message)) { error in
            if let error {
                log.error("Emit failed for \(event): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - WebSocket Lifecycle

    private func openWebSocket() {
        // Socket.IO EIO4 WebSocket URL
        let wsScheme = serverURL.hasPrefix("https") ? "wss" : "ws"
        let host = serverURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        let urlString = "\(wsScheme)://\(host)/socket.io/?EIO=4&transport=websocket"

        guard let url = URL(string: urlString) else {
            connectionError = "Invalid server URL"
            return
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()
        receiveMessage()
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage() // Continue receiving
            case .failure(let error):
                log.error("Receive error: \(error.localizedDescription)")
                self.handleDisconnect()
            }
        }
    }

    // MARK: - Socket.IO Protocol (EIO4)
    //
    // Engine.IO packet types:
    //   0 = open    (server → client, contains JSON with sid, pingInterval, pingTimeout)
    //   1 = close
    //   2 = ping    (client → server)
    //   3 = pong    (server → client)
    //   4 = message (wraps Socket.IO packets)
    //
    // Socket.IO packet types (prefixed after '4'):
    //   0 = CONNECT
    //   1 = DISCONNECT
    //   2 = EVENT      → 42["eventName", payload]
    //   3 = ACK

    private func handleMessage(_ raw: String) {
        guard let first = raw.first else { return }

        switch first {
        // Engine.IO "open" packet
        case "0":
            handleOpen(String(raw.dropFirst()))

        // Engine.IO "pong"
        case "3":
            log.debug("Pong received")

        // Engine.IO "message" → Socket.IO packet
        case "4":
            handleSocketIOPacket(String(raw.dropFirst()))

        default:
            log.debug("Unknown EIO packet: \(raw.prefix(20))")
        }
    }

    private func handleOpen(_ json: String) {
        // Parse: {"sid":"xxx","upgrades":[],"pingInterval":25000,"pingTimeout":20000}
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        sid = obj["sid"] as? String
        if let pi = obj["pingInterval"] as? Double { pingInterval = pi / 1000 }
        if let pt = obj["pingTimeout"] as? Double { pingTimeout = pt / 1000 }

        log.info("EIO open, sid=\(self.sid ?? "nil"), pingInterval=\(self.pingInterval)s")

        // Send Socket.IO CONNECT packet: 40
        webSocket?.send(.string("40")) { _ in }

        startPing()
    }

    private func handleSocketIOPacket(_ packet: String) {
        guard let first = packet.first else { return }

        switch first {
        // Socket.IO CONNECT ACK: 0{"sid":"..."}
        case "0":
            Task { @MainActor in
                self.isConnected = true
                self.connectionError = nil
                self.reconnectAttempts = 0
            }
            log.info("Socket.IO connected")

        // Socket.IO EVENT: 2["event", payload]
        case "2":
            parseEvent(String(packet.dropFirst()))

        // Socket.IO DISCONNECT
        case "1":
            handleDisconnect()

        default:
            log.debug("Unknown SIO packet type: \(first)")
        }
    }

    private func parseEvent(_ body: String) {
        // body = ["eventName", {payload}]
        guard let data = body.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let event = array.first as? String else {
            return
        }

        log.debug("Event received: \(event)")

        // Extract payload (second element, re-serialize to Data)
        var payloadData = Data()
        if array.count > 1, let payloadObj = array[safe: 1] {
            payloadData = (try? JSONSerialization.data(withJSONObject: payloadObj)) ?? Data()
        }

        onEvent?(event, payloadData)
    }

    // MARK: - Ping

    private func startPing() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.pingInterval ?? 25))
                if Task.isCancelled { break }
                self?.webSocket?.send(.string("2")) { _ in } // EIO ping
            }
        }
    }

    // MARK: - Reconnect

    private func handleDisconnect() {
        Task { @MainActor in
            self.isConnected = false
        }
        pingTask?.cancel()
        webSocket = nil
        sid = nil

        guard !intentionalDisconnect else { return }
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            Task { @MainActor in
                self.connectionError = String(localized: "重连失败，请检查网络")
            }
            return
        }

        reconnectAttempts += 1
        // Exponential backoff: 1s, 2s, 4s, 8s, ... capped at 30s
        let delay = min(pow(2.0, Double(reconnectAttempts - 1)), 30)

        log.info("Reconnecting in \(delay)s (attempt \(self.reconnectAttempts))")

        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.openWebSocket()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension SocketClient: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol proto: String?
    ) {
        log.info("WebSocket transport open")
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        log.info("WebSocket closed, code=\(closeCode.rawValue)")
        handleDisconnect()
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
