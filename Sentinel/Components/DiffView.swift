import SwiftUI

/// Displays a unified diff with syntax coloring.
/// Added lines are green, removed lines are red, context lines are default.
struct DiffView: View {
    let diff: String

    private let parsedLines: [DiffLine]
    private let addedCount: Int
    private let removedCount: Int
    private let isTruncated: Bool

    init(diff: String) {
        self.diff = diff
        let lines = diff.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            let s = String(line)
            if s.hasPrefix("+++") || s.hasPrefix("---") {
                return DiffLine(text: s, type: .header)
            } else if s.hasPrefix("@@") {
                return DiffLine(text: s, type: .hunk)
            } else if s.hasPrefix("+") {
                return DiffLine(text: s, type: .added)
            } else if s.hasPrefix("-") {
                return DiffLine(text: s, type: .removed)
            } else {
                return DiffLine(text: s, type: .context)
            }
        }
        self.parsedLines = lines
        self.addedCount = lines.count { $0.type == .added }
        self.removedCount = lines.count { $0.type == .removed }
        self.isTruncated = diff.contains("Diff truncated:")
    }

    var body: some View {
        GroupBox {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(parsedLines.enumerated()), id: \.offset) { _, line in
                        diffLine(line)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            HStack {
                Label(String(localized: "Diff (\(addedCount)+/\(removedCount)-)"), systemImage: "doc.badge.gearshape")
                Spacer()
                if isTruncated {
                    Text(String(localized: "已截断"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private func diffLine(_ line: DiffLine) -> some View {
        Text(line.text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(line.type.foregroundColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .background(line.type.backgroundColor)
    }
}

private struct DiffLine {
    let text: String
    let type: DiffLineType
}

private enum DiffLineType {
    case header, hunk, added, removed, context

    var foregroundColor: Color {
        switch self {
        case .header: .secondary
        case .hunk: .purple
        case .added: .green
        case .removed: .red
        case .context: .primary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .added: .green.opacity(0.08)
        case .removed: .red.opacity(0.08)
        default: .clear
        }
    }
}
