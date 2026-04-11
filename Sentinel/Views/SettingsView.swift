import SwiftUI

/// Settings tab. Connection control (pairing, manual connect, mode switching)
/// lives in TerminalListView + AddTerminalSheet — this view is a read-only
/// dashboard plus links to rules / stats / trust manager.
struct SettingsView: View {
    @Environment(LocalDiscoveryService.self) private var local
    @Environment(RelayService.self) private var relay
    @Environment(ApprovalStore.self) private var store
    @Environment(TrustManager.self) private var trustManager

    var body: some View {
        NavigationStack {
            List {
                connectionSection

                notificationPermissionWarning

                Section {
                    NavigationLink {
                        RulesView()
                    } label: {
                        Label(String(localized: "规则管理"), systemImage: "slider.horizontal.3")
                    }
                }

                if !trustManager.activeTrusts.isEmpty {
                    trustSection
                }

                usageSection

                statisticsSection

                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "设置"))
        }
    }

    // MARK: - Sections

    private var connectionSection: some View {
        Section {
            LabeledContent(String(localized: "状态")) {
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

            if let host = local.discoveredHost {
                LabeledContent(String(localized: "当前 Mac")) {
                    Text(host)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            if let error = relay.connectionError {
                LabeledContent(String(localized: "错误")) {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.trailing)
                }
            }

            if relay.isConnected {
                Button(role: .destructive) {
                    relay.disconnect()
                } label: {
                    Label(String(localized: "断开连接"), systemImage: "wifi.slash")
                }
            }
        } header: {
            Text(String(localized: "连接"))
        } footer: {
            Text(String(localized: "连接由终端列表中的 profile 管理。在【终端】标签添加或切换连接。"))
        }
    }

    @ViewBuilder
    private var notificationPermissionWarning: some View {
        if NotificationService.shared.permissionChecked && !NotificationService.shared.isPermissionGranted {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "通知权限未开启"))
                            .font(.subheadline)
                        Text(String(localized: "审批请求将只在 App 内显示，后台时可能错过重要操作"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                Button(String(localized: "前往系统设置")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private var trustSection: some View {
        Section {
            ForEach(trustManager.activeTrusts) { entry in
                HStack(spacing: 12) {
                    Image(systemName: entry.isSessionOnly ? "infinity" : "clock.badge.checkmark")
                        .font(.body)
                        .foregroundStyle(.green)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.toolName)
                            .font(.subheadline.weight(.medium))
                        if let pattern = entry.pathPattern {
                            Text(pattern)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(entry.remainingText)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(entry.remainingSeconds < 60 && !entry.isSessionOnly ? .orange : .secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        withAnimation(Theme.springAnimation) { trustManager.revoke(id: entry.id) }
                    } label: {
                        Label(String(localized: "撤销"), systemImage: "xmark.circle")
                    }
                }
            }
            Button(role: .destructive) {
                withAnimation(Theme.springAnimation) { trustManager.revokeAll() }
            } label: {
                Label(String(localized: "撤销全部信任"), systemImage: "xmark.shield")
            }
        } header: {
            Label(String(localized: "临时信任"), systemImage: "clock.badge.checkmark")
        } footer: {
            Text(String(localized: "信任期内的工具请求将自动允许，无需手动审批"))
        }
    }

    private var usageSection: some View {
        Section {
            HStack {
                Label(String(localized: "今日调用"), systemImage: "chart.bar.fill")
                Spacer()
                Text(String(localized: "\(store.todayCallCount) 次"))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(String(localized: "重置时间"), systemImage: "clock.arrow.circlepath")
                Spacer()
                Text(nextMidnightText)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(String(localized: "当前模型"), systemImage: "cpu")
                Spacer()
                Text(store.currentModel.displayName)
                    .foregroundStyle(store.currentModel.color)
            }
        } header: {
            Text(String(localized: "使用情况"))
        }
    }

    private var statisticsSection: some View {
        Section(String(localized: "统计")) {
            NavigationLink {
                StatisticsView()
            } label: {
                HStack {
                    Label(String(localized: "统计仪表盘"), systemImage: "chart.bar")
                    Spacer()
                    Text("\(store.resolvedCount)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var aboutSection: some View {
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

    // MARK: - Computed

    private var nextMidnightText: String {
        let cal = Calendar.current
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: .now),
              let midnight = cal.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return "--"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: midnight, relativeTo: .now)
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(short) (\(build))"
    }
}
