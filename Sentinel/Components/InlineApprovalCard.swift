import SwiftUI

struct InlineApprovalCard: View {
    let request: ApprovalRequest
    /// Callback when the user decides. `modifiedInput` is non-nil only when
    /// the user edited the tool arguments before tapping Allow.
    let onDecision: (Decision, [String: Any]?) -> Void

    @Environment(TrustManager.self) private var trustManager
    @State private var decided: Decision?
    @State private var isAuthenticating = false
    @State private var authError: String?
    @State private var showTrustMenu = false
    @State private var showEditor = false

    var body: some View {
        if let decided {
            decidedView(decided)
        } else {
            pendingView
                .sheet(isPresented: $showEditor) {
                    ArgEditorSheet(request: request) { editedInput in
                        Haptic.allow()
                        decided = .allowed
                        onDecision(.allowed, editedInput)
                    }
                }
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

            if let ctx = request.contextSummary, !ctx.isEmpty {
                ContextSummaryView(summary: ctx)
            }

            if let diff = request.diff, !diff.isEmpty {
                DiffView(diff: diff)
            }

            HStack(spacing: 8) {
                Button {
                    Haptic.block()
                    decided = .blocked
                    onDecision(.blocked, nil)
                } label: {
                    Label(String(localized: "拒绝"), systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                if canEdit {
                    Button {
                        showEditor = true
                    } label: {
                        Label(String(localized: "编辑"), systemImage: "pencil")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

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
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
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

    /// Show the edit button only when there's something worth editing.
    /// We gate on having at least one input field so read-only tools (which
    /// sometimes have no input) don't show a useless edit button.
    private var canEdit: Bool {
        !request.toolInput.isEmpty
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
        Haptic.allow()
        trustManager.trust(toolName: request.toolName, pathPattern: pathPattern, duration: duration)
        decided = .allowed
        onDecision(.allowed, nil)
    }

    private func handleAllow() {
        ApprovalHelper.handleAllow(
            request: request,
            onSuccess: { decided = .allowed; onDecision(.allowed, nil) },
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
