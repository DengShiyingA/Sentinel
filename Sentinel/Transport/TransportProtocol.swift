import Foundation

/// Unified transport interface for all connection modes.
/// Each implementation handles connect/disconnect and bidirectional messaging.
protocol TransportProtocol: AnyObject {
    var isConnected: Bool { get }
    var onRequest: ((ApprovalRequest) -> Void)? { get set }

    func connect() async throws
    func disconnect()
    func sendDecision(requestId: String, decision: Decision) async throws
}
