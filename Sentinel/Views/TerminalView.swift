import SwiftUI

/// Real-time terminal output from Claude Code.
/// Shows tool results, decisions, and notifications as streaming text.
struct TerminalView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                HStack {
                    Circle()
                        .fill(relay.isConnected ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(relay.isConnected
                         ? "sentinel · connected"
                         : "sentinel · disconnected")
                        .font(.caption.monospaced())
                        .foregroundStyle(.green.opacity(0.8))
                    Spacer()
                    Text("\(store.terminalLines.count) lines")
                        .font(.caption.monospaced())
                        .foregroundStyle(.green.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black)

                // Terminal output
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(store.terminalLines) { line in
                                TerminalLineView(line: line)
                                    .id(line.id)
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
            }
            .background(.black)
            .navigationTitle(String(localized: "终端"))
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.terminalLines.removeAll()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.green.opacity(0.6))
                    }
                }
            }
        }
    }
}

// MARK: - Terminal Line Model

struct TerminalLine: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
    let type: LineType

    enum LineType {
        case normal
        case success    // ✅
        case error      // ❌
        case info       // 📢 ℹ️
        case tool       // [Write] [Bash] etc
    }

    var color: Color {
        switch type {
        case .normal:  .green
        case .success: .green
        case .error:   .red
        case .info:    .yellow
        case .tool:    .cyan
        }
    }

    static func from(text: String) -> TerminalLine {
        let type: LineType
        if text.hasPrefix("✅") { type = .success }
        else if text.hasPrefix("❌") { type = .error }
        else if text.hasPrefix("📢") || text.hasPrefix("ℹ") { type = .info }
        else if text.hasPrefix("[") { type = .tool }
        else { type = .normal }

        return TerminalLine(
            id: UUID().uuidString,
            text: text,
            timestamp: Date(),
            type: type
        )
    }
}

// MARK: - Terminal Line View

struct TerminalLineView: View {
    let line: TerminalLine

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(line.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.green.opacity(0.3))
                .frame(width: 55, alignment: .leading)

            Text(line.text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(line.color)
                .textSelection(.enabled)
        }
    }
}
