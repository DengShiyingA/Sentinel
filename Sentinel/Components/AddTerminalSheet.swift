import SwiftUI

struct AddTerminalSheet: View {
    let onAdd: (TerminalProfile) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var portText = "7750"
    @State private var showQRScanner = false
    @State private var scanErrorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "终端 1"), text: $name)
                } header: {
                    Text(String(localized: "名称"))
                }

                Section {
                    HStack {
                        Text(String(localized: "端口"))
                        Spacer()
                        TextField("7750", text: $portText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text(String(localized: "连接"))
                } footer: {
                    Text(String(localized: "在 Mac 上运行：sentinel run --port \(portText.isEmpty ? "7750" : portText)"))
                        .font(.caption)
                        .monospaced()
                }

                Section {
                    Button {
                        showQRScanner = true
                    } label: {
                        Label(String(localized: "扫描远程二维码"), systemImage: "qrcode.viewfinder")
                    }
                } header: {
                    Text(String(localized: "远程访问"))
                } footer: {
                    Text(String(localized: "Mac 端运行 sentinel run --remote 获取二维码"))
                }
            }
            .navigationTitle(String(localized: "添加终端"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "取消")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "添加")) {
                        let port = Int(portText) ?? 7750
                        let profile = TerminalProfile(
                            name: name.isEmpty ? String(localized: "终端") : name,
                            port: port,
                            useBonjour: port == 7750
                        )
                        onAdd(profile)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView { scannedString in
                    handleRemoteScan(scannedString)
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
        }
    }

    private func handleRemoteScan(_ scannedString: String) {
        showQRScanner = false

        guard let url = URL(string: scannedString),
              url.scheme == "sentinel-remote",
              let host = url.host, !host.isEmpty else {
            scanErrorMessage = String(localized: "无效的远程二维码")
            return
        }

        // Extract #key=ENCODED fragment
        guard let fragment = url.fragment else {
            scanErrorMessage = String(localized: "远程二维码缺少密钥")
            return
        }

        // fragment is "key=ENCODED_BASE64"
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

        var profile = TerminalProfile(
            name: String(localized: "远程 \(host)"),
            port: 443,
            useBonjour: false
        )
        profile.remoteUrl = "wss://\(host)"
        profile.remotePublicKey = decodedKey

        onAdd(profile)
        dismiss()
    }
}
