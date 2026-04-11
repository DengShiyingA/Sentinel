import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            installPage.tag(1)
            connectPage.tag(2)
            readyPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Pages

    private var welcomePage: some View {
        onboardingPage(
            icon: "shield.checkered",
            iconColor: .blue,
            title: "Sentinel",
            subtitle: String(localized: "Claude Code 安全审批"),
            steps: [
                (icon: "hand.raised.fill", text: String(localized: "AI 执行危险操作前，手机确认")),
                (icon: "pencil", text: String(localized: "允许时可编辑工具参数")),
                (icon: "clock.badge.checkmark", text: String(localized: "智能规则学习，减少重复审批")),
                (icon: "globe", text: String(localized: "LAN 或远程 Cloudflare Tunnel")),
            ]
        )
    }

    private var installPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "laptopcomputer.and.arrow.down")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text(String(localized: "安装 CLI"))
                .font(.title.bold())

            Text(String(localized: "在 Mac 终端运行"))
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                CopyableCommandRow(
                    label: String(localized: "1. 通过 npm 安装"),
                    command: "npm install -g @two7722/sentinel-guard"
                )
                CopyableCommandRow(
                    label: String(localized: "2. 注入 Claude Code hook"),
                    command: "sentinel install"
                )
            }
            .padding(.horizontal, 24)

            Text(String(localized: "需要 Node 20+。hook 注入是一次性的。"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
    }

    private var connectPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wifi")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(String(localized: "连接方式"))
                .font(.title.bold())

            VStack(spacing: 12) {
                connectOption(
                    icon: "wifi",
                    color: .green,
                    title: String(localized: "局域网（默认）"),
                    desc: String(localized: "Bonjour 自动发现，同 WiFi 即插即用")
                )
                connectOption(
                    icon: "network",
                    color: .purple,
                    title: String(localized: "手动 IP"),
                    desc: String(localized: "Bonjour 不可用时（跨子网）指定 Mac 主机")
                )
                connectOption(
                    icon: "globe",
                    color: .blue,
                    title: String(localized: "远程 Cloudflare Tunnel"),
                    desc: String(localized: "出门在外，扫码后自动 fallback 到 wss")
                )
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue)
                .symbolEffect(.bounce)

            Text(String(localized: "准备开始"))
                .font(.title.bold())

            Text(String(localized: "在 Mac 终端运行"))
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                CopyableCommandRow(
                    label: String(localized: "本地工作"),
                    command: "sentinel run"
                )
                CopyableCommandRow(
                    label: String(localized: "远程访问（出门用）"),
                    command: "sentinel run --remote"
                )
            }
            .padding(.horizontal, 24)

            Text(String(localized: "接下来在【终端】标签添加一个终端。局域网自动发现，无需扫码。"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                UserDefaults.standard.set(true, forKey: "sentinel.onboarded")
                withAnimation(Theme.springAnimation) { isComplete = true }
            } label: {
                Text(String(localized: "开始使用"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func onboardingPage(icon: String, iconColor: Color, title: String, subtitle: String, steps: [(icon: String, text: String)]) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title.bold())

            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(spacing: 12) {
                        Image(systemName: steps[i].icon)
                            .font(.body)
                            .foregroundStyle(iconColor)
                            .frame(width: 28)
                        Text(steps[i].text)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    private func connectOption(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(color.opacity(Theme.cardFillOpacity), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}
