import SwiftUI

struct InlineApprovalCard: View {
    let request: ApprovalRequest
    let onDecision: (Decision) -> Void

    @Environment(TrustManager.self) private var trustManager
    @State private var decided: Decision?
    @State private var isAuthenticating = false
    @State private var authError: String?
    @State private var showTrustMenu = false

    var body: some View {
        if let decided {
            decidedView(decided)
        } else {
            pendingView
        }
    }

    private func decidedView(_ decision: Decision) -> some View {
        HStack(spacing: 8) {
            Image(systemName: decision == .allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text(decision == .allowed ? String(localized: "已允许") : String(localized: "已拒绝"))
                .font(.caption.weight(.medium))
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text(request.toolName)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            if let path = extractPath {
                Text(path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var pendingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ToolIcon(toolName: request.toolName, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.toolName)
                        .font(.subheadline.weight(.semibold))
                    if let path = extractPath {
                        Text(path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()
                if let diff = request.diff, !diff.isEmpty {
                    DiffSummaryBadge(diff: diff)
                }
                RiskBadge(riskLevel: request.riskLevel)
                CountdownText(timeoutAt: request.timeoutAt)
            }

            if let diff = request.diff, !diff.isEmpty {
                DiffView(diff: diff)
            }

            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    decided = .blocked
                    onDecision(.blocked)
                } label: {
                    Label(String(localized: "拒绝"), systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    handleAllow()
                } label: {
                    Group {
                        if isAuthenticating {
                            ProgressView()
                        } else if request.riskLevel == .requireFaceID {
                            Label(String(localized: "允许"), systemImage: "faceid")
                        } else {
                            Label(String(localized: "允许"), systemImage: "checkmark.circle.fill")
                        }
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)

                if canTrust {
                    trustButton
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .alert(String(localized: "认证失败"), isPresented: .init(
            get: { authError != nil },
            set: { if !$0 { authError = nil } }
        )) {
            Button(String(localized: "确定")) { authError = nil }
        } message: {
            Text(authError ?? "")
        }
    }

    private var canTrust: Bool {
        request.riskLevel != .requireFaceID && !TrustManager.isHighRisk(path: extractPath)
    }

    private var trustButton: some View {
        Menu {
            let suggestedPattern = TrustManager.suggestPathPattern(from: extractPath)

            Section(String(localized: "信任 \(request.toolName)")) {
                ForEach(TrustManager.Duration.allCases, id: \.self) { duration in
                    Button(duration.label) {
                        trustAndAllow(duration: duration, pathPattern: nil)
                    }
                }
            }

            if let pattern = suggestedPattern {
                Section(String(localized: "信任路径 \(pattern)")) {
                    ForEach(TrustManager.Duration.allCases, id: \.self) { duration in
                        Button("\(duration.label) · \(pattern)") {
                            trustAndAllow(duration: duration, pathPattern: pattern)
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

    private func trustAndAllow(duration: TrustManager.Duration, pathPattern: String?) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        trustManager.trust(toolName: request.toolName, pathPattern: pathPattern, duration: duration)
        decided = .allowed
        onDecision(.allowed)
    }

    private func handleAllow() {
        ApprovalHelper.handleAllow(
            request: request,
            onSuccess: { decided = .allowed; onDecision(.allowed) },
            onAuthStart: { isAuthenticating = true },
            onAuthEnd: { isAuthenticating = false },
            onError: { authError = $0 }
        )
    }

    private var extractPath: String? {
        ApprovalHelper.extractPath(from: request)
    }

    private var cardBackground: Color {
        switch request.riskLevel {
        case .requireFaceID: Color.red.opacity(0.06)
        case .requireConfirm: Color.orange.opacity(0.06)
        }
    }

    private var borderColor: Color {
        switch request.riskLevel {
        case .requireFaceID: .red.opacity(0.3)
        case .requireConfirm: .orange.opacity(0.3)
        }
    }
}
