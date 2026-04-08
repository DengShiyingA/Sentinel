import SwiftUI

struct ActivityFeedView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
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

    // MARK: - Status Bar

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

    // MARK: - Feed List

    private var feedList: some View {
        List(store.activityFeed) { item in
            ActivityRow(item: item)
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "暂无活动"), systemImage: "clock")
        } description: {
            Text(String(localized: "Claude Code 的操作记录会显示在这里"))
        }
    }

    // MARK: - Message Input

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

        // Add to local feed
        let item = ActivityItem(
            id: UUID().uuidString,
            type: .userMessage,
            summary: text,
            toolName: nil,
            timestamp: Date(),
            stopReason: nil,
            message: text
        )
        store.activityFeed.insert(item, at: 0)

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
            case "Bash": return item.isError ? "terminal" : "terminal"
            case "Read": return "doc.text"
            default: return "checkmark.circle"
            }
        case .notification: return "bell"
        case .stop: return item.isError ? "xmark.circle" : "checkmark.circle"
        case .taskCompleted: return "checkmark.seal"
        case .sessionEnded: return "clock"
        case .userMessage: return "text.bubble"
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
        case .userMessage: return .tint
        }
    }
}
