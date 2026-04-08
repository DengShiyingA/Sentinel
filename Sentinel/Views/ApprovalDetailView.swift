import SwiftUI

struct ApprovalDetailView: View {
    let request: ApprovalRequest

    @Environment(ApprovalStore.self) private var store
    @State private var isAuthenticating = false
    @State private var authError: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    riskBanner
                    detailSection
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
                totalDuration: 120,
                size: 56,
                lineWidth: 4
            ) {
                store.sendDecision(requestId: request.id, decision: .blocked)
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
        guard let data = try? JSONEncoder.sentinelEncoder.encode(request.toolInput),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                  withJSONObject: obj,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let str = String(data: pretty, encoding: .utf8) else {
            return request.toolInput.description
        }
        return str
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Block
            Button(role: .destructive) {
                store.sendDecision(requestId: request.id, decision: .blocked)
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
        .padding()
        .background(.bar)
    }

    // MARK: - Allow Logic

    private func handleAllow() {
        if request.riskLevel == .requireFaceID {
            isAuthenticating = true
            Task {
                do {
                    try await BiometricService.authenticate(
                        reason: String(localized: "验证身份以允许高风险操作")
                    )
                    store.sendDecision(requestId: request.id, decision: .allowed)
                } catch {
                    authError = error.localizedDescription
                }
                isAuthenticating = false
            }
        } else {
            store.sendDecision(requestId: request.id, decision: .allowed)
        }
    }

    // MARK: - Helpers

    private var humanReadableToolName: String {
        let name = request.toolName.lowercased()
        if name.contains("write") || name.contains("edit") {
            return String(localized: "文件写入")
        } else if name.contains("bash") || name.contains("exec") {
            return String(localized: "命令执行")
        } else if name.contains("read") {
            return String(localized: "文件读取")
        } else if name.contains("grep") || name.contains("search") || name.contains("glob") {
            return String(localized: "文件搜索")
        } else if name.contains("delete") || name.contains("rm") {
            return String(localized: "文件删除")
        } else {
            return String(localized: "工具调用")
        }
    }

    private var extractPath: String? {
        request.toolInput["file_path"]?.description
            ?? request.toolInput["path"]?.description
            ?? request.toolInput["command"]?.description
    }
}
