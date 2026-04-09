import SwiftUI

struct ContextSummaryView: View {
    let summary: String
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bubble.left.fill")
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.purple.opacity(0.7))
                .padding(.top, compact ? 1 : 2)

            Text(summary)
                .font(compact ? .caption2 : .caption)
                .foregroundStyle(.secondary)
                .lineLimit(compact ? 1 : 2)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}
