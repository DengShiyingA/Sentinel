import Foundation

/// Unified transport interface for all connection modes.
/// Each implementation handles connect/disconnect and bidirectional messaging.
protocol TransportProtocol: AnyObject {
    var isConnected: Bool { get }
    var onRequest: ((ApprovalRequest) -> Void)? { get set }
    var onActivity: ((ActivityItem) -> Void)? { get set }
    var onDecisionSync: ((String) -> Void)? { get set }  // requestId resolved by another device

    func connect() async throws
    func disconnect()
    func sendDecision(requestId: String, decision: Decision) async throws
}
