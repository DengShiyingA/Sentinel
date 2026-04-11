import SwiftUI

struct HistoryView: View {
    @Environment(ApprovalStore.self) private var store
    @State private var searchText = ""
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if groupedHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle(String(localized: "历史"))
            .searchable(text: $searchText, prompt: String(localized: "搜索工具名或路径"))
            .toolbar {
                if !store.decisionHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "清空"), role: .destructive) {
                            showClearConfirm = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                String(localized: "清空历史记录"),
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "清空所有记录"), role: .destructive) {
                    store.clearHistory()
                }
                Button(String(localized: "取消"), role: .cancel) {}
            } message: {
                Text(String(localized: "此操作不可撤销"))
            }
        }
    }

    // MARK: - Grouped Data

    private struct SessionGroup: Identifiable {
        let id: String          // sessionId
        let records: [DecisionRecord]
        var date: Date { records.last?.decidedAt ?? Date() }
    }

    private var groupedHistory: [SessionGroup] {
        let filtered = filteredHistory
        guard !filtered.isEmpty else { return [] }

        // Group by sessionId, preserving order (newest session first)
        var groups: [SessionGroup] = []
        var current: (id: String, records: [DecisionRecord])? = nil

        for record in filtered {
            if current == nil || current!.id != record.sessionId {
                if let c = current {
                    groups.append(SessionGroup(id: c.id, records: c.records))
                }
                current = (record.sessionId, [record])
            } else {
                current!.records.append(record)
            }
        }
        if let c = current {
            groups.append(SessionGroup(id: c.id, records: c.records))
        }

        return groups
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

    // MARK: - Views

    private var historyList: some View {
        List {
            ForEach(groupedHistory) { group in
                Section {
                    ForEach(group.records) { record in
                        NavigationLink {
                            HistoryDetailView(record: record)
                        } label: {
                            recordRow(record)
                        }
                    }
                } header: {
                    sessionHeader(group)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sessionHeader(_ group: SessionGroup) -> some View {
        let isActive = group.id == store.currentSessionId
        let allowed = group.records.filter { $0.decision == .allowed }.count
        let blocked = group.records.filter { $0.decision == .blocked }.count

        return HStack(spacing: 6) {
            if isActive {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 7))
            }
            Text(group.date, format: .dateTime.month().day().hour().minute())
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
            Text("✓\(allowed)  ✗\(blocked)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func recordRow(_ record: DecisionRecord) -> some View {
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

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "暂无历史记录"), systemImage: "clock")
        } description: {
            Text(String(localized: "审批决策记录会显示在这里"))
        }
    }
}
