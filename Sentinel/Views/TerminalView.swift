import SwiftUI

struct TerminalView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.terminalLines.isEmpty && store.activityFeed.isEmpty {
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
                    if !store.terminalLines.isEmpty {
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

    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(store.terminalLines) { line in
                        terminalLine(line)
                            .id(line.id)
                    }

                    ForEach(store.activityFeed.reversed()) { item in
                        activityBubble(item)
                            .id("a-\(item.id)")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: store.terminalLines.count) { _, _ in
                if let last = store.terminalLines.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func terminalLine(_ line: TerminalLine) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(line.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .leading)

            Text(line.text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(lineColor(line.text))
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func activityBubble(_ item: ActivityItem) -> some View {
        if item.type == .userMessage {
            HStack {
                Spacer()
                Text(item.summary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 4)
        } else if item.type == .claudeResponse {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.purple)
                    Text(item.summary)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField(
                relay.isConnected
                    ? String(localized: "发送消息给 Claude Code...")
                    : String(localized: "未连接"),
                text: $messageText
            )
            .textFieldStyle(.roundedBorder)
            .disabled(!relay.isConnected)
            .submitLabel(.send)
            .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .disabled(messageText.isEmpty || !relay.isConnected)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
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
