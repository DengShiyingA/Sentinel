import SwiftUI

struct TerminalLine: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
    let type: LineType

    enum LineType {
        case normal, success, error, info, tool
    }

    var color: Color {
        switch type {
        case .normal:  .primary
        case .success: .green
        case .error:   .red
        case .info:    .orange
        case .tool:    .blue
        }
    }

    static func from(text: String) -> TerminalLine {
        let type: LineType
        if text.hasPrefix("✅") { type = .success }
        else if text.hasPrefix("❌") { type = .error }
        else if text.hasPrefix("📢") || text.hasPrefix("ℹ") { type = .info }
        else if text.hasPrefix("[") { type = .tool }
        else { type = .normal }

        return TerminalLine(id: UUID().uuidString, text: text, timestamp: Date(), type: type)
    }
}

struct TerminalLineView: View {
    let line: TerminalLine

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(line.timestamp, format: .dateTime.hour().minute().second())
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .leading)

            Text(line.text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(line.color)
                .textSelection(.enabled)
        }
    }
}
