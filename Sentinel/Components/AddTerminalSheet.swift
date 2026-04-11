import SwiftUI

/// Sheet for creating or editing a TerminalProfile.
///
/// When `existing` is nil, the sheet is in "add" mode: empty form, commit
/// button says 添加.
/// When `existing` is a profile, the sheet is in "edit" mode: fields are
/// pre-populated, commit button says 保存, and a destructive "delete" row
/// is shown at the bottom.
struct AddTerminalSheet: View {
    let existing: TerminalProfile?
    let onSave: (TerminalProfile) -> Void
    let onDelete: ((TerminalProfile) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name = ""
    @State private var useBonjour = true
    @State private var portText = "7750"
    @State private var hostText = ""
    @State private var remoteUrl: String?
    @State private var remotePublicKey: String?

    // UI state
    @State private var showQRScanner = false
    @State private var scanErrorMessage: String?
    @State private var showDeleteConfirm = false

    // MARK: - Init

    init(
        existing: TerminalProfile? = nil,
        onSave: @escaping (TerminalProfile) -> Void,
        onDelete: ((TerminalProfile) -> Void)? = nil
    ) {
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var isEditing: Bool { existing != nil }

    /// The `sentinel run` command the user should run on the Mac for this
    /// profile. Reflects the port textfield live so the copy stays accurate
    /// as the user types.
    private var lanStartCommand: String {
        let port = portText.trimmingCharacters(in: .whitespaces)
        if port.isEmpty || port == "7750" {
            return "sentinel run"
        }
        return "sentinel run --port \(port)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "终端 1"), text: $name)
                } header: {
                    Text(String(localized: "名称"))
                }

                Section {
                    Toggle(String(localized: "自动发现 (Bonjour)"), isOn: $useBonjour)
                    HStack {
                        Text(String(localized: "端口"))
                        Spacer()
                        TextField("7750", text: $portText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    if !useBonjour {
                        HStack {
                            Text(String(localized: "主机"))
                            Spacer()
                            TextField("192.168.1.10", text: $hostText)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 200)
                        }
                    }

                    CopyableCommandRow(
                        label: String(localized: "在 Mac 上运行"),
                        command: lanStartCommand
                    )
                } header: {
                    Text(String(localized: "局域网连接"))
                } footer: {
                    if useBonjour {
                        Text(String(localized: "通过 mDNS 自动发现同局域网的 Mac。"))
                            .font(.caption)
                    } else {
                        Text(String(localized: "输入 Mac 的 IP/主机名。当 Bonjour 不可用（跨子网 / 公司网络）时使用。"))
                            .font(.caption)
                    }
                }

                Section {
                    if let remoteUrl, !remoteUrl.isEmpty {
                        LabeledContent(String(localized: "Tunnel")) {
                            Text(remoteUrl.replacingOccurrences(of: "wss://", with: ""))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Button {
                            showQRScanner = true
                        } label: {
                            Label(String(localized: "重新扫描"), systemImage: "qrcode.viewfinder")
                        }
                        Button(role: .destructive) {
                            self.remoteUrl = nil
                            self.remotePublicKey = nil
                        } label: {
                            Label(String(localized: "清除远程配置"), systemImage: "xmark.circle")
                        }
                    } else {
                        Button {
                            showQRScanner = true
                        } label: {
                            Label(String(localized: "扫描远程二维码"), systemImage: "qrcode.viewfinder")
                        }
                    }

                    CopyableCommandRow(
                        label: String(localized: "在 Mac 上运行"),
                        command: "sentinel run --remote"
                    )
                } header: {
                    Text(String(localized: "远程访问"))
                } footer: {
                    Text(String(localized: "Mac 运行命令后扫码配对。出门蜂窝网络时自动走 Cloudflare Tunnel。"))
                        .font(.caption)
                }

                if isEditing, let profile = existing {
                    metaSection(profile)
                }

                if isEditing, onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label(String(localized: "删除此终端"), systemImage: "trash")
                        }
                    } footer: {
                        Text(String(localized: "删除后历史记录不受影响。规则不会被删除。"))
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing
                             ? String(localized: "编辑终端")
                             : String(localized: "添加终端"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "取消")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing
                           ? String(localized: "保存")
                           : String(localized: "添加")) {
                        commit()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canCommit)
                }
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView { scanned in
                    handleRemoteScan(scanned)
                }
            }
            .alert(
                String(localized: "扫描失败"),
                isPresented: Binding(
                    get: { scanErrorMessage != nil },
                    set: { if !$0 { scanErrorMessage = nil } }
                ),
                presenting: scanErrorMessage
            ) { _ in
                Button(String(localized: "好")) { scanErrorMessage = nil }
            } message: { message in
                Text(message)
            }
            .confirmationDialog(
                String(localized: "确定删除此终端？"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "删除"), role: .destructive) {
                    if let profile = existing {
                        onDelete?(profile)
                        dismiss()
                    }
                }
                Button(String(localized: "取消"), role: .cancel) {}
            }
            .onAppear { hydrate() }
        }
    }

    // MARK: - Sections

    private func metaSection(_ profile: TerminalProfile) -> some View {
        Section {
            if let path = profile.lastPath {
                LabeledContent(String(localized: "上次路径")) {
                    Text(path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
            if let used = profile.lastUsedAt {
                LabeledContent(String(localized: "上次使用")) {
                    Text(used, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent(String(localized: "创建时间")) {
                Text(profile.createdAt, format: .dateTime.month().day().hour().minute())
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "状态"))
        }
    }

    // MARK: - Hydration

    private func hydrate() {
        guard let p = existing else { return }
        name = p.name
        useBonjour = p.useBonjour
        portText = String(p.port)
        hostText = p.host
        remoteUrl = p.remoteUrl
        remotePublicKey = p.remotePublicKey
    }

    // MARK: - Validation

    private var canCommit: Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if Int(portText) == nil { return false }
        if !useBonjour && hostText.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return true
    }

    // MARK: - Commit

    private func commit() {
        let port = Int(portText) ?? 7750
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedHost = hostText.trimmingCharacters(in: .whitespaces)

        if var profile = existing {
            // Edit mode: mutate existing profile, preserving id/createdAt/lastUsedAt/lastPath
            profile.name = trimmedName.isEmpty ? profile.name : trimmedName
            profile.port = port
            profile.useBonjour = useBonjour
            profile.host = useBonjour ? "" : trimmedHost
            profile.remoteUrl = remoteUrl
            profile.remotePublicKey = remotePublicKey
            onSave(profile)
        } else {
            // Add mode: fresh profile with defaults for lastPath/lastUsedAt
            var profile = TerminalProfile(
                name: trimmedName.isEmpty ? String(localized: "终端") : trimmedName,
                port: port,
                useBonjour: useBonjour,
                host: useBonjour ? "" : trimmedHost
            )
            profile.remoteUrl = remoteUrl
            profile.remotePublicKey = remotePublicKey
            onSave(profile)
        }
        dismiss()
    }

    // MARK: - Remote scan

    private func handleRemoteScan(_ scannedString: String) {
        showQRScanner = false

        guard let url = URL(string: scannedString),
              url.scheme == "sentinel-remote",
              let host = url.host, !host.isEmpty else {
            scanErrorMessage = String(localized: "无效的远程二维码")
            return
        }

        guard let fragment = url.fragment else {
            scanErrorMessage = String(localized: "远程二维码缺少密钥")
            return
        }

        let parts = fragment.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0] == "key" else {
            scanErrorMessage = String(localized: "远程二维码缺少密钥")
            return
        }

        let encodedKey = String(parts[1])
        guard let decodedKey = encodedKey.removingPercentEncoding, !decodedKey.isEmpty else {
            scanErrorMessage = String(localized: "密钥解码失败")
            return
        }

        remoteUrl = "wss://\(host)"
        remotePublicKey = decodedKey

        // Auto-fill name from host ONLY if we're in add mode and name is empty —
        // editing shouldn't rename unless the user explicitly changes it.
        if !isEditing && name.trimmingCharacters(in: .whitespaces).isEmpty {
            name = String(localized: "远程 \(host)")
        }
    }
}
