import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LocalTransport")

final class LocalTransport: TransportProtocol {
    private let discovery: LocalDiscoveryService

    var onRequest: ((ApprovalRequest) -> Void)? { didSet { rebindListener() } }
    var onActivity: ((ActivityItem) -> Void)? { didSet { rebindListener() } }
    var onDecisionSync: ((String) -> Void)? { didSet { rebindListener() } }
    var onTerminal: ((String) -> Void)? { didSet { rebindListener() } }

    init(discovery: LocalDiscoveryService) {
        self.discovery = discovery
        rebindListener()
    }

    var isConnected: Bool { discovery.isConnected }

    func connect() async throws {
        await MainActor.run { discovery.startDiscovery() }
    }

    func disconnect() {
        discovery.disconnect()
        discovery.stopDiscovery()
    }

    func sendDecision(requestId: String, decision: Decision) async throws {
        discovery.emit("decision", dict: [
            "requestId": requestId,
            "action": decision.rawValue,
        ])
    }

    /// Re-set discovery.onEvent every time a callback changes,
    /// so closures always reference the latest callbacks.
    private func rebindListener() {
        let onReq = onRequest
        let onAct = onActivity
        let onSync = onDecisionSync
        let onTerm = onTerminal

        discovery.onEvent = { event, data in
            switch event {
            case "handshake":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let ek = dict["ek"] as? String {
                    TransportEncryption.setKey(base64: ek)
                    log.info("Encryption key received")
                }

            case "approval_request":
                do {
                    let request = try JSONDecoder.sentinelDecoder.decode(ApprovalRequest.self, from: data)
                    log.info("Request: \(request.id) tool=\(request.toolName)")
                    onReq?(request)
                } catch {
                    log.error("Decode error: \(error)")
                    if let raw = String(data: data, encoding: .utf8) {
                        log.error("Raw: \(raw.prefix(200))")
                    }
                }

            case "notification":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let title = dict["title"] as? String ?? "Sentinel"
                    let message = dict["message"] as? String ?? ""
                    NotificationService.shared.postSimpleNotification(title: title, body: message)
                }

            case "terminal":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = dict["text"] as? String {
                    onTerm?(text)
                }

            case "activity":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let typeStr = dict["type"] as? String ?? ""
                    let type = ActivityType(rawValue: typeStr) ?? .toolCompleted
                    let item = ActivityItem(
                        id: UUID().uuidString,
                        type: type,
                        summary: dict["summary"] as? String ?? dict["message"] as? String ?? typeStr,
                        toolName: dict["toolName"] as? String,
                        timestamp: Date(),
                        stopReason: dict["stopReason"] as? String,
                        message: dict["message"] as? String
                    )
                    onAct?(item)
                }

            default:
                break
            }
        }
    }
}
