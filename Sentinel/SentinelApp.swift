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
                .onAppear {
                    // Delay slightly to let SwiftUI finish layout first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        relay.connectCurrentMode()
                    }
                    NotificationService.shared.onNotificationAction = { [store] id, decision in
                        store.sendDecision(requestId: id, decision: decision)
                    }
                }
        }
    }
}
