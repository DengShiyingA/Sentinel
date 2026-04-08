import SwiftUI

struct ContentView: View {
    @Environment(PairingService.self) private var pairing
    @Environment(RelayService.self) private var relay

    var body: some View {
        // Local/CloudKit: always show main UI (no pairing needed)
        // Server: require pairing first
        if ConnectionMode.current != .server || pairing.isPaired {
            MainTabView()
        } else {
            PairingView()
        }
    }
}

struct MainTabView: View {
    @Environment(ApprovalStore.self) private var store

    var body: some View {
        TabView {
            Tab(String(localized: "审批"), systemImage: "checkmark.shield") {
                ApprovalListView()
            }
            .badge(store.pendingRequests.count)

            Tab(String(localized: "规则"), systemImage: "list.bullet.rectangle") {
                RulesView()
            }

            Tab(String(localized: "设置"), systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
