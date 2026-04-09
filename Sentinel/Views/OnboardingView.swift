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

    private var welcomePage: some View {
        onboardingPage(
            icon: "shield.checkered",
            iconColor: .blue,
            title: "Sentinel",
            subtitle: String(localized: "Claude Code 安全审批"),
            steps: [
                (icon: "hand.raised.fill", text: String(localized: "AI 执行危险操作前，手机确认")),
                (icon: "terminal", text: String(localized: "远程监控 Claude Code 实时输出")),
                (icon: "clock.badge.checkmark", text: String(localized: "智能规则，减少重复审批")),
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

            Text(String(localized: "在 Mac 终端执行以下命令"))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                codeBlock("git clone https://github.com/DengShiyingA/Sentinel.git")
                codeBlock("cd Sentinel && ./install.sh")
                codeBlock("sentinel install")
            }
            .padding(.horizontal, 24)

            Text(String(localized: "install.sh 会安装依赖并全局注册 sentinel 命令\nsentinel install 会注入 hook 到 Claude Code"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

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

            VStack(spacing: 16) {
                connectOption(
                    icon: "wifi",
                    color: .green,
                    title: String(localized: "局域网"),
                    desc: String(localized: "同一 WiFi 自动发现，零配置")
                )
                connectOption(
                    icon: "icloud",
                    color: .blue,
                    title: "CloudKit",
                    desc: String(localized: "通过 iCloud 同步，跨网络")
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

            codeBlock("sentinel start")

            Text(String(localized: "确保 Mac 和 iPhone 在同一 WiFi"))
                .font(.caption)
                .foregroundStyle(.tertiary)

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

    private func codeBlock(_ text: String) -> some View {
        Text(text)
            .font(.caption.monospaced())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: Theme.badgeRadius))
            .textSelection(.enabled)
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
