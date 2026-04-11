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
    var onModel: ((String) -> Void)? { get set }
    var onBrowseResult: ((BrowseResult) -> Void)? { get set }

    func connect() async throws
    func disconnect()
    /// Send a decision for a pending approval. `modifiedInput`, when non-nil,
    /// is serialized as `modifiedInput` on the wire so the CLI hook handler
    /// returns it as `updatedInput` to Claude Code.
    func sendDecision(requestId: String, decision: Decision, modifiedInput: [String: Any]?) async throws
    func sendRulesUpdate(rules: [[String: Any]]) async throws
}
