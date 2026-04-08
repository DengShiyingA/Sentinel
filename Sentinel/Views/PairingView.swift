import SwiftUI

struct PairingView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(\.dismiss) private var dismiss

    @State private var serverURL = ""
    @State private var manualLink = ""
    @State private var isPairing = false
    @State private var errorMessage: String?
    @State private var showScanner = false
    @State private var showManualInput = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)

                        Text(String(localized: "服务器配对"))
                            .font(.title2.bold())
                    }
                    .padding(.top, 32)

                    // Server URL
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "服务器地址"))
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("https://your-server.com", text: $serverURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 24)

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.caption).foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            errorMessage = nil
                            showScanner = true
                        } label: {
                            Label(String(localized: "扫描配对码"), systemImage: "qrcode.viewfinder")
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(serverURL.isEmpty || isPairing)

                        Button {
                            errorMessage = nil
                            showManualInput = true
                        } label: {
                            Label(String(localized: "手动输入链接"), systemImage: "link")
                                .frame(maxWidth: .infinity).frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        .disabled(serverURL.isEmpty || isPairing)
                    }
                    .padding(.horizontal, 24)

                    if isPairing {
                        ProgressView(String(localized: "配对中..."))
                    }

                    // Steps
                    VStack(alignment: .leading, spacing: 8) {
                        stepRow("1", String(localized: "在 Mac 运行 sentinel pair --mode server -s URL"))
                        stepRow("2", String(localized: "输入上方的服务器地址"))
                        stepRow("3", String(localized: "扫描终端显示的二维码"))
                    }
                    .padding(16)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle(String(localized: "配对"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "取消")) { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                NavigationStack {
                    QRScannerView { link in
                        showScanner = false
                        doPairing(link: link)
                    }
                    .ignoresSafeArea()
                    .navigationTitle(String(localized: "扫描"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "取消")) { showScanner = false }
                        }
                    }
                }
            }
            .alert(String(localized: "输入配对链接"), isPresented: $showManualInput) {
                TextField("sentinel://pair/...", text: $manualLink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button(String(localized: "取消"), role: .cancel) { manualLink = "" }
                Button(String(localized: "配对")) {
                    doPairing(link: manualLink)
                    manualLink = ""
                }
            } message: {
                Text(String(localized: "粘贴 sentinel://pair/... 链接"))
            }
        }
    }

    private func doPairing(link: String) {
        isPairing = true
        errorMessage = nil
        Task {
            do {
                let secret = try PairingService.parseDeepLink(link)
                try await pairing.pair(serverURL: serverURL, secret: secret)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPairing = false
        }
    }

    private func stepRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.caption.bold()).foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.tint, in: Circle())
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
