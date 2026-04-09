import SwiftUI

struct InlineApprovalGroupCard: View {
    let group: ApprovalGroup
    let onDecision: (String, Decision) -> Void
    let onGroupDecision: (Decision) -> Void

    @Environment(TrustManager.self) private var trustManager
    @State private var isExpanded = false
    @State private var groupDecided: Decision?
    @State private var individualDecisions: Set<String> = []

    var body: some View {
        if let groupDecided {
            decidedView(groupDecided)
        } else {
            pendingView
        }
    }

    private var hasHighRisk: Bool {
        group.requests.contains { req in
            req.riskLevel == .requireFaceID
            || TrustManager.isHighRisk(path: ApprovalHelper.extractPath(from: req))
        }
    }

    private var canTrust: Bool {
        !hasHighRisk && group.requests.allSatisfy { $0.riskLevel != .requireFaceID }
    }

    private var liveRequests: [ApprovalRequest] {
        group.requests.filter { !individualDecisions.contains($0.id) }
    }

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

    private var pendingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            fileList
            if isExpanded { expandedItems }
            if hasHighRisk { highRiskWarning }
            actionButtons
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(hasHighRisk ? Color.red.opacity(0.04) : Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(hasHighRisk ? Color.red.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
        .animation(.spring(duration: 0.3, bounce: 0.1), value: isExpanded)
        .animation(.spring(duration: 0.3, bounce: 0.1), value: individualDecisions)
    }

    private var headerRow: some View {
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
            if hasHighRisk {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var fileList: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(liveRequests.prefix(isExpanded ? liveRequests.count : 5)) { req in
                HStack(spacing: 6) {
                    Circle()
                        .fill(req.riskLevel == .requireFaceID ? .red : .orange)
                        .frame(width: 5, height: 5)
                    Text(ApprovalHelper.extractPath(from: req) ?? req.toolName)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if TrustManager.isHighRisk(path: ApprovalHelper.extractPath(from: req)) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                    }
                }
            }
            if !isExpanded && liveRequests.count > 5 {
                Text(String(localized: "... 还有 \(liveRequests.count - 5) 个"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.leading, 4)
    }

    private var expandedItems: some View {
        VStack(spacing: 6) {
            ForEach(liveRequests) { request in
                InlineApprovalCard(request: request) { decision in
                    individualDecisions.insert(request.id)
                    onDecision(request.id, decision)
                    if individualDecisions.count == group.requests.count {
                        groupDecided = decision
                    }
                }
            }
        }
    }

    private var highRiskWarning: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
            Text(String(localized: "包含高风险文件，请逐个审查"))
                .font(.caption2)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                groupDecided = .blocked
                onGroupDecision(.blocked)
            } label: {
                Label(
                    String(localized: "全部拒绝 (\(liveRequests.count))"),
                    systemImage: "xmark.circle.fill"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button {
                if hasHighRisk {
                    withAnimation { isExpanded = true }
                    return
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                groupDecided = .allowed
                onGroupDecision(.allowed)
            } label: {
                Label(
                    String(localized: "全部允许 (\(liveRequests.count))"),
                    systemImage: hasHighRisk ? "exclamationmark.triangle" : "checkmark.circle.fill"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            }
            .buttonStyle(.borderedProminent)
            .tint(hasHighRisk ? .orange : .blue)

            if canTrust {
                groupTrustButton
            }
        }
    }

    private var groupTrustButton: some View {
        Menu {
            Section(String(localized: "信任 \(group.toolName)")) {
                ForEach(TrustManager.Duration.allCases, id: \.self) { duration in
                    Button(duration.label) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        trustManager.trust(toolName: group.toolName, duration: duration)
                        groupDecided = .allowed
                        onGroupDecision(.allowed)
                    }
                }
            }

            if let pattern = inferGroupPattern() {
                Section(String(localized: "信任路径 \(pattern)")) {
                    ForEach(TrustManager.Duration.allCases, id: \.self) { duration in
                        Button("\(duration.label) · \(pattern)") {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            trustManager.trust(toolName: group.toolName, pathPattern: pattern, duration: duration)
                            groupDecided = .allowed
                            onGroupDecision(.allowed)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "clock.badge.checkmark")
                .font(.subheadline)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.bordered)
        .tint(.green)
    }

    private func inferGroupPattern() -> String? {
        let paths = group.requests.compactMap { ApprovalHelper.extractPath(from: $0) }
        guard paths.count >= 2 else { return paths.first.flatMap { TrustManager.suggestPathPattern(from: $0) } }

        let dirs = Set(paths.map { ($0 as NSString).deletingLastPathComponent })
        let exts = Set(paths.map { ($0 as NSString).pathExtension })

        if dirs.count == 1, let dir = dirs.first, exts.count == 1, let ext = exts.first, !ext.isEmpty {
            return "\(dir)/*.\(ext)"
        } else if dirs.count == 1, let dir = dirs.first {
            return "\(dir)/*"
        }
        return nil
    }
}
