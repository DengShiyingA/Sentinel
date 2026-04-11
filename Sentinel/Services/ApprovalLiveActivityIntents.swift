import AppIntents
import Foundation

/// AppIntent fired when the user taps "Allow" on a Live Activity from the lock screen
/// or Dynamic Island. LiveActivityIntent runs in the widget extension process on
/// iOS 17+ when the main app is not foregrounded.
///
/// Because this runs in the widget process (or briefly in a background main-app task),
/// we cannot reach the WebSocket transport directly. Instead we enqueue the decision
/// onto the shared App Group queue and post a Darwin notification. The main app's
/// observer (installed in SentinelApp.onAppear) drains the queue and sends the
/// decision over the live transport.
///
/// This file must be included in BOTH the Sentinel target AND the widget
/// extension target.
public struct AllowApprovalIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "允许"
    public static var description = IntentDescription("允许这次 Claude 工具调用")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Request ID")
    public var requestId: String

    public init() {}
    public init(requestId: String) { self.requestId = requestId }

    public func perform() async throws -> some IntentResult {
        PendingDecisionQueue.enqueue(
            .init(requestId: requestId, decision: "allowed")
        )
        return .result()
    }
}

/// Allow-high-risk variant: opens the main app so the user can complete
/// Face ID verification before the decision is dispatched. LiveActivityIntent
/// runs without an extra biometric prompt on an unlocked device, so we cannot
/// perform BiometricService.authenticate() from the widget extension process.
/// Opening the app funnels the user back into ApprovalHelper.handleAllow
/// which runs the normal Face ID prompt.
public struct AllowHighRiskApprovalIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "允许（高风险）"
    public static var description = IntentDescription("允许高风险工具调用（需 Face ID）")
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Request ID")
    public var requestId: String

    public init() {}
    public init(requestId: String) { self.requestId = requestId }

    public func perform() async throws -> some IntentResult {
        // Write the intent into a separate "needs biometric" queue key so the
        // main app's drain path knows to run the in-app Face ID flow rather
        // than immediately dispatching .allowed.
        PendingDecisionQueue.enqueue(
            .init(requestId: requestId, decision: "allow_needs_biometric")
        )
        return .result()
    }
}

public struct DenyApprovalIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "拒绝"
    public static var description = IntentDescription("拒绝这次 Claude 工具调用")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Request ID")
    public var requestId: String

    public init() {}
    public init(requestId: String) { self.requestId = requestId }

    public func perform() async throws -> some IntentResult {
        PendingDecisionQueue.enqueue(
            .init(requestId: requestId, decision: "blocked")
        )
        return .result()
    }
}
