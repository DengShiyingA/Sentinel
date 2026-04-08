import SwiftUI

struct ContentView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(RelayService.self) private var relay

    var body: some View {
        MainTabView()
    }
}

struct MainTabView: View {
    @Environment(ApprovalStore.self) private var store

    var body: some View {
        TabView {
            ApprovalListView()
                .tabItem {
                    Label(String(localized: "审批"), systemImage: "checkmark.shield")
                }
                .badge(store.pendingRequests.count)

            ActivityFeedView()
                .tabItem {
                    Label(String(localized: "活动"), systemImage: "list.bullet.rectangle")
                }
                .badge(store.newActivityCount > 0 ? store.newActivityCount : 0)

            RulesView()
                .tabItem {
                    Label(String(localized: "规则"), systemImage: "slider.horizontal.3")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "设置"), systemImage: "gearshape")
                }
        }
    }
}
