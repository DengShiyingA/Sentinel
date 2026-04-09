import Foundation

/// Unified transport interface for all connection modes.
/// Each implementation handles connect/disconnect and bidirectional messaging.
protocol TransportProtocol: AnyObject {
    var isConnected: Bool { get }
    var onRequest: ((ApprovalRequest) -> Void)? { get set }
    var onActivity: ((ActivityItem) -> Void)? { get set }
    var onDecisionSync: ((String) -> Void)? { get set }
    var onTerminal: ((String) -> Void)? { get set }
    var onWorkspaceInfo: ((_ cwd: String, _ hostname: String?) -> Void)? { get set }

    func connect() async throws
    func disconnect()
    func sendDecision(requestId: String, decision: Decision) async throws
    func sendRulesUpdate(rules: [[String: Any]]) async throws
}
