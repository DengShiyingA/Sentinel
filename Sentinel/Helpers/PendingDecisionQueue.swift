import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "PendingDecisionQueue")

/// Shared queue (App Group UserDefaults) for decisions triggered by LiveActivity AppIntents.
///
/// When a user taps Allow/Deny on a Live Activity from the lock screen, the
/// corresponding `LiveActivityIntent` runs in the widget extension process (or
/// briefly in the main app if it's running). Neither process can directly send
/// a WebSocket message — only the long-lived main app transport can.
///
/// So the intent writes the pending decision here, posts a Darwin notification,
/// and the main app's observer picks it up and dispatches the decision over
/// the real transport.
///
/// This file must be included in BOTH the Sentinel target AND the widget
/// extension target.
public enum PendingDecisionQueue {
    public static let appGroupId = "group.com.sentinel.ios"
    public static let userDefaultsKey = "sentinel.pendingDecisions"
    public static let darwinNotificationName = "com.sentinel.decision-queued"

    public struct Entry: Codable, Hashable {
        public let requestId: String
        public let decision: String // "allowed" | "blocked"
        public let queuedAt: Date

        public init(requestId: String, decision: String, queuedAt: Date = Date()) {
            self.requestId = requestId
            self.decision = decision
            self.queuedAt = queuedAt
        }
    }

    /// Append a pending decision to the shared queue.
    /// Called from AppIntent code running in either process.
    public static func enqueue(_ entry: Entry) {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            log.error("App group \(appGroupId) unavailable")
            return
        }
        var queue = readQueue(defaults: defaults)
        queue.append(entry)
        if let data = try? JSONEncoder().encode(queue) {
            defaults.set(data, forKey: userDefaultsKey)
        }
        postDarwinNotification()
    }

    /// Drain the queue, returning all pending entries and clearing storage.
    public static func drain() -> [Entry] {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return [] }
        let entries = readQueue(defaults: defaults)
        defaults.removeObject(forKey: userDefaultsKey)
        return entries
    }

    private static func readQueue(defaults: UserDefaults) -> [Entry] {
        guard let data = defaults.data(forKey: userDefaultsKey),
              let queue = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return queue
    }

    // MARK: - Darwin Notification

    /// Post a cross-process Darwin notification so the main app's observer wakes up.
    public static func postDarwinNotification() {
        let name = CFNotificationName(darwinNotificationName as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            name,
            nil,
            nil,
            true
        )
    }
}
