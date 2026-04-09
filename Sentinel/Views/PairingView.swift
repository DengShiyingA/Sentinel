import SwiftUI

struct PairingView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(\.dismiss) private var dismiss

    @State private var isPairing = false
    @State private var errorMessage: String?
    @State private var showScanner = false
    @State private var showManualInput = false
    @State private var manualLink = ""
    @State private var copiedCommand = false
    @State private var copyResetTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Hero
                VStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text(String(localized: "配对 Mac"))
                        .font(.title2.bold())

                    Text(String(localized: "在 Mac 终端运行配对命令，然后扫描屏幕上的二维码"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Error
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.caption).foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                // Primary action: Scan
                VStack(spacing: 12) {
                    Button {
                        errorMessage = nil
                        showScanner = true
                    } label: {
                        Label(String(localized: "扫描二维码"), systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isPairing)

                    Button {
                        errorMessage = nil
                        showManualInput = true
                    } label: {
                        Text(String(localized: "手动粘贴链接"))
                            .font(.subheadline)
                    }
                    .disabled(isPairing)
                }
                .padding(.horizontal, 24)

                if isPairing {
                    ProgressView(String(localized: "配对中..."))
                }

                Spacer()

                // Mac command hint with copy button
                VStack(spacing: 8) {
                    Text(String(localized: "Mac 终端运行："))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text("sentinel pair --mode server -s URL")
                            .font(.caption.monospaced())
                            .lineLimit(1)

                        Button {
                            UIPasteboard.general.string = "sentinel pair --mode server -s "
                            copiedCommand = true
                            copyResetTask?.cancel()
                            copyResetTask = Task {
                                try? await Task.sleep(for: .seconds(2))
                                guard !Task.isCancelled else { return }
                                copiedCommand = false
                            }
                        } label: {
                            Image(systemName: copiedCommand ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(copiedCommand ? .green : .secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.bottom, 16)
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
            .alert(String(localized: "粘贴配对链接"), isPresented: $showManualInput) {
                TextField("sentinel://pair/...", text: $manualLink)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button(String(localized: "取消"), role: .cancel) { manualLink = "" }
                Button(String(localized: "配对")) {
                    doPairing(link: manualLink)
                    manualLink = ""
                }
            } message: {
                Text(String(localized: "粘贴终端显示的 sentinel://pair/... 链接"))
            }
        }
    }

    private func doPairing(link: String) {
        isPairing = true
        errorMessage = nil
        Task {
            do {
                let result = try PairingService.parseDeepLink(link)

                guard let serverURL = result.serverURL, !serverURL.isEmpty else {
                    // Old format link without embedded server URL — show error
                    errorMessage = String(localized: "请使用最新版 CLI 生成配对码（sentinel pair --mode server -s URL）")
                    isPairing = false
                    return
                }

                try await pairing.pair(serverURL: serverURL, secret: result.secret)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPairing = false
        }
    }
}
