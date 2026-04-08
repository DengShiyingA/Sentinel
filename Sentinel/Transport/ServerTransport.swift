import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "ServerTransport")

/// Wraps SocketClient as a TransportProtocol.
final class ServerTransport: TransportProtocol {
    private let socket: SocketClient
    private let serverURL: String
    private let deviceId: String

    var onRequest: ((ApprovalRequest) -> Void)?
    var onActivity: ((ActivityItem) -> Void)?

    init(socket: SocketClient, serverURL: String, deviceId: String) {
        self.socket = socket
        self.serverURL = serverURL
        self.deviceId = deviceId
        setupListener()
    }

    var isConnected: Bool { socket.isConnected }

    func connect() async throws {
        socket.connect(serverURL: serverURL, deviceId: deviceId)
        // Wait up to 5s for connection
        for _ in 0..<50 {
            if socket.isConnected { return }
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    func disconnect() {
        socket.disconnect()
    }

    func sendDecision(requestId: String, decision: Decision) async throws {
        socket.emit("decision", dict: [
            "requestId": requestId,
            "action": decision.rawValue,
        ])
    }

    private func setupListener() {
        socket.onEvent = { [weak self] event, data in
            guard event == "approval_request" else { return }
            guard let request = try? JSONDecoder.sentinelDecoder.decode(ApprovalRequest.self, from: data) else {
                log.error("Failed to decode approval_request")
                return
            }
            self?.onRequest?(request)
        }
    }
}
