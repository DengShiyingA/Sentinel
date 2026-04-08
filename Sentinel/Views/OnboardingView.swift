import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool

    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1
            onboardingPage(
                icon: "shield.checkered",
                iconColor: .blue,
                title: String(localized: "Sentinel"),
                subtitle: String(localized: "Claude Code 的 iOS 审批引擎"),
                description: String(localized: "让 AI 执行危险操作前\n必须经过你的手机确认")
            ).tag(0)

            // Page 2
            onboardingPage(
                icon: "wifi",
                iconColor: .green,
                title: String(localized: "三种连接模式"),
                subtitle: String(localized: "局域网 · CloudKit · 自建服务器"),
                description: String(localized: "局域网模式零配置\n同一 WiFi 自动发现 Mac")
            ).tag(1)

            // Page 3
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

                Text("sentinel start")
                    .font(.title3.monospaced())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                Spacer()

                Button {
                    UserDefaults.standard.set(true, forKey: "sentinel.onboarded")
                    withAnimation { isComplete = true }
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
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func onboardingPage(icon: String, iconColor: Color, title: String, subtitle: String, description: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.title.bold())

            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
