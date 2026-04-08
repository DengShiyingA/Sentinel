import SwiftUI

struct ApprovalListView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay

    var body: some View {
        NavigationStack {
            Group {
                if store.pendingRequests.isEmpty {
                    emptyState
                } else {
                    requestList
                }
            }
            .navigationTitle(String(localized: "审批"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    connectionIndicator
                }
            }
        }
    }

    // MARK: - Request List

    private var requestList: some View {
        List {
            ForEach(store.pendingRequests) { request in
                NavigationLink(value: request.id) {
                    ApprovalRow(request: request)
                }
                .swipeActions(edge: .trailing) {
                    Button(String(localized: "允许")) {
                        store.sendDecision(requestId: request.id, decision: .allowed)
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .leading) {
                    Button(String(localized: "拒绝")) {
                        store.sendDecision(requestId: request.id, decision: .blocked)
                    }
                    .tint(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: String.self) { requestId in
            if let request = store.request(for: requestId) {
                ApprovalDetailView(request: request)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "没有待审批的请求"), systemImage: "checkmark.shield")
        } description: {
            Text(String(localized: "当 Claude Code 需要执行工具时，审批请求会出现在这里"))
        }
    }

    // MARK: - Connection Indicator

    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(relay.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            Text(relay.isConnected ? String(localized: "已连接") : String(localized: "未连接"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Approval Row

struct ApprovalRow: View {
    let request: ApprovalRequest

    var body: some View {
        HStack(spacing: 12) {
            ToolIcon(toolName: request.toolName)

            VStack(alignment: .leading, spacing: 4) {
                Text(request.toolName)
                    .font(.headline)

                if let path = request.toolInput["file_path"]?.description
                    ?? request.toolInput["command"]?.description {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                RiskBadge(riskLevel: request.riskLevel)
                CountdownText(timeoutAt: request.timeoutAt)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Countdown Text (compact, for list rows)

struct CountdownText: View {
    let timeoutAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int(max(0, timeoutAt.timeIntervalSince(context.date)))
            Text("\(remaining)s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(remaining < 30 ? .red : .secondary)
        }
    }
}
