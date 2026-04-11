// Simulator 测试：先在 Mac 运行 `sentinel start`
// 然后在【终端】标签点 + 添加一个终端并进入（自动 Bonjour 发现）

import SwiftUI

@main
struct SentinelApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var pairing: PairingService
    @State private var local: LocalDiscoveryService
    @State private var relay: RelayService
    @State private var store: ApprovalStore
    @State private var trustManager = TrustManager()

    init() {
        let p = PairingService()
        let l = LocalDiscoveryService()
        let r = RelayService(local: l)
        let a = ApprovalStore(relay: r)

        _pairing = State(initialValue: p)
        _local = State(initialValue: l)
        _relay = State(initialValue: r)
        _store = State(initialValue: a)

        NotificationService.shared.setup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pairing)
                .environment(local)
                .environment(relay)
                .environment(store)
                .environment(trustManager)
                .onAppear {
                    store.trustManager = trustManager
                    // Connection is now lazy — triggered when user taps into a terminal
                    NotificationService.shared.onNotificationAction = { [weak store] id, decision in
                        store?.sendDecision(requestId: id, decision: decision)
                    }

                    // Drain any decisions queued by Live Activity intents while the app
                    // was backgrounded, and install a cross-process observer so future
                    // taps from the lock screen wake the main app to dispatch them.
                    store.drainPendingLiveActivityDecisions()
                    LiveActivityDecisionObserver.install(store: store)

                    // Refresh notification permission status so the UI reflects
                    // any changes the user made in Settings while the app was closed.
                    NotificationService.shared.refreshPermissionStatus()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Drain any decisions queued while we were backgrounded.
                        // The Darwin observer usually handles this in real time
                        // but we run this belt-and-braces pass on every foreground
                        // transition in case the OS suspended the notifyd delivery.
                        store.drainPendingLiveActivityDecisions()
                        NotificationService.shared.refreshPermissionStatus()
                    }
                }
        }
    }
}
