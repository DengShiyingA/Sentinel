import Foundation

enum TransportFactory {
    static func makeTransport(
        mode: ConnectionMode,
        socket: SocketClient,
        local: LocalDiscoveryService,
        pairing: PairingService
    ) -> TransportProtocol {
        switch mode {
        case .local:
            return LocalTransport(discovery: local)
        case .cloudkit:
            return CloudKitTransport()
        }
    }
}
