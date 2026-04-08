import SwiftUI

/// Unified dashboard: segmented picker switches between Pending / Terminal / History
struct DashboardView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay

    @State private var tab: DashboardTab = .pending

    enum DashboardTab: String, CaseIterable {
        case pending = "待审批"
        case terminal = "终端"
        case history = "历史"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("", selection: $tab) {
                    ForEach(DashboardTab.allCases, id: \.self) { t in
                        Text(String(localized: String.LocalizationValue(t.rawValue))).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content
                switch tab {
                case .pending:
                    pendingContent
                case .terminal:
                    terminalContent
                case .history:
                    historyContent
                }
            }
            .navigationTitle(String(localized: "Sentinel"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    connectionIndicator
                }
            }
            .overlay(alignment: .top) {
                if let toast = store.syncToast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 52)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(duration: 0.3), value: store.syncToast)
                }
            }
        }
    }

    // MARK: - Pending Approvals

    private var pendingContent: some View {
        Group {
            if store.pendingRequests.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "没有待审批的请求"), systemImage: "checkmark.shield")
                } description: {
                    Text(String(localized: "当 Claude Code 需要执行工具时，审批请求会出现在这里"))
                }
            } else {
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
        }
    }

    // MARK: - Terminal

    private var terminalContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(store.terminalLines) { line in
                            TerminalLineView(line: line).id(line.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .background(.black)
                .onChange(of: store.terminalLines.count) { _, _ in
                    if let last = store.terminalLines.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if store.terminalLines.isEmpty {
                Spacer()
                Text(String(localized: "等待 Claude Code 输出..."))
                    .font(.caption.monospaced())
                    .foregroundStyle(.green.opacity(0.4))
                Spacer()
            }
        }
        .background(.black)
    }

    // MARK: - History (Activity Feed)

    private var historyContent: some View {
        Group {
            if store.activityFeed.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "暂无活动"), systemImage: "clock")
                } description: {
                    Text(String(localized: "Claude Code 的操作记录会显示在这里"))
                }
            } else {
                List(store.activityFeed) { item in
                    NavigationLink(value: "activity-\(item.id)") {
                        ActivityRow(item: item)
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: String.self) { id in
                    if id.hasPrefix("activity-") {
                        let actId = String(id.dropFirst(9))
                        if let item = store.activityFeed.first(where: { $0.id == actId }) {
                            ActivityDetailView(item: item)
                        }
                    }
                }
            }
        }
        .onAppear { store.clearNewActivityCount() }
    }

    // MARK: - Connection

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

// MARK: - Approval Row (unchanged)

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
