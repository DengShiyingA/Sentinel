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
