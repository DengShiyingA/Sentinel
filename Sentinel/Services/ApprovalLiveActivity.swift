import ActivityKit
import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LiveActivity")

/// Thin wrapper around ActivityKit for approval Live Activities.
/// Handles start / end lifecycle and authorization checks.
///
/// The lock-screen countdown is rendered by the widget itself using
/// `Text(timerInterval:)`, so we don't need to push periodic updates —
/// just start at creation and end when the user decides or the request
/// times out.
@MainActor
final class ApprovalLiveActivity {
    static let shared = ApprovalLiveActivity()

    /// Map of approval requestId → activity identifier so we can look up
    /// the running activity when a decision comes in.
    private var activeActivities: [String: String] = [:]

    private init() {}

    /// Whether the user has Live Activities enabled for this app.
    var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Start a Live Activity for the given approval request.
    /// Silently no-ops if Live Activities are disabled or if an activity
    /// for this request is already running (defensive guard against double-start).
    func start(for request: ApprovalRequest, summary: String) {
        guard isAvailable else {
            log.info("Live Activities disabled by user — skipping start")
            return
        }

        guard activeActivities[request.id] == nil else {
            log.info("Activity already exists for \(request.id) — skipping")
            return
        }

        let attributes = ApprovalActivityAttributes(
            requestId: request.id,
            toolName: request.toolName,
            summary: summary,
            riskLevelRaw: request.riskLevel.rawValue,
            startedAt: Date(),
            timeoutAt: request.timeoutAt
        )

        let initialState = ApprovalActivityAttributes.ContentState(
            secondsRemaining: max(0, Int(request.timeoutAt.timeIntervalSinceNow)),
            phase: .pending
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: initialState,
                    staleDate: request.timeoutAt
                ),
                pushType: nil
            )
            activeActivities[request.id] = activity.id
            log.info("Started Live Activity \(activity.id) for request \(request.id)")
        } catch {
            log.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// End the Live Activity associated with the given request.
    /// Updates the final ContentState so the lock-screen UI shows the outcome
    /// briefly before iOS removes it.
    func end(requestId: String, phase: ApprovalActivityAttributes.ContentState.Phase) {
        Task { @MainActor in
            guard let activityId = activeActivities[requestId] else {
                log.debug("No active activity for \(requestId)")
                return
            }

            guard let activity = Activity<ApprovalActivityAttributes>.activities
                .first(where: { $0.id == activityId }) else {
                activeActivities.removeValue(forKey: requestId)
                return
            }

            let finalState = ApprovalActivityAttributes.ContentState(
                secondsRemaining: 0,
                phase: phase
            )

            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(4))
            )

            activeActivities.removeValue(forKey: requestId)
            log.info("Ended Live Activity for \(requestId) with phase \(phase.rawValue)")
        }
    }

    /// End all running activities. Called on disconnect / app background to keep state clean.
    func endAll() {
        Task { @MainActor in
            for activity in Activity<ApprovalActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            activeActivities.removeAll()
        }
    }
}
