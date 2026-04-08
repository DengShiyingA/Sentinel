import SwiftUI

struct ContentView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(RelayService.self) private var relay

    @State private var onboarded = UserDefaults.standard.bool(forKey: "sentinel.onboarded")

    var body: some View {
        if !onboarded {
            OnboardingView(isComplete: $onboarded)
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @Environment(ApprovalStore.self) private var store

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label(String(localized: "审批"), systemImage: "checkmark.shield")
                }
                .badge(store.pendingRequests.count)

            ActivityFeedView()
                .tabItem {
                    Label(String(localized: "消息"), systemImage: "bubble.left.and.bubble.right")
                }
                .badge(store.newActivityCount > 0 ? store.newActivityCount : 0)

            SettingsView()
                .tabItem {
                    Label(String(localized: "设置"), systemImage: "gearshape")
                }
        }
    }
}
