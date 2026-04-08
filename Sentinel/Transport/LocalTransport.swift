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
            guard event == "approval_request" else { return }
            guard let request = try? JSONDecoder.sentinelDecoder.decode(ApprovalRequest.self, from: data) else {
                log.error("Failed to decode approval_request")
                return
            }
            self?.onRequest?(request)
        }
    }
}
