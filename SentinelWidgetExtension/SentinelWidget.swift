import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SentinelEntry: TimelineEntry {
    let date: Date
    let state: WidgetState?
}

// MARK: - Timeline Provider

struct SentinelProvider: TimelineProvider {
    func placeholder(in context: Context) -> SentinelEntry {
        SentinelEntry(date: .now, state: WidgetState(
            isConnected: true, pendingCount: 0, resolvedCount: 42,
            latestToolName: nil, latestPath: nil, latestRiskLevel: nil, updatedAt: .now
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (SentinelEntry) -> Void) {
        completion(SentinelEntry(date: .now, state: WidgetState.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SentinelEntry>) -> Void) {
        let entry = SentinelEntry(date: .now, state: WidgetState.read())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - Widget View

struct SentinelWidgetEntryView: View {
    let entry: SentinelEntry

    var body: some View {
        if let state = entry.state {
            connectedView(state)
        } else {
            noDataView
        }
    }

    private func connectedView(_ state: WidgetState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(state.isConnected
                         ? String(localized: "已连接")
                         : String(localized: "未连接"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if state.pendingCount > 0 {
                    HStack(spacing: 4) {
                        Text("\(state.pendingCount)")
                            .font(.title2.weight(.bold).monospacedDigit())
                        Text(String(localized: "待审批"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if let toolName = state.latestToolName {
                HStack(spacing: 6) {
                    Image(systemName: toolIcon(toolName))
                        .font(.caption)
                        .foregroundStyle(toolColor(toolName))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(toolName)
                            .font(.caption.weight(.medium))
                        if let path = state.latestPath {
                            Text(path)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(String(localized: "一切正常"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(localized: "已处理 \(state.resolvedCount)"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
    }

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Sentinel")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(localized: "打开 App 开始监控"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    private func toolIcon(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("write") || n.contains("edit") { return "doc.badge.plus" }
        if n.contains("bash") { return "terminal" }
        if n.contains("read") { return "doc.text" }
        return "gearshape"
    }

    private func toolColor(_ name: String) -> Color {
        let n = name.lowercased()
        if n.contains("write") || n.contains("edit") { return .blue }
        if n.contains("bash") { return .orange }
        if n.contains("read") { return .green }
        return .secondary
    }
}

// MARK: - Widget Definition

struct SentinelWidget: Widget {
    let kind = "SentinelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentinelProvider()) { entry in
            SentinelWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sentinel")
        .description(String(localized: "监控 Claude Code 审批状态"))
        .supportedFamilies([.systemMedium])
    }
}
