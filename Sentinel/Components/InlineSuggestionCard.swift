import SwiftUI

struct InlineSuggestionCard: View {
    let suggestion: RuleSuggestion
    let onCreateRule: () -> Void
    let onDismiss: () -> Void

    @State private var decided = false

    var body: some View {
        if decided {
            decidedView
        } else {
            pendingView
        }
    }

    private var decidedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(String(localized: "已创建规则"))
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
            Text(suggestion.toolName)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var pendingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                Text(suggestion.displayText)
                    .font(.subheadline)
            }

            HStack(spacing: 10) {
                Button {
                    onDismiss()
                } label: {
                    Label(String(localized: "忽略"), systemImage: "xmark")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.bordered)

                Button {
                    decided = true
                    onCreateRule()
                } label: {
                    Label(String(localized: "创建规则"), systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .fill(Color.blue.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
