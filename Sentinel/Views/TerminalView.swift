import SwiftUI

struct TerminalView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @State private var messageText = ""
    @State private var isScrolledToBottom = true
    @State private var pendingApprovalCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.timeline.isEmpty {
                    emptyState
                } else {
                    feedList
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
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.timeline) { entry in
                            entryRow(entry).id(entry.id)
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
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("bottom-anchor", anchor: .bottom)
                        }
                    }
                }

                if !isScrolledToBottom && pendingApprovalCount > 0 {
                    newApprovalBanner {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("bottom-anchor", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Entry Row

    @ViewBuilder
    private func entryRow(_ entry: TimelineEntry) -> some View {
        switch entry.kind {
        case .terminal(let text):
            if isCompactLine(text) {
                // Compact single-line for approval results and tool completions
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
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
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
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
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

    // MARK: - New Approval Banner

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

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack {
                TextField(
                    relay.isConnected
                        ? String(localized: "发送消息给 Claude Code...")
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

    // MARK: - Empty State

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

    // MARK: - Helpers

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendUserMessage(text)
        messageText = ""
    }

    /// Lines that are approval results or tool completions — render compact.
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
