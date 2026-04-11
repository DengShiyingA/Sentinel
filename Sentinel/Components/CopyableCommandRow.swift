import SwiftUI

/// A reusable row that shows a shell command in a monospaced code block
/// with a tap-to-copy button. Designed for Form `Section` content.
///
/// Visual:
///   ┌────────────────────────────────────────┐
///   │ label                                  │
///   │ $ sentinel run --port 7750       [📋] │
///   └────────────────────────────────────────┘
///
/// Tapping the copy button writes the command (without the `$ ` prefix)
/// to the system pasteboard and shows a brief ✓ affordance + haptic.
struct CopyableCommandRow: View {
    let label: String
    let command: String

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("$ \(command)")
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.vertical, 8)
                    .padding(.leading, 10)

                Spacer(minLength: 4)

                Button {
                    copy()
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(copied ? .green : .accentColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
                .accessibilityLabel(String(localized: "复制命令"))
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
        .padding(.vertical, 2)
    }

    private func copy() {
        UIPasteboard.general.string = command
        Haptic.allow()
        withAnimation(.easeInOut(duration: 0.18)) {
            copied = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.18)) {
                copied = false
            }
        }
    }
}
