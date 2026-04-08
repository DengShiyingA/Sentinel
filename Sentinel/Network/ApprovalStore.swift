import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "ApprovalStore")

@Observable
final class ApprovalStore {
    var pendingRequests: [ApprovalRequest] = []
    var resolvedCount: Int = 0
    var activityFeed: [ActivityItem] = []
    var newActivityCount: Int = 0

    private let relay: RelayService
    private var timeoutTasks: [String: Task<Void, Never>] = [:]

    init(relay: RelayService) {
        self.relay = relay
        setupRelay()
    }

    /// Toast message shown briefly when another device handles a request
    var syncToast: String?

    private func setupRelay() {
        relay.onRequest = { [weak self] request in
            self?.handleIncomingRequest(request)
        }
        relay.onActivity = { [weak self] item in
            self?.handleActivity(item)
        }
        relay.onDecisionSync = { [weak self] requestId in
            self?.handleDecisionSync(requestId)
        }
    }

    // MARK: - Decision Sync (multi-device)

    private func handleDecisionSync(_ requestId: String) {
        Task { @MainActor in
            guard self.pendingRequests.contains(where: { $0.id == requestId }) else { return }
            self.removeRequest(id: requestId)
            self.resolvedCount += 1

            // Show toast
            self.syncToast = String(localized: "已由其他设备处理")
            log.info("Decision sync: \(requestId) removed (handled by other device)")

            // Auto-dismiss toast
            try? await Task.sleep(for: .seconds(2))
            if self.syncToast != nil { self.syncToast = nil }
        }
    }

    // MARK: - Activity Feed

    private func handleActivity(_ item: ActivityItem) {
        Task { @MainActor in
            self.activityFeed.insert(item, at: 0)
            if self.activityFeed.count > 50 { self.activityFeed.removeLast() }
            self.newActivityCount += 1
            log.info("Activity: \(item.type.rawValue) — \(item.summary)")

            // System notification for stop events
            if item.type == .stop {
                NotificationService.shared.postSimpleNotification(
                    title: item.isError ? "❌ Claude Code" : "✅ Claude Code",
                    body: item.summary
                )
            }
        }
    }

    func clearNewActivityCount() {
        newActivityCount = 0
    }

    // MARK: - Approval Requests

    private func handleIncomingRequest(_ request: ApprovalRequest) {
        Task { @MainActor in
            guard !self.pendingRequests.contains(where: { $0.id == request.id }) else { return }
            self.pendingRequests.insert(request, at: 0)
            log.info("New request: \(request.id) tool=\(request.toolName)")
        }
        scheduleTimeout(for: request)
    }

    func sendDecision(requestId: String, decision: Decision) {
        timeoutTasks[requestId]?.cancel()
        timeoutTasks.removeValue(forKey: requestId)
        relay.sendDecision(requestId: requestId, decision: decision)
        Task { @MainActor in
            self.removeRequest(id: requestId)
            self.resolvedCount += 1
        }
        log.info("Decision: \(requestId) → \(decision.rawValue)")
    }

    // MARK: - Send Message to Mac

    func sendUserMessage(_ text: String) {
        relay.sendUserMessage(text)
    }

    // MARK: - Timeout

    private func scheduleTimeout(for request: ApprovalRequest) {
        let requestId = request.id
        let remaining = request.remainingSeconds
        guard remaining > 0 else {
            sendDecision(requestId: requestId, decision: .blocked)
            return
        }
        let task = Task {
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            let stillPending = await MainActor.run {
                self.pendingRequests.contains { $0.id == requestId }
            }
            if stillPending {
                self.sendDecision(requestId: requestId, decision: .blocked)
            }
        }
        timeoutTasks[requestId] = task
    }

    @MainActor
    private func removeRequest(id: String) {
        pendingRequests.removeAll { $0.id == id }
    }

    func request(for id: String) -> ApprovalRequest? {
        pendingRequests.first { $0.id == id }
    }
}
