import SwiftUI

struct InlineSummaryCard: View {
    let summary: SessionSummary
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: summary.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(summary.isError ? .red : .green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(summary.displaySubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(summary.durationText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if !summary.filesModified.isEmpty {
                        Label(String(localized: "文件"), systemImage: "doc.text")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        ForEach(summary.filesModified, id: \.self) { file in
                            Text(file)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.primary)
                                .padding(.leading, 24)
                        }
                    }

                    HStack(spacing: 16) {
                        Label("\(summary.commandsRun)", systemImage: "terminal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("\(summary.approvalsAllowed) \(String(localized: "允许"))", systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.green)
                        if summary.approvalsBlocked > 0 {
                            Label("\(summary.approvalsBlocked) \(String(localized: "拒绝"))", systemImage: "xmark")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(summary.isError ? Color.red.opacity(0.06) : Color.green.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    summary.isError ? Color.red.opacity(0.3) : Color.green.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}
