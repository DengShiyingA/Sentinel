import Foundation

enum TransportFactory {
    static func makeTransport(
        mode: ConnectionMode,
        local: LocalDiscoveryService
    ) -> TransportProtocol {
        switch mode {
        case .local:
            return LocalTransport(discovery: local)
        case .cloudkit:
            return CloudKitTransport()
        }
    }
}
