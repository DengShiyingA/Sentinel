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
    /// for this request is already running (defensive guard against double-start,
    /// including the case where the app was relaunched while an activity was live).
    func start(for request: ApprovalRequest, summary: String) {
        guard isAvailable else {
            log.info("Live Activities disabled by user — skipping start")
            return
        }

        // Double-start guard: check both the in-memory dict AND the OS-level
        // activity list (the dict is wiped on app relaunch but the activity
        // itself may survive).
        if activeActivities[request.id] != nil ||
            Activity<ApprovalActivityAttributes>.activities
                .contains(where: { $0.attributes.requestId == request.id }) {
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
    /// briefly before iOS removes it. Looks up the activity by its attributes
    /// `requestId` so it also works after an app relaunch (when the in-memory
    /// `activeActivities` dict has been wiped but the OS still has the activity).
    func end(requestId: String, phase: ApprovalActivityAttributes.ContentState.Phase) {
        Task { @MainActor in
            // Match by attributes.requestId, not the local dict — survives app relaunch.
            let activity = Activity<ApprovalActivityAttributes>.activities
                .first(where: { $0.attributes.requestId == requestId })

            guard let activity else {
                activeActivities.removeValue(forKey: requestId)
                log.debug("No active activity for \(requestId)")
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
