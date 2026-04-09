import SwiftUI

struct StatisticsView: View {
    @Environment(ApprovalStore.self) private var store

    var body: some View {
        let stats = Statistics.build(history: store.decisionHistory, resolvedCount: store.resolvedCount)

        List {
            if stats.totalCount == 0 {
                emptyState
            } else {
                overviewSection(stats)
                toolBreakdownSection(stats)
                riskSection(stats)
                performanceSection(stats)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "统计"))
    }

    private var emptyState: some View {
        Section {
            ContentUnavailableView {
                Label(String(localized: "暂无数据"), systemImage: "chart.bar")
            } description: {
                Text(String(localized: "审批记录会在处理请求后自动统计"))
            }
        }
    }

    private func overviewSection(_ stats: Statistics) -> some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: String(localized: "今日总计"),
                    value: "\(stats.totalCount)",
                    icon: "shield.checkered",
                    color: .blue
                )
                StatCard(
                    title: String(localized: "已允许"),
                    value: "\(stats.allowedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                StatCard(
                    title: String(localized: "已拒绝"),
                    value: "\(stats.blockedCount)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                StatCard(
                    title: String(localized: "自动信任"),
                    value: "\(stats.autoTrustedCount)",
                    icon: "clock.badge.checkmark",
                    color: .purple
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }

    private func toolBreakdownSection(_ stats: Statistics) -> some View {
        Section(String(localized: "工具分布")) {
            if stats.toolBreakdown.isEmpty {
                Text(String(localized: "暂无工具调用记录"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stats.toolBreakdown) { tool in
                    HStack(spacing: 12) {
                        ToolIcon(toolName: tool.toolName, size: 24)

                        Text(tool.toolName)
                            .font(.subheadline)

                        Spacer()

                        Text("\(tool.count)")
                            .font(.subheadline.monospacedDigit().weight(.medium))

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(toolColor(tool.toolName))
                                .frame(width: geo.size.width * tool.ratio, height: 6)
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(width: 60, height: 20)
                    }
                }
            }
        }
    }

    private func riskSection(_ stats: Statistics) -> some View {
        Section(String(localized: "风险概览")) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "高风险操作"))
                        .font(.subheadline)
                    Text(String(localized: "\(stats.highRiskCount) 次"))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(stats.highRiskCount > 0 ? .red : .green)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: stats.highRiskRatio)
                        .stroke(
                            stats.highRiskRatio > 0.3 ? .red : .orange,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(stats.highRiskRatio * 100))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50, height: 50)
            }
            .padding(.vertical, 4)
        }
    }

    private func performanceSection(_ stats: Statistics) -> some View {
        Section(String(localized: "响应")) {
            HStack {
                Label(String(localized: "平均响应时间"), systemImage: "gauge.medium")
                    .font(.subheadline)
                Spacer()
                Text(formatTime(stats.averageResponseTime))
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(stats.averageResponseTime < 10 ? .green : stats.averageResponseTime < 30 ? .orange : .red)
            }
        }
    }

    private func toolColor(_ name: String) -> Color {
        let n = name.lowercased()
        if n.contains("write") || n.contains("edit") { return .blue }
        if n.contains("bash") { return .orange }
        if n.contains("read") { return .green }
        if n.contains("grep") || n.contains("glob") { return .teal }
        return .secondary
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 1 { return "< 1s" }
        if seconds < 60 { return String(format: "%.1fs", seconds) }
        return String(format: "%dm %ds", Int(seconds) / 60, Int(seconds) % 60)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
