import Foundation

struct Statistics {
    let totalCount: Int
    let allowedCount: Int
    let blockedCount: Int
    let autoTrustedCount: Int
    let toolBreakdown: [ToolStat]
    let highRiskCount: Int
    let highRiskRatio: Double
    let averageResponseTime: TimeInterval

    struct ToolStat: Identifiable {
        let id: String
        var toolName: String { id }
        let count: Int
        let ratio: Double
    }

    static func build(
        history: [DecisionRecord],
        resolvedCount: Int,
        since: Date = Calendar.current.startOfDay(for: Date())
    ) -> Statistics {
        let today = history.filter { $0.decidedAt >= since }
        let allowed = today.filter { $0.decision == .allowed }.count
        let blocked = today.filter { $0.decision == .blocked }.count
        let autoTrusted = max(0, resolvedCount - history.count)

        let toolCounts = Dictionary(grouping: today, by: \.request.toolName)
            .map { ToolStat(id: $0.key, count: $0.value.count, ratio: today.isEmpty ? 0 : Double($0.value.count) / Double(today.count)) }
            .sorted { $0.count > $1.count }

        let highRisk = today.filter { $0.request.riskLevel == .requireFaceID }.count
        let highRiskRatio = today.isEmpty ? 0 : Double(highRisk) / Double(today.count)

        let avgResponse: TimeInterval = {
            let times = today.compactMap { record -> TimeInterval? in
                let elapsed = record.decidedAt.timeIntervalSince(record.request.timestamp)
                return elapsed > 0 && elapsed < 300 ? elapsed : nil
            }
            guard !times.isEmpty else { return 0 }
            return times.reduce(0, +) / Double(times.count)
        }()

        return Statistics(
            totalCount: today.count + autoTrusted,
            allowedCount: allowed,
            blockedCount: blocked,
            autoTrustedCount: autoTrusted,
            toolBreakdown: toolCounts,
            highRiskCount: highRisk,
            highRiskRatio: highRiskRatio,
            averageResponseTime: avgResponse
        )
    }
}
