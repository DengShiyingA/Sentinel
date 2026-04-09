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
    var onDecisionSync: ((String) -> Void)?
    var onTerminal: ((String) -> Void)?
    var onWorkspaceInfo: ((_ cwd: String, _ hostname: String?) -> Void)?

    init(socket: SocketClient, serverURL: String, deviceId: String) {
        self.socket = socket
        self.serverURL = serverURL
        self.deviceId = deviceId
        setupListener()
    }

    var isConnected: Bool { socket.isConnected }

    func connect() async throws {
        socket.connect(serverURL: serverURL, deviceId: deviceId)
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

    func sendRulesUpdate(rules: [[String: Any]]) async throws {
        socket.emit("rules_update", dict: ["rules": rules])
    }

    private func setupListener() {
        socket.onEvent = { [weak self] event, data in
            // Dispatch all callbacks to MainActor for thread safety
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch event {
                case "approval_request":
                    guard let request = try? JSONDecoder.sentinelDecoder.decode(ApprovalRequest.self, from: data) else {
                        log.error("Failed to decode approval_request")
                        ErrorBus.shared.post( String(localized: "审批请求解析失败"),
                                             recovery: String(localized: "请检查 CLI 版本是否匹配"))
                        return
                    }
                    self.onRequest?(request)

                case "decision_sync":
                    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let requestId = dict["requestId"] as? String {
                        let decidedBy = dict["decidedBy"] as? String ?? "other device"
                        log.info("Decision sync: \(requestId) decided by \(decidedBy)")
                        self.onDecisionSync?(requestId)
                    }

                case "activity":
                    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let typeStr = dict["type"] as? String ?? ""
                        let type = ActivityType(rawValue: typeStr) ?? .toolCompleted
                        let item = ActivityItem(
                            id: UUID().uuidString,
                            type: type,
                            summary: dict["summary"] as? String ?? typeStr,
                            toolName: dict["toolName"] as? String,
                            timestamp: Date(),
                            stopReason: dict["stopReason"] as? String,
                            message: dict["message"] as? String
                        )
                        self.onActivity?(item)
                    }

                default:
                    break
                }
            }
        }
    }
}
