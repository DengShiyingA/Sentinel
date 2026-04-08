import SwiftUI

struct SettingsView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(SocketClient.self) private var socket
    @Environment(LocalDiscoveryService.self) private var local
    @Environment(RelayService.self) private var relay
    @Environment(ApprovalStore.self) private var store

    @State private var showUnpairAlert = false
    @State private var connectionMode = ConnectionMode.current

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

                // Connection status
                Section(String(localized: "连接")) {
                    HStack {
                        Text(String(localized: "状态"))
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(relay.isConnected ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(relay.isConnected
                                 ? String(localized: "已连接")
                                 : String(localized: "未连接"))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Mode-specific details
                    switch connectionMode {
                    case .local:
                        if let host = local.discoveredHost {
                            LabeledContent(String(localized: "Mac")) {
                                Text(host).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                        }
                        if local.isSearching {
                            HStack {
                                Text(String(localized: "搜索中"))
                                Spacer()
                                ProgressView()
                            }
                        }

                    case .cloudkit:
                        LabeledContent(String(localized: "同步方式")) {
                            Text("iCloud Private Database")
                                .font(.caption).foregroundStyle(.secondary)
                        }

                    case .server:
                        if let error = socket.connectionError {
                            HStack {
                                Text(String(localized: "错误"))
                                Spacer()
                                Text(error).font(.caption).foregroundStyle(.red)
                            }
                        }
                    }
                }

                // Server info (server mode only)
                if connectionMode == .server {
                    Section(String(localized: "服务器")) {
                        LabeledContent(String(localized: "地址")) {
                            Text(pairing.serverURL)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        LabeledContent(String(localized: "Mac 设备")) {
                            Text(pairing.macDeviceId.prefix(8) + "...")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
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
                    } footer: {
                        Text(String(localized: "解除配对将断开与 Mac 的连接，需要重新配对"))
                    }
                }

                // About
                Section(String(localized: "关于")) {
                    LabeledContent(String(localized: "版本")) {
                        Text("0.1.0").foregroundStyle(.secondary)
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
                Text(String(localized: "确定要解除与 Mac 的配对吗？所有密钥将被删除。"))
            }
        }
    }
}
