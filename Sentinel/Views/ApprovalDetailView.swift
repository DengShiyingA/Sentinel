import SwiftUI
import UIKit

struct ApprovalDetailView: View {
    let request: ApprovalRequest

    @Environment(ApprovalStore.self) private var store
    @Environment(TrustManager.self) private var trustManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var authError: String?
    @State private var showTrustOptions = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    riskBanner
                    detailSection
                    if let diff = request.diff, !diff.isEmpty {
                        DiffView(diff: diff)
                    }
                    toolInputSection
                }
                .padding()
            }

            Divider()
            actionButtons
        }
        .navigationTitle(request.toolName)
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: "认证失败"), isPresented: .init(
            get: { authError != nil },
            set: { if !$0 { authError = nil } }
        )) {
            Button(String(localized: "确定")) { authError = nil }
        } message: {
            Text(authError ?? "")
        }
    }

    // MARK: - Risk Banner

    private var riskBanner: some View {
        HStack {
            Image(systemName: request.riskLevel.systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(request.riskLevel.label)
                    .font(.headline)
                Text(riskDescription)
                    .font(.caption)
                    .opacity(0.8)
            }
            Spacer()
            CountdownRing(
                timeoutAt: request.timeoutAt,
                totalDuration: SentinelConfig.approvalTimeoutSeconds,
                size: 56,
                lineWidth: 4
            ) {
                store.sendDecision(requestId: request.id, decision: .blocked)
                dismiss()
            }
        }
        .padding()
        .foregroundStyle(.white)
        .background(bannerColor, in: RoundedRectangle(cornerRadius: 12))
    }

    private var riskDescription: String {
        switch request.riskLevel {
        case .requireFaceID: String(localized: "高风险操作，需要 Face ID 验证")
        case .requireConfirm: String(localized: "中等风险操作，需要手动确认")
        }
    }

    private var bannerColor: Color {
        switch request.riskLevel {
        case .requireFaceID: .red
        case .requireConfirm: .orange
        }
    }

    // MARK: - Detail Section

    private var detailSection: some View {
        GroupBox(String(localized: "操作详情")) {
            VStack(spacing: 0) {
                detailRow(label: String(localized: "类型"), value: humanReadableToolName)
                Divider().padding(.vertical, 4)
                detailRow(label: String(localized: "工具"), value: request.toolName, monospaced: true)
                if let path = extractPath {
                    Divider().padding(.vertical, 4)
                    detailRow(label: String(localized: "目标"), value: path, monospaced: true)
                }
                Divider().padding(.vertical, 4)
                detailRow(
                    label: String(localized: "时间"),
                    value: request.timestamp.formatted(date: .omitted, time: .standard)
                )
            }
            .padding(.vertical, 4)
        }
    }

    private func detailRow(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            Spacer()
            Text(value)
                .font(monospaced ? .caption.monospaced() : .callout)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Tool Input Section

    private var toolInputSection: some View {
        GroupBox(String(localized: "参数")) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(formattedInput)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var formattedInput: String {
        do {
            let data = try JSONEncoder.sentinelEncoder.encode(request.toolInput)
            let obj = try JSONSerialization.jsonObject(with: data)
            let pretty = try JSONSerialization.data(
                withJSONObject: obj,
                options: [.prettyPrinted, .sortedKeys]
            )
            return String(data: pretty, encoding: .utf8) ?? request.toolInput.description
        } catch {
            // Show raw description with error hint rather than silently degrading
            return "⚠ \(error.localizedDescription)\n\n\(request.toolInput.description)"
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Block
                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    store.sendDecision(requestId: request.id, decision: .blocked)
                    dismiss()
                } label: {
                    Label(String(localized: "拒绝"), systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)

                // Allow
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
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)
            }

            // Trust timer — only for non-FaceID tools (high-risk shouldn't be auto-trusted)
            if request.riskLevel != .requireFaceID {
                Button {
                    showTrustOptions = true
                } label: {
                    Label(String(localized: "允许并信任一段时间"), systemImage: "clock.badge.checkmark")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .confirmationDialog(
                    String(localized: "信任 \(request.toolName)"),
                    isPresented: $showTrustOptions,
                    titleVisibility: .visible
                ) {
                    ForEach(TrustManager.durations, id: \.minutes) { option in
                        Button(option.label) {
                            trustManager.trust(toolName: request.toolName, minutes: option.minutes)
                            store.sendDecision(requestId: request.id, decision: .allowed)
                            dismiss()
                        }
                    }
                    Button(String(localized: "取消"), role: .cancel) {}
                } message: {
                    Text(String(localized: "信任期内，\(request.toolName) 的请求将自动允许"))
                }
            }
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Allow Logic

    private func handleAllow() {
        ApprovalHelper.handleAllow(
            request: request,
            onSuccess: { store.sendDecision(requestId: request.id, decision: .allowed); dismiss() },
            onAuthStart: { isAuthenticating = true },
            onAuthEnd: { isAuthenticating = false },
            onError: { authError = $0 }
        )
    }

    // MARK: - Helpers

    private var humanReadableToolName: String {
        ApprovalHelper.humanReadableToolName(for: request.toolName)
    }

    private var extractPath: String? {
        ApprovalHelper.extractPath(from: request)
    }
}
