import SwiftUI

struct SettingsView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(SocketClient.self) private var socket
    @Environment(LocalDiscoveryService.self) private var local
    @Environment(RelayService.self) private var relay
    @Environment(ApprovalStore.self) private var store

    @State private var showUnpairAlert = false
    @State private var showPairingSheet = false
    @State private var showManualConnect = false
    @State private var connectionMode = ConnectionMode.current
    @State private var manualHost = "localhost"
    @State private var manualPort = "7750"

    var body: some View {
        NavigationStack {
            List {
                // Mode picker
                Section {
                    Picker(String(localized: "连接模式"), selection: $connectionMode) {
                        ForEach(ConnectionMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                    .onChange(of: connectionMode) { _, newMode in
                        relay.switchMode(newMode)
                    }
                } footer: {
                    Text(connectionMode.description)
                }

                // Connection
                Section(String(localized: "连接")) {
                    // Status row
                    LabeledContent(String(localized: "状态")) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(relay.isConnected ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(statusText).foregroundStyle(.secondary)
                        }
                    }

                    // Mode-specific info
                    if connectionMode == .local {
                        if let host = local.discoveredHost {
                            LabeledContent(String(localized: "Mac")) {
                                Text(host).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                        }

                        if local.isSearching {
                            LabeledContent(String(localized: "搜索中")) {
                                ProgressView()
                            }
                        }

                        // Manual connect (for Simulator)
                        Button {
                            showManualConnect = true
                        } label: {
                            Label(String(localized: "手动连接"), systemImage: "network")
                        }
                    }

                    if connectionMode == .cloudkit {
                        LabeledContent(String(localized: "同步")) {
                            Text("iCloud").foregroundStyle(.secondary)
                        }
                    }

                    if connectionMode == .server {
                        if pairing.isPaired {
                            LabeledContent(String(localized: "服务器")) {
                                Text(pairing.serverURL)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        } else {
                            Button {
                                showPairingSheet = true
                            } label: {
                                Label(String(localized: "配对服务器"), systemImage: "qrcode")
                            }
                        }
                    }

                    if let error = relay.connectionError {
                        LabeledContent(String(localized: "错误")) {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }

                    // Disconnect button (only when connected)
                    if relay.isConnected {
                        Button(role: .destructive) {
                            relay.disconnect()
                        } label: {
                            Label(String(localized: "断开连接"), systemImage: "wifi.slash")
                        }
                    }
                }

                // Rules
                Section {
                    NavigationLink {
                        RulesView()
                    } label: {
                        Label(String(localized: "规则管理"), systemImage: "slider.horizontal.3")
                    }
                }

                // Stats
                Section(String(localized: "统计")) {
                    LabeledContent(String(localized: "待处理")) {
                        Text("\(store.pendingRequests.count)").monospacedDigit()
                    }
                    LabeledContent(String(localized: "已处理")) {
                        Text("\(store.resolvedCount)").monospacedDigit()
                    }
                }

                // Unpair (server mode only)
                if connectionMode == .server && pairing.isPaired {
                    Section {
                        Button(role: .destructive) {
                            showUnpairAlert = true
                        } label: {
                            Label(String(localized: "解除配对"), systemImage: "link.badge.plus")
                        }
                    }
                }

                // About
                Section(String(localized: "关于")) {
                    LabeledContent(String(localized: "版本")) {
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                    LabeledContent("Sentinel") {
                        Text("Claude Code Rule Engine")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "设置"))
            .alert(String(localized: "解除配对"), isPresented: $showUnpairAlert) {
                Button(String(localized: "取消"), role: .cancel) {}
                Button(String(localized: "解除配对"), role: .destructive) {
                    socket.disconnect()
                    pairing.unpair()
                }
            } message: {
                Text(String(localized: "确定要解除配对吗？"))
            }
            .alert(String(localized: "手动连接"), isPresented: $showManualConnect) {
                TextField(String(localized: "主机地址"), text: $manualHost)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField(String(localized: "端口"), text: $manualPort)
                    .keyboardType(.numberPad)
                Button(String(localized: "取消"), role: .cancel) {}
                Button(String(localized: "连接")) {
                    let port = UInt16(manualPort) ?? 7750
                    local.connect(host: manualHost, port: port)
                }
            } message: {
                Text(String(localized: "Simulator 测试请输入 localhost:7750"))
            }
            .sheet(isPresented: $showPairingSheet) {
                PairingView()
            }
        }
    }

    private var statusText: String {
        let mode = connectionMode.label
        if relay.isConnected {
            return "\(mode) · \(String(localized: "已连接"))"
        } else {
            return "\(mode) · \(String(localized: "未连接"))"
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
