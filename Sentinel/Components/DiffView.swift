import SwiftUI

struct DiffView: View {
    let diff: String
    var initiallyExpanded: Bool = false

    private let parsedLines: [DiffLine]
    private let addedCount: Int
    private let removedCount: Int
    private let isTruncated: Bool
    private let fileName: String?
    private static let collapsedLineLimit = 30

    init(diff: String, initiallyExpanded: Bool = false) {
        self.diff = diff
        self.initiallyExpanded = initiallyExpanded
        var lineNumber = 0
        var detectedFileName: String?
        let lines = diff.split(separator: "\n", omittingEmptySubsequences: false).map { line in
            let s = String(line)
            let type: DiffLineType
            if s.hasPrefix("+++") {
                type = .header
                let path = s.dropFirst(4).trimmingCharacters(in: .whitespaces)
                if path != "/dev/null" { detectedFileName = (path as NSString).lastPathComponent }
            } else if s.hasPrefix("---") {
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
        self.fileName = detectedFileName
    }

    @State private var isExpanded = false
    @State private var showAll = false
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            if isExpanded {
                diffContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .onAppear {
            if initiallyExpanded { isExpanded = true }
        }
    }

    private var headerBar: some View {
        Button {
            withAnimation(Theme.springAnimation) {
                isExpanded.toggle()
                if !isExpanded { showAll = false }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))

                if let fileName {
                    Text(fileName)
                        .font(.caption.weight(.medium).monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                statsBadge

                Spacer()

                if isTruncated {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if isExpanded {
                    copyButton
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statsBadge: some View {
        HStack(spacing: 2) {
            Text("+\(addedCount)")
                .foregroundStyle(.green)
            Text("-\(removedCount)")
                .foregroundStyle(.red)
        }
        .font(.system(size: 11, design: .monospaced).weight(.semibold))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.tertiarySystemFill), in: Capsule())
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = diff
            Haptic.light()
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.caption)
                .foregroundStyle(copied ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    private var visibleLines: ArraySlice<DiffLine> {
        let contentLines = parsedLines.filter { $0.type != .header }
        if showAll || contentLines.count <= Self.collapsedLineLimit {
            return contentLines[...]
        }
        return contentLines.prefix(Self.collapsedLineLimit)
    }

    private var hiddenCount: Int {
        let contentLines = parsedLines.filter { $0.type != .header }
        return showAll ? 0 : max(0, contentLines.count - Self.collapsedLineLimit)
    }

    private var diffContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(visibleLines.enumerated()), id: \.offset) { _, line in
                        diffLineRow(line)
                    }
                }
            }

            if hiddenCount > 0 {
                expandButton
            }
        }
        .background(Color(.systemGroupedBackground))
        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
    }

    private var expandButton: some View {
        Button {
            withAnimation(Theme.springAnimation) { showAll = true }
        } label: {
            HStack(spacing: 6) {
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.caption2)
                Text(String(localized: "展开剩余 \(hiddenCount) 行"))
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }

    private func diffLineRow(_ line: DiffLine) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(line.lineNumber.map { String(format: "%4d", $0) } ?? "    ")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(line.type.lineNumberColor)
                .frame(width: 36, alignment: .trailing)

            Rectangle()
                .fill(Color(.separator).opacity(0.2))
                .frame(width: 1)
                .padding(.horizontal, 3)

            Text(line.prefix)
                .font(.system(size: 12, design: .monospaced).weight(.semibold))
                .foregroundStyle(line.type.prefixColor)
                .frame(width: 12, alignment: .center)

            Text(line.content)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line.type.foregroundColor)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 1.5)
        .padding(.trailing, 8)
        .background(line.type.backgroundColor)
    }
}

struct DiffSummaryBadge: View {
    let diff: String

    private let addedCount: Int
    private let removedCount: Int

    init(diff: String) {
        self.diff = diff
        let lines = diff.split(separator: "\n", omittingEmptySubsequences: false)
        self.addedCount = lines.count { $0.hasPrefix("+") && !$0.hasPrefix("+++") }
        self.removedCount = lines.count { $0.hasPrefix("-") && !$0.hasPrefix("---") }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.badge.gearshape")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("+\(addedCount)")
                .foregroundStyle(.green)
            Text("-\(removedCount)")
                .foregroundStyle(.red)
        }
        .font(.system(size: 10, design: .monospaced).weight(.medium))
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
        case .hunk: "@"
        case .header, .context: " "
        }
    }

    var content: String {
        switch type {
        case .added, .removed:
            String(text.dropFirst(1))
        case .hunk:
            text
        case .header:
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
        case .hunk: .purple
        default: .clear
        }
    }

    var lineNumberColor: Color {
        switch self {
        case .added: .green.opacity(0.5)
        case .removed: .red.opacity(0.4)
        default: Color(.tertiaryLabel)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .header: .secondary
        case .hunk: .purple
        case .added: Color(.label)
        case .removed: Color(.label)
        case .context: Color(.secondaryLabel)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .added: Color.green.opacity(0.1)
        case .removed: Color.red.opacity(0.1)
        case .hunk: Color.purple.opacity(0.05)
        default: .clear
        }
    }
}
