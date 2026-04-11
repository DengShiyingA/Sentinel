import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LiveActivityObserver")

/// Installs a Darwin notification observer that wakes the main app when a
/// Live Activity AppIntent enqueues a decision from the widget extension
/// process. On each notification the app drains the shared queue and
/// dispatches decisions via the existing transport.
///
/// Must be called from the main app (widget extension side only writes to
/// the queue via `PendingDecisionQueue.enqueue`).
@MainActor
enum LiveActivityDecisionObserver {
    private static var installed = false

    static func install(store: ApprovalStore) {
        guard !installed else { return }
        installed = true

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = PendingDecisionQueue.darwinNotificationName as CFString
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(StoreHolder.shared).toOpaque())
        StoreHolder.shared.store = store

        CFNotificationCenterAddObserver(
            center,
            observer,
            { (_, _, _, _, _) in
                Task { @MainActor in
                    StoreHolder.shared.store?.drainPendingLiveActivityDecisions()
                }
            },
            name,
            nil,
            .deliverImmediately
        )

        log.info("Darwin notification observer installed for \(PendingDecisionQueue.darwinNotificationName)")
    }

    /// Holds a weak-like reference to the store from the C callback.
    /// Darwin notification callbacks are C function pointers so they cannot
    /// capture Swift context directly; we use a shared singleton holder.
    @MainActor
    private final class StoreHolder {
        static let shared = StoreHolder()
        weak var store: ApprovalStore?
        private init() {}
    }
}
