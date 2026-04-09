import SwiftUI

struct InlineApprovalGroupCard: View {
    let group: ApprovalGroup
    let onDecision: (String, Decision) -> Void
    let onGroupDecision: (Decision) -> Void

    @State private var isExpanded = false
    @State private var groupDecided: Decision?

    var body: some View {
        if let groupDecided {
            decidedView(groupDecided)
        } else {
            pendingView
        }
    }

    // MARK: - Decided (collapsed)

    private func decidedView(_ decision: Decision) -> some View {
        HStack(spacing: 8) {
            Image(systemName: decision == .allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text(decision == .allowed ? String(localized: "已允许") : String(localized: "已拒绝"))
                .font(.caption.weight(.medium))
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text("\(group.requests.count) \(group.toolName)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Pending (interactive)

    private var pendingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                ToolIcon(toolName: group.toolName, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayLabel)
                        .font(.subheadline.weight(.semibold))
                    Text(group.toolName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Expanded: individual items
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(group.requests) { request in
                        InlineApprovalCard(request: request) { decision in
                            onDecision(request.id, decision)
                        }
                    }
                }
            }

            // Group action buttons (only when not expanded)
            if !isExpanded {
                HStack(spacing: 10) {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        groupDecided = .blocked
                        onGroupDecision(.blocked)
                    } label: {
                        Label(
                            String(localized: "全部拒绝 (\(group.requests.count))"),
                            systemImage: "xmark.circle.fill"
                        )
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        groupDecided = .allowed
                        onGroupDecision(.allowed)
                    } label: {
                        Label(
                            String(localized: "全部允许 (\(group.requests.count))"),
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
