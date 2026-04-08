import SwiftUI

struct ContentView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(RelayService.self) private var relay

    var body: some View {
        // Always show MainTabView — pairing is handled inside SettingsView/PairingView
        // Never remove the tab hierarchy based on mode changes
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

            RulesView()
                .tabItem {
                    Label(String(localized: "规则"), systemImage: "list.bullet.rectangle")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "设置"), systemImage: "gearshape")
                }
        }
    }
}
