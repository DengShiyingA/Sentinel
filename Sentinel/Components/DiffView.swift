import SwiftUI

struct DiffView: View {
    let diff: String

    private let parsedLines: [DiffLine]
    private let addedCount: Int
    private let removedCount: Int
    private let isTruncated: Bool
    private static let collapsedLineLimit = 30

    init(diff: String) {
        self.diff = diff
        var lineNumber = 0
        let lines = diff.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            let s = String(line)
            let type: DiffLineType
            if s.hasPrefix("+++") || s.hasPrefix("---") {
                type = .header
            } else if s.hasPrefix("@@") {
                type = .hunk
                if let match = s.firstMatch(of: /\+(\d+)/) {
                    lineNumber = (Int(match.1) ?? 1) - 1
                }
            } else if s.hasPrefix("+") {
                lineNumber += 1
                type = .added
            } else if s.hasPrefix("-") {
                type = .removed
            } else {
                lineNumber += 1
                type = .context
            }
            return DiffLine(
                text: s,
                type: type,
                lineNumber: (type == .added || type == .context) ? lineNumber : nil
            )
        }
        self.parsedLines = lines
        self.addedCount = lines.count { $0.type == .added }
        self.removedCount = lines.count { $0.type == .removed }
        self.isTruncated = diff.contains("Diff truncated:")
    }

    @State private var isExpanded = false
    @State private var showAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            if isExpanded {
                diffContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private var headerBar: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)

                Text("Diff")
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 4) {
                    Text("+\(addedCount)")
                        .foregroundStyle(.green)
                    Text("-\(removedCount)")
                        .foregroundStyle(.red)
                }
                .font(.caption.monospacedDigit().weight(.medium))

                Spacer()

                if isTruncated {
                    Text(String(localized: "已截断"))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if isExpanded {
                    Button {
                        UIPasteboard.general.string = diff
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }

    private var visibleLines: ArraySlice<DiffLine> {
        if showAll || parsedLines.count <= Self.collapsedLineLimit {
            return parsedLines[...]
        }
        return parsedLines.prefix(Self.collapsedLineLimit)
    }

    private var hiddenCount: Int {
        showAll ? 0 : max(0, parsedLines.count - Self.collapsedLineLimit)
    }

    private var diffContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(visibleLines.enumerated()), id: \.offset) { _, line in
                        diffLineRow(line)
                    }
                }
            }

            if hiddenCount > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showAll = true }
                } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "... 还有 \(hiddenCount) 行"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemGroupedBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func diffLineRow(_ line: DiffLine) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(line.lineNumber.map { String(format: "%4d", $0) } ?? "    ")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 36, alignment: .trailing)
                .padding(.trailing, 4)

            Text(line.prefix)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line.type.prefixColor)
                .frame(width: 14, alignment: .center)

            Text(line.content)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line.type.foregroundColor)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 1)
        .padding(.trailing, 8)
        .background(line.type.backgroundColor)
    }
}

private struct DiffLine {
    let text: String
    let type: DiffLineType
    let lineNumber: Int?

    var prefix: String {
        switch type {
        case .added: "+"
        case .removed: "-"
        case .hunk: "@@"
        case .header, .context: " "
        }
    }

    var content: String {
        switch type {
        case .added, .removed:
            String(text.dropFirst(1))
        case .header, .hunk:
            text
        case .context:
            text.hasPrefix(" ") ? String(text.dropFirst(1)) : text
        }
    }
}

private enum DiffLineType {
    case header, hunk, added, removed, context

    var prefixColor: Color {
        switch self {
        case .added: .green
        case .removed: .red
        default: .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .header: .secondary
        case .hunk: .purple
        case .added: Color(.label)
        case .removed: Color(.label)
        case .context: .secondary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .added: Color.green.opacity(0.12)
        case .removed: Color.red.opacity(0.12)
        case .hunk: Color.purple.opacity(0.06)
        default: .clear
        }
    }
}
