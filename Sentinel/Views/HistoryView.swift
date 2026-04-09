import SwiftUI

struct HistoryView: View {
    @Environment(ApprovalStore.self) private var store
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if filteredHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle(String(localized: "历史"))
            .searchable(text: $searchText, prompt: String(localized: "搜索工具名或路径"))
        }
    }

    private var filteredHistory: [DecisionRecord] {
        if searchText.isEmpty { return store.decisionHistory }
        let query = searchText.lowercased()
        return store.decisionHistory.filter { record in
            record.request.toolName.lowercased().contains(query)
            || (record.request.toolInput["file_path"]?.description ?? "").lowercased().contains(query)
            || (record.request.toolInput["command"]?.description ?? "").lowercased().contains(query)
        }
    }

    private var historyList: some View {
        List(filteredHistory) { record in
            HStack(spacing: 12) {
                Image(systemName: record.decision == .allowed
                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(record.decision == .allowed ? .green : .red)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.request.toolName)
                        .font(.headline)
                    if let path = record.request.toolInput["file_path"]?.description
                        ?? record.request.toolInput["command"]?.description {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    RiskBadge(riskLevel: record.request.riskLevel)
                    Text(record.decidedAt, format: .dateTime.hour().minute().second())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "暂无历史记录"), systemImage: "clock")
        } description: {
            Text(String(localized: "审批决策记录会显示在这里"))
        }
    }
}
