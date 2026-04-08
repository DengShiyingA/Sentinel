import SwiftUI

struct PairingView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(LocalDiscoveryService.self) private var local
    @Environment(RelayService.self) private var relay

    @State private var connectionMode = ConnectionMode.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                            .symbolEffect(.pulse, options: .repeating)

                        Text(String(localized: "Sentinel"))
                            .font(.largeTitle.bold())

                        Text(String(localized: "Claude Code 移动端审批"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Mode picker
                    Picker(String(localized: "连接模式"), selection: $connectionMode) {
                        ForEach(ConnectionMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .onChange(of: connectionMode) { _, newMode in
                        ConnectionMode.current = newMode
                        relay.switchMode(newMode)
                    }

                    switch connectionMode {
                    case .local:
                        localContent
                    case .cloudkit:
                        cloudkitContent
                    case .server:
                        serverContent
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Local

    private var localContent: some View {
        VStack(spacing: 20) {
            GroupBox {
                VStack(spacing: 16) {
                    if local.isConnected {
                        Label(String(localized: "已连接到 \(local.discoveredHost ?? "Mac")"),
                              systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green).font(.headline)
                    } else if local.isSearching {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(String(localized: "自动发现中...")).foregroundStyle(.secondary)
                        }
                    } else {
                        Label(String(localized: "未发现 Mac"), systemImage: "wifi.slash")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        local.startDiscovery()
                    } label: {
                        Label(String(localized: "重新搜索"), systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity).frame(height: 44)
                    }
                    .buttonStyle(.bordered).disabled(local.isSearching)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)

            instructions([
                String(localized: "在开发机上运行 sentinel start"),
                String(localized: "确保 Mac 和 iPhone 在同一 WiFi"),
                String(localized: "iOS 自动发现并连接，无需配对码"),
            ])
        }
        .onAppear {
            if !local.isConnected && !local.isSearching {
                local.startDiscovery()
            }
        }
    }

    // MARK: - CloudKit

    private var cloudkitContent: some View {
        VStack(spacing: 20) {
            GroupBox {
                VStack(spacing: 16) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.cyan)

                    Text(String(localized: "通过 iCloud 同步"))
                        .font(.headline)

                    Text(String(localized: "确保 Mac 和 iPhone 登录同一 Apple ID，审批请求会通过 iCloud 自动同步。"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if relay.isConnected {
                        Label(String(localized: "已连接"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        ProgressView(String(localized: "连接中..."))
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)

            instructions([
                String(localized: "在开发机上运行 sentinel start --mode cloudkit"),
                String(localized: "确保两台设备登录同一 Apple ID"),
                String(localized: "无需任何配对，自动同步"),
            ])
        }
    }

    // MARK: - Server

    @State private var serverURL = ""
    @State private var manualLink = ""
    @State private var isPairing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var showScanner = false
    @State private var showManualInput = false

    private var serverContent: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "服务器地址"))
                    .font(.caption).foregroundStyle(.secondary)
                TextField("https://your-server.com", text: $serverURL)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL).textContentType(.URL)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 24)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button { errorMessage = nil; showScanner = true } label: {
                    Label(String(localized: "扫描配对码"), systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity).frame(height: 50).fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(serverURL.isEmpty || isPairing)

                Button { errorMessage = nil; showManualInput = true } label: {
                    Label(String(localized: "手动输入链接"), systemImage: "link")
                        .frame(maxWidth: .infinity).frame(height: 50)
                }
                .buttonStyle(.bordered).controlSize(.large)
                .disabled(serverURL.isEmpty || isPairing)
            }
            .padding(.horizontal, 24)

            if isPairing { ProgressView(String(localized: "配对中...")).padding() }

            instructions([
                String(localized: "在开发机上运行 sentinel pair --mode server"),
                String(localized: "输入上方的服务器地址"),
                String(localized: "扫描终端显示的二维码"),
            ])
        }
        .fullScreenCover(isPresented: $showScanner) {
            NavigationStack {
                QRScannerView { link in showScanner = false; startServerPairing(link: link) }
                    .ignoresSafeArea()
                    .navigationTitle(String(localized: "扫描配对码"))
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
                .autocorrectionDisabled().textInputAutocapitalization(.never)
            Button(String(localized: "取消"), role: .cancel) { manualLink = "" }
            Button(String(localized: "配对")) { startServerPairing(link: manualLink); manualLink = "" }
        } message: {
            Text(String(localized: "粘贴 sentinel://pair/... 链接"))
        }
        .overlay { if showSuccess { successOverlay } }
    }

    private func startServerPairing(link: String) {
        isPairing = true; errorMessage = nil
        Task {
            do {
                let secret = try PairingService.parseDeepLink(link)
                try await pairing.pair(serverURL: serverURL, secret: secret)
                withAnimation(.spring(duration: 0.5)) { showSuccess = true }
                try? await Task.sleep(for: .seconds(1.5))
                showSuccess = false
            } catch { errorMessage = error.localizedDescription }
            isPairing = false
        }
    }

    // MARK: - Shared

    private func instructions(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, text in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(idx + 1)")
                        .font(.caption.bold()).foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(.tint, in: Circle())
                    Text(text).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundStyle(.green).symbolEffect(.bounce)
            Text(String(localized: "配对成功")).font(.title2.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial).transition(.opacity)
    }
}
