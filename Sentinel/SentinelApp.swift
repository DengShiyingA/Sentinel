// Simulator 测试：先在 Mac 运行 `sentinel start --mode local`
// 然后在 App 设置页选择"局域网"模式，点"手动连接"输入 localhost:7750

import SwiftUI

@main
struct SentinelApp: App {
    @State private var pairing: PairingService
    @State private var socket: SocketClient
    @State private var local: LocalDiscoveryService
    @State private var relay: RelayService
    @State private var store: ApprovalStore
    @State private var trustManager = TrustManager()

    init() {
        let p = PairingService()
        let s = SocketClient()
        let l = LocalDiscoveryService()
        let r = RelayService(socket: s, local: l, pairing: p)
        let a = ApprovalStore(relay: r)

        _pairing = State(initialValue: p)
        _socket = State(initialValue: s)
        _local = State(initialValue: l)
        _relay = State(initialValue: r)
        _store = State(initialValue: a)

        NotificationService.shared.setup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pairing)
                .environment(socket)
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
                }
        }
    }
}
