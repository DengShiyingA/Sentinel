import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LocalTransport")

/// Wraps LocalDiscoveryService as a TransportProtocol.
final class LocalTransport: TransportProtocol {
    private let discovery: LocalDiscoveryService

    var onRequest: ((ApprovalRequest) -> Void)?

    init(discovery: LocalDiscoveryService) {
        self.discovery = discovery
        setupListener()
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

    private func setupListener() {
        discovery.onEvent = { [weak self] event, data in
            log.info("LocalTransport received event: \(event), bytes: \(data.count)")

            switch event {
            case "approval_request":
                do {
                    let request = try JSONDecoder.sentinelDecoder.decode(ApprovalRequest.self, from: data)
                    log.info("Decoded request: \(request.id) tool=\(request.toolName)")
                    self?.onRequest?(request)
                } catch {
                    log.error("Decode error: \(error)")
                    if let raw = String(data: data, encoding: .utf8) {
                        log.error("Raw JSON: \(raw.prefix(200))")
                    }
                }

            case "notification":
                // Mac sent a custom notification (sentinel notify "message")
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let title = dict["title"] as? String ?? "Sentinel"
                    let message = dict["message"] as? String ?? ""
                    NotificationService.shared.postSimpleNotification(title: title, body: message)
                    log.info("Notification: \(title) — \(message)")
                }

            default:
                break
            }
        }
    }
}
