import SwiftUI

struct TerminalView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @Environment(TrustManager.self) private var trustManager
    @State private var messageText = ""
    @State private var isScrolledToBottom = true
    @State private var pendingApprovalCount = 0
    @State private var showSlashMenu = false
    @State private var commandResult: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.timeline.isEmpty && commandResult == nil {
                    emptyState
                } else {
                    feedList
                }

                if showSlashMenu {
                    slashCommandList
                }

                Divider()
                inputBar
            }
            .navigationTitle(String(localized: "终端"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Circle()
                        .fill(relay.isConnected ? .green : .gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .accessibilityLabel(relay.isConnected
                            ? String(localized: "已连接")
                            : String(localized: "未连接"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.timeline.isEmpty {
                        Button {
                            store.clearTerminal()
                            commandResult = nil
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                    }
                }
            }
            .onChange(of: store.pendingRequests.count) { _, newCount in
                pendingApprovalCount = newCount
            }
            .onChange(of: messageText) { _, newValue in
                withAnimation(Theme.springAnimation) {
                    showSlashMenu = newValue.hasPrefix("/")
                }
            }
        }
    }

    private var feedList: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.timeline) { entry in
                            entryRow(entry).id(entry.id)
                        }

                        if let result = commandResult {
                            commandResultView(result)
                                .id("cmd-result")
                        }

                        Color.clear.frame(height: 1).id("bottom-anchor")
                            .onAppear { isScrolledToBottom = true }
                            .onDisappear { isScrolledToBottom = false }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: store.timeline.count) { _, _ in
                    if isScrolledToBottom {
                        withAnimation(Theme.springAnimation) {
                            proxy.scrollTo("bottom-anchor", anchor: .bottom)
                        }
                    }
                }

                if !isScrolledToBottom && pendingApprovalCount > 0 {
                    newApprovalBanner {
                        withAnimation(Theme.springAnimation) {
                            proxy.scrollTo("bottom-anchor", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: TimelineEntry) -> some View {
        switch entry.kind {
        case .terminal(let text):
            if isCompactLine(text) {
                Text(text)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(lineColor(text).opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                HStack(alignment: .top, spacing: 6) {
                    Text(entry.time, format: .dateTime.hour().minute().second())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 55, alignment: .leading)
                    Text(text)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(lineColor(text))
                        .textSelection(.enabled)
                }
            }

        case .user(let text):
            HStack {
                Spacer()
                Text(text)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: Theme.bubbleRadius))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 2)

        case .claude(let text):
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.purple)
                    Text(text)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: Theme.bubbleRadius))
                Spacer()
            }
            .padding(.vertical, 2)

        case .approval(let request):
            InlineApprovalCard(request: request) { decision in
                store.sendDecision(requestId: request.id, decision: decision)
            }
            .padding(.vertical, 4)

        case .approvalGroup(let group):
            InlineApprovalGroupCard(
                group: group,
                onDecision: { requestId, decision in
                    store.sendDecision(requestId: requestId, decision: decision)
                },
                onGroupDecision: { decision in
                    store.sendGroupDecision(group: group, decision: decision)
                }
            )
            .padding(.vertical, 4)

        case .suggestion(let suggestion):
            InlineSuggestionCard(
                suggestion: suggestion,
                onCreateRule: { store.createRuleFromSuggestion(suggestion) },
                onDismiss: { store.dismissSuggestion(suggestion) }
            )
            .padding(.vertical, 4)

        case .summary(let summary):
            InlineSummaryCard(summary: summary)
                .padding(.vertical, 4)
        }
    }

    private func commandResultView(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "terminal")
                .font(.caption)
                .foregroundStyle(.teal)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.teal.opacity(0.06), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var slashCommandList: some View {
        let commands = SlashCommand.matching(messageText)

        return ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(commands) { cmd in
                    Button {
                        executeCommand(cmd)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: cmd.icon)
                                .font(.subheadline)
                                .foregroundStyle(.teal)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(cmd.label)
                                    .font(.subheadline.weight(.medium).monospaced())
                                    .foregroundStyle(.primary)
                                Text(cmd.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 240)
        .background(Color(.secondarySystemGroupedBackground))
        .transition(Theme.springTransition)
    }

    private func newApprovalBanner(scrollToBottom: @escaping () -> Void) -> some View {
        Button {
            scrollToBottom()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                Text(String(localized: "\(pendingApprovalCount) 个新审批"))
                    .font(.caption.weight(.medium))
                Image(systemName: "arrow.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack {
                TextField(
                    relay.isConnected
                        ? String(localized: "消息或 / 命令...")
                        : String(localized: "未连接"),
                    text: $messageText
                )
                .disabled(!relay.isConnected)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

                if !messageText.isEmpty {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "等待输出"), systemImage: "terminal")
        } description: {
            if let error = relay.connectionError {
                Text(error)
            } else {
                Text(String(localized: "Claude Code 的实时输出和对话会显示在这里"))
            }
        } actions: {
            if !relay.isConnected {
                Button {
                    relay.connectCurrentMode()
                } label: {
                    Label(String(localized: "重新连接"), systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if text.hasPrefix("/") {
            if let cmd = SlashCommand.all.first(where: { $0.label == text }) {
                executeCommand(cmd)
                return
            }
        }

        store.sendUserMessage(text)
        messageText = ""
    }

    private func executeCommand(_ cmd: SlashCommand) {
        Haptic.light()
        messageText = ""
        showSlashMenu = false

        switch cmd.id {
        case "block":
            commandResult = String(localized: "🚫 已封锁所有请求")
            for req in store.pendingRequests {
                store.sendDecision(requestId: req.id, decision: .blocked)
            }

        case "allow":
            commandResult = String(localized: "✅ 已放行所有请求")
            for req in store.pendingRequests {
                store.sendDecision(requestId: req.id, decision: .allowed)
            }

        case "status":
            let mode = ConnectionMode.current.label
            let connected = relay.isConnected ? String(localized: "已连接") : String(localized: "未连接")
            let pending = store.pendingRequests.count
            let resolved = store.resolvedCount
            commandResult = """
            \(mode) · \(connected)
            \(String(localized: "待处理")): \(pending) | \(String(localized: "已处理")): \(resolved)
            """

        case "rules":
            let rules = RulesView.loadCustomRules()
            if rules.isEmpty {
                commandResult = String(localized: "无自定义规则（使用内置规则）")
            } else {
                let list = rules.map { "· \($0.toolPattern ?? "*") \($0.pathPattern ?? "*") → \($0.risk)" }.joined(separator: "\n")
                commandResult = "\(String(localized: "自定义规则")) (\(rules.count)):\n\(list)"
            }

        case "trust":
            if trustManager.activeTrusts.isEmpty {
                commandResult = String(localized: "无活跃信任")
            } else {
                let list = trustManager.activeTrusts.map { "· \($0.displayLabel) — \($0.remainingText)" }.joined(separator: "\n")
                commandResult = "\(String(localized: "临时信任")) (\(trustManager.activeTrusts.count)):\n\(list)"
            }

        case "clear":
            store.clearTerminal()
            commandResult = nil

        case "stats":
            let stats = Statistics.build(history: store.decisionHistory, resolvedCount: store.resolvedCount)
            commandResult = """
            \(String(localized: "今日")): \(stats.totalCount) | ✅ \(stats.allowedCount) | ❌ \(stats.blockedCount) | 🔒 \(stats.autoTrustedCount)
            \(String(localized: "高风险")): \(stats.highRiskCount) (\(Int(stats.highRiskRatio * 100))%)
            \(String(localized: "响应")): \(stats.averageResponseTime < 1 ? "< 1s" : String(format: "%.1fs", stats.averageResponseTime))
            """

        case "reconnect":
            relay.connectCurrentMode()
            commandResult = String(localized: "🔄 正在重新连接...")

        default:
            commandResult = String(localized: "未知命令: /\(cmd.id)")
        }
    }

    private func isCompactLine(_ text: String) -> Bool {
        text.contains("— allowed") || text.contains("— blocked") || text.hasPrefix("[")
    }

    private func lineColor(_ text: String) -> Color {
        if text.hasPrefix("✅") { return .green }
        if text.hasPrefix("❌") { return .red }
        if text.hasPrefix("📢") { return .orange }
        if text.hasPrefix(">") { return .blue }
        if text.hasPrefix("[") { return .teal }
        return .primary
    }
}
