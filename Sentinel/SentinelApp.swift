import SwiftUI

@main
struct SentinelApp: App {
    @State private var pairing = PairingService()
    @State private var socket = SocketClient()
    @State private var local = LocalDiscoveryService()
    @State private var relay: RelayService
    @State private var store: ApprovalStore

    init() {
        let socketClient = SocketClient()
        let localService = LocalDiscoveryService()
        let pairingService = PairingService()

        let relayService = RelayService(
            socket: socketClient,
            local: localService,
            pairing: pairingService
        )
        let approvalStore = ApprovalStore(relay: relayService)

        _socket = State(initialValue: socketClient)
        _local = State(initialValue: localService)
        _pairing = State(initialValue: pairingService)
        _relay = State(initialValue: relayService)
        _store = State(initialValue: approvalStore)

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
                    relay.connectCurrentMode()
                    setupNotificationActions()
                }
                .onOpenURL { url in
                    guard url.scheme == "sentinel", url.host == "pair" else { return }
                }
        }
    }

    private func setupNotificationActions() {
        NotificationService.shared.onNotificationAction = { [store] requestId, decision in
            store.sendDecision(requestId: requestId, decision: decision)
        }
    }
}
