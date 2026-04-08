import SwiftUI

struct ActivityFeedView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar

                if store.activityFeed.isEmpty {
                    emptyState
                } else {
                    feedList
                }

                Divider()
                messageInput
            }
            .navigationTitle(String(localized: "活动"))
            .onAppear { store.clearNewActivityCount() }
        }
    }

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(relay.isConnected ? .green : .gray)
                .frame(width: 8, height: 8)
            Text(relay.isConnected
                 ? String(localized: "Claude Code 运行中")
                 : String(localized: "等待中"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if !store.activityFeed.isEmpty {
                Text(String(localized: "已执行 \(store.activityFeed.count) 个操作"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var feedList: some View {
        List(store.activityFeed) { item in
            NavigationLink(value: item.id) {
                ActivityRow(item: item)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: String.self) { id in
            if let item = store.activityFeed.first(where: { $0.id == id }) {
                ActivityDetailView(item: item)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "暂无活动"), systemImage: "clock")
        } description: {
            Text(String(localized: "Claude Code 的操作记录会显示在这里"))
        }
    }

    private var messageInput: some View {
        HStack(spacing: 8) {
            TextField(String(localized: "发送消息给 Claude Code..."), text: $messageText)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendUserMessage(text)
        store.activityFeed.insert(ActivityItem(
            id: UUID().uuidString, type: .userMessage, summary: text,
            toolName: nil, timestamp: Date(), stopReason: nil, message: text
        ), at: 0)
        messageText = ""
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.summary)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    if let tool = item.toolName {
                        Text(tool)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    Text(item.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch item.type {
        case .toolCompleted:
            switch item.toolName {
            case "Write", "Edit": return "doc.badge.plus"
            case "Bash": return "terminal"
            case "Read": return "doc.text"
            default: return "checkmark.circle"
            }
        case .notification: return "bell"
        case .stop: return item.isError ? "xmark.circle" : "checkmark.circle"
        case .taskCompleted: return "checkmark.seal"
        case .sessionEnded: return "clock"
        case .userMessage: return "text.bubble"
        case .claudeResponse: return "bubble.left.fill"
        case .claudeStatus: return "ellipsis.bubble"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .toolCompleted:
            if item.toolName == "Write" || item.toolName == "Edit" { return .blue }
            return item.isError ? .red : .green
        case .notification: return .orange
        case .stop: return item.isError ? .red : .green
        case .taskCompleted: return .green
        case .sessionEnded: return .gray
        case .userMessage: return .blue
        case .claudeResponse: return .purple
        case .claudeStatus: return .gray
        }
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let item: ActivityItem

    var body: some View {
        List {
            // Header
            Section {
                HStack(spacing: 14) {
                    Image(systemName: item.type.systemImage)
                        .font(.title2)
                        .foregroundStyle(headerColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.type.label)
                            .font(.headline)
                        Text(item.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Details
            Section {
                if let tool = item.toolName {
                    LabeledContent(String(localized: "工具")) {
                        Text(tool).font(.body.monospaced())
                    }
                }

                LabeledContent(String(localized: "类型")) {
                    Text(item.type.label)
                }

                LabeledContent(String(localized: "时间")) {
                    Text(item.timestamp.formatted(date: .abbreviated, time: .standard))
                }

                if let reason = item.stopReason {
                    LabeledContent(String(localized: "停止原因")) {
                        Text(reason)
                            .foregroundStyle(reason == "error" ? .red : .green)
                    }
                }
            } header: {
                Text(String(localized: "详情"))
            }

            // Message content
            if let message = item.message, !message.isEmpty {
                Section {
                    Text(message)
                        .font(.body)
                        .textSelection(.enabled)
                } header: {
                    Text(String(localized: "内容"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(item.toolName ?? item.type.label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerColor: Color {
        switch item.type {
        case .toolCompleted: .blue
        case .notification: .orange
        case .stop: item.isError ? .red : .green
        case .taskCompleted: .green
        case .sessionEnded: .gray
        case .userMessage: .blue
        case .claudeResponse: .purple
        case .claudeStatus: .gray
        }
    }
}
