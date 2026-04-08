import SwiftUI

struct TerminalView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if feedItems.isEmpty {
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
                    HStack(spacing: 4) {
                        Circle()
                            .fill(relay.isConnected ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(relay.isConnected
                             ? String(localized: "运行中")
                             : String(localized: "等待中"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !feedItems.isEmpty {
                        Button {
                            store.terminalLines.removeAll()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private var feedItems: [FeedItem] {
        var items: [FeedItem] = []

        for line in store.terminalLines {
            items.append(FeedItem(
                id: line.id, time: line.timestamp, kind: .terminal(line.text)))
        }

        for item in store.activityFeed {
            switch item.type {
            case .userMessage:
                items.append(FeedItem(
                    id: "u-\(item.id)", time: item.timestamp, kind: .user(item.summary)))
            case .claudeResponse:
                items.append(FeedItem(
                    id: "c-\(item.id)", time: item.timestamp, kind: .claude(item.summary)))
            case .notification:
                items.append(FeedItem(
                    id: "n-\(item.id)", time: item.timestamp, kind: .terminal("📢 \(item.summary)")))
            case .stop:
                let prefix = item.isError ? "❌" : "✅"
                items.append(FeedItem(
                    id: "s-\(item.id)", time: item.timestamp, kind: .terminal("\(prefix) \(item.summary)")))
            default:
                break
            }
        }

        items.sort { $0.time < $1.time }
        return items
    }

    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(feedItems) { item in
                        feedRow(item).id(item.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: feedItems.count) { _, _ in
                if let last = feedItems.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func feedRow(_ item: FeedItem) -> some View {
        switch item.kind {
        case .terminal(let text):
            HStack(alignment: .top, spacing: 6) {
                Text(item.time, format: .dateTime.hour().minute().second())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 55, alignment: .leading)
                Text(text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(lineColor(text))
                    .textSelection(.enabled)
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
        }
    }

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

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "等待输出"), systemImage: "terminal")
        } description: {
            Text(String(localized: "Claude Code 的实时输出和对话会显示在这里"))
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendUserMessage(text)
        messageText = ""
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

private struct FeedItem: Identifiable {
    let id: String
    let time: Date
    let kind: Kind

    enum Kind {
        case terminal(String)
        case user(String)
        case claude(String)
    }
}
