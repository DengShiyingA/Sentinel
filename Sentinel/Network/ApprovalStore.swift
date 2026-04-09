import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "ApprovalStore")

@Observable
final class ApprovalStore {
    var pendingRequests: [ApprovalRequest] = []
    var resolvedCount: Int = 0
    var activityFeed: [ActivityItem] = []
    var terminalLines: [TerminalLine] = []

    private let relay: RelayService
    private var timeoutTasks: [String: Task<Void, Never>] = [:]
    /// Set by SentinelApp after init to enable trust-based auto-approval
    var trustManager: TrustManager?

    init(relay: RelayService) {
        self.relay = relay
        setupRelay()
    }

    /// Toast message shown briefly when another device handles a request
    var syncToast: String?

    /// History of resolved approval requests with their decisions.
    var decisionHistory: [DecisionRecord] = []

    /// Pending rule suggestions shown in timeline.
    var pendingSuggestions: [RuleSuggestion] = []
    /// Dismissed suggestion pattern keys — never suggest again.
    private var dismissedPatterns: Set<String> = []
    /// Session summaries shown in timeline.
    var sessionSummaries: [SessionSummary] = []
    /// Timestamp of last .stop event for session boundary tracking.
    private var lastStopTimestamp: Date?

    /// Cached unified timeline — rebuilt only when underlying data changes.
    private(set) var timeline: [TimelineEntry] = []
    /// Monotonic counter used as tie-breaker for stable sorting.
    private var insertionCounter: Int = 0

    /// Rebuild the cached timeline. Called after any mutation to terminalLines, activityFeed, or pendingRequests.
    @MainActor
    private func rebuildTimeline() {
        var entries: [TimelineEntry] = []

        for (i, line) in terminalLines.enumerated() {
            entries.append(TimelineEntry(
                id: line.id, time: line.timestamp, order: i, kind: .terminal(line.text)))
        }

        let baseOrder = terminalLines.count
        for (i, item) in activityFeed.reversed().enumerated() {
            switch item.type {
            case .userMessage:
                entries.append(TimelineEntry(
                    id: "u-\(item.id)", time: item.timestamp, order: baseOrder + i,
                    kind: .user(item.summary)))
            case .claudeResponse:
                entries.append(TimelineEntry(
                    id: "c-\(item.id)", time: item.timestamp, order: baseOrder + i,
                    kind: .claude(item.summary)))
            case .notification:
                entries.append(TimelineEntry(
                    id: "n-\(item.id)", time: item.timestamp, order: baseOrder + i,
                    kind: .terminal("📢 \(item.summary)")))
            case .stop:
                let prefix = item.isError ? "❌" : "✅"
                entries.append(TimelineEntry(
                    id: "s-\(item.id)", time: item.timestamp, order: baseOrder + i,
                    kind: .terminal("\(prefix) \(item.summary)")))
            default:
                break
            }
        }

        let approvalBase = baseOrder + activityFeed.count
        let groups = groupedApprovals()
        for (i, group) in groups.enumerated() {
            if group.requests.count == 1 {
                let req = group.requests[0]
                entries.append(TimelineEntry(
                    id: "a-\(req.id)", time: req.timestamp, order: approvalBase + i,
                    kind: .approval(req)))
            } else {
                let earliest = group.requests.map(\.timestamp).min() ?? Date()
                entries.append(TimelineEntry(
                    id: "ag-\(group.id)", time: earliest, order: approvalBase + i,
                    kind: .approvalGroup(group)))
            }
        }

        // Suggestions
        let sugBase = approvalBase + groups.count
        for (i, suggestion) in pendingSuggestions.enumerated() {
            entries.append(TimelineEntry(
                id: "sug-\(suggestion.id)", time: suggestion.timestamp, order: sugBase + i,
                kind: .suggestion(suggestion)))
        }

        // Session summaries
        let sumBase = sugBase + pendingSuggestions.count
        for (i, summary) in sessionSummaries.enumerated() {
            entries.append(TimelineEntry(
                id: "sum-\(summary.id)", time: summary.timestamp, order: sumBase + i,
                kind: .summary(summary)))
        }

        // Stable sort: by time first, then insertion order for tie-breaking
        entries.sort { a, b in
            if a.time != b.time { return a.time < b.time }
            return a.order < b.order
        }

        timeline = entries

        SharedStateWriter.update(
            isConnected: relay.isConnected,
            pendingRequests: pendingRequests,
            resolvedCount: resolvedCount
        )
    }

    /// Group pending requests by tool name when they arrive within 3 seconds.
    private func groupedApprovals() -> [ApprovalGroup] {
        guard !pendingRequests.isEmpty else { return [] }
        let sorted = pendingRequests.sorted { $0.timestamp < $1.timestamp }
        var groups: [ApprovalGroup] = []
        var current = ApprovalGroup(
            id: "grp-\(sorted[0].id)", toolName: sorted[0].toolName, requests: [sorted[0]])

        for i in 1..<sorted.count {
            let req = sorted[i]
            let lastInGroup = current.requests.last!
            let gap = req.timestamp.timeIntervalSince(lastInGroup.timestamp)

            if req.toolName == current.toolName && gap <= 3.0 {
                current.requests.append(req)
            } else {
                groups.append(current)
                current = ApprovalGroup(
                    id: "grp-\(req.id)", toolName: req.toolName, requests: [req])
            }
        }
        groups.append(current)
        return groups
    }

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
        relay.onTerminal = { [weak self] text in
            self?.handleTerminalLine(text)
        }
    }

    // MARK: - Terminal

    private func handleTerminalLine(_ text: String) {
        Task { @MainActor in
            self.terminalLines.append(TerminalLine.from(text: text))
            if self.terminalLines.count > SentinelConfig.maxTerminalLines {
                self.terminalLines.removeFirst(self.terminalLines.count - SentinelConfig.maxTerminalLines)
            }
            self.rebuildTimeline()
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
            if self.activityFeed.count > SentinelConfig.maxActivityItems { self.activityFeed.removeLast() }
            log.info("Activity: \(item.type.rawValue) — \(item.summary)")

            // Session summary for stop events
            if item.type == .stop {
                let summary = SessionSummaryBuilder.build(
                    history: self.decisionHistory,
                    since: self.lastStopTimestamp,
                    stopItem: item
                )
                self.sessionSummaries.append(summary)
                self.lastStopTimestamp = item.timestamp

                NotificationService.shared.postSimpleNotification(
                    title: item.isError ? "❌ Claude Code 任务失败" : "✅ Claude Code 任务完成",
                    body: summary.displaySubtitle
                )
            }

            self.rebuildTimeline()
        }
    }

    // MARK: - Approval Requests

    private func handleIncomingRequest(_ request: ApprovalRequest) {
        Task { @MainActor in
            // Check temporary trust — auto-approve without user interaction
            if let trustManager, trustManager.isTrusted(toolName: request.toolName) {
                log.info("Auto-allowed (trusted): \(request.id) tool=\(request.toolName)")
                relay.sendDecision(requestId: request.id, decision: .allowed)
                self.resolvedCount += 1
                return
            }

            guard !self.pendingRequests.contains(where: { $0.id == request.id }) else { return }
            self.pendingRequests.insert(request, at: 0)
            self.rebuildTimeline()
            log.info("New request: \(request.id) tool=\(request.toolName)")

            NotificationService.shared.postApprovalNotification(
                requestId: request.id,
                toolName: request.toolName,
                riskLevel: request.riskLevel
            )

            self.scheduleTimeout(for: request)
        }
    }

    func sendDecision(requestId: String, decision: Decision) {
        timeoutTasks[requestId]?.cancel()
        timeoutTasks.removeValue(forKey: requestId)
        relay.sendDecision(requestId: requestId, decision: decision)
        Task { @MainActor in
            guard let req = self.pendingRequests.first(where: { $0.id == requestId }) else { return }
            self.decisionHistory.insert(
                DecisionRecord(id: requestId, request: req, decision: decision, decidedAt: Date()),
                at: 0
            )
            if self.decisionHistory.count > SentinelConfig.maxHistoryItems {
                self.decisionHistory.removeLast(self.decisionHistory.count - SentinelConfig.maxHistoryItems)
            }
            self.removeRequest(id: requestId)
            self.resolvedCount += 1

            // Check for rule suggestion after allowing
            if decision == .allowed {
                if let suggestion = SuggestionEngine.analyze(
                    history: self.decisionHistory,
                    dismissedPatterns: self.dismissedPatterns
                ) {
                    self.pendingSuggestions.append(suggestion)
                    self.rebuildTimeline()
                }
            }
        }
        log.info("Decision: \(requestId) → \(decision.rawValue)")
    }

    func sendGroupDecision(group: ApprovalGroup, decision: Decision) {
        for request in group.requests {
            sendDecision(requestId: request.id, decision: decision)
        }
    }

    @MainActor
    func dismissSuggestion(_ suggestion: RuleSuggestion) {
        let key = SuggestionEngine.patternKey(toolName: suggestion.toolName, pathPattern: suggestion.pathPattern)
        dismissedPatterns.insert(key)
        pendingSuggestions.removeAll { $0.id == suggestion.id }
        rebuildTimeline()
    }

    @MainActor
    func createRuleFromSuggestion(_ suggestion: RuleSuggestion) {
        let rule = CustomRule(
            id: UUID().uuidString,
            toolPattern: suggestion.toolName,
            pathPattern: suggestion.pathPattern,
            risk: "auto_allow",
            description: String(localized: "自动规则: \(suggestion.toolName)")
        )
        var rules = RulesView.loadCustomRules()
        rules.append(rule)
        RulesView.saveCustomRules(rules)

        let key = SuggestionEngine.patternKey(toolName: suggestion.toolName, pathPattern: suggestion.pathPattern)
        dismissedPatterns.insert(key)
        pendingSuggestions.removeAll { $0.id == suggestion.id }
        rebuildTimeline()
        log.info("Created rule from suggestion: \(suggestion.toolName) \(suggestion.pathPattern ?? "*")")
    }

    @MainActor
    func clearTerminal() {
        terminalLines.removeAll()
        rebuildTimeline()
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
            // Already expired — mark as expired immediately instead of blocking
            Task { @MainActor in self.expireRequest(id: requestId) }
            return
        }
        let task = Task {
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            let stillPending = await MainActor.run {
                self.pendingRequests.contains { $0.id == requestId }
            }
            if stillPending {
                // Mark as expired and notify — don't auto-block
                await MainActor.run { self.expireRequest(id: requestId) }
            }
        }
        timeoutTasks[requestId] = task
    }

    /// Move a request to expired state. The user can still manually block it,
    /// but we don't auto-block to avoid unintended denials when user is away.
    @MainActor
    private func expireRequest(id: String) {
        removeRequest(id: id)
        resolvedCount += 1
        // Notify transport that request expired (treated as timeout on CLI side)
        relay.sendDecision(requestId: id, decision: .blocked)
        log.info("Request expired: \(id)")
    }

    @MainActor
    private func removeRequest(id: String) {
        pendingRequests.removeAll { $0.id == id }
        rebuildTimeline()
    }

    func request(for id: String) -> ApprovalRequest? {
        pendingRequests.first { $0.id == id }
    }
}
