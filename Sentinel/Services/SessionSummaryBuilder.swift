import Foundation

enum SessionSummaryBuilder {
    static func build(
        history: [DecisionRecord],
        since: Date?,
        stopItem: ActivityItem
    ) -> SessionSummary {
        let startTime = since ?? Date.distantPast

        let sessionDecisions = history.filter { $0.decidedAt > startTime }

        let filesModified = sessionDecisions
            .filter { $0.decision == .allowed }
            .compactMap { record -> String? in
                let tool = record.request.toolName.lowercased()
                guard tool.contains("write") || tool.contains("edit") else { return nil }
                return ApprovalHelper.extractPath(from: record.request)
            }
        let uniqueFiles = Array(Set(filesModified))

        let commandsRun = sessionDecisions
            .filter { $0.decision == .allowed }
            .filter { $0.request.toolName.lowercased().contains("bash") }
            .count

        let allowed = sessionDecisions.filter { $0.decision == .allowed }.count
        let blocked = sessionDecisions.filter { $0.decision == .blocked }.count

        let duration = stopItem.timestamp.timeIntervalSince(
            startTime == .distantPast ? stopItem.timestamp : startTime
        )

        return SessionSummary(
            id: UUID().uuidString,
            filesModified: uniqueFiles.sorted(),
            commandsRun: commandsRun,
            approvalsAllowed: allowed,
            approvalsBlocked: blocked,
            isError: stopItem.isError,
            duration: max(0, duration),
            timestamp: stopItem.timestamp
        )
    }
}
