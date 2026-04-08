import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "RelayService")

/// Manages the active TransportProtocol. Handles mode switching at runtime
/// without requiring app restart.
@Observable
final class RelayService {
    private(set) var currentMode: ConnectionMode = ConnectionMode.current
    private(set) var transport: TransportProtocol?
    var isConnected: Bool { transport?.isConnected ?? false }

    private let socket: SocketClient
    private let local: LocalDiscoveryService
    private let pairing: PairingService

    /// Forwarded to ApprovalStore
    var onRequest: ((ApprovalRequest) -> Void)? {
        didSet { transport?.onRequest = onRequest }
    }

    init(socket: SocketClient, local: LocalDiscoveryService, pairing: PairingService) {
        self.socket = socket
        self.local = local
        self.pairing = pairing
    }

    /// Connect using the persisted mode
    func connectCurrentMode() {
        switchMode(ConnectionMode.current)
    }

    /// Switch to a new mode: disconnect old, connect new
    func switchMode(_ mode: ConnectionMode) {
        // Disconnect old
        transport?.disconnect()
        transport = nil
        currentMode = mode
        ConnectionMode.current = mode

        // Create new
        let newTransport = TransportFactory.makeTransport(
            mode: mode,
            socket: socket,
            local: local,
            pairing: pairing
        )
        newTransport.onRequest = onRequest
        transport = newTransport

        // Connect async with timeout — never block UI
        Task.detached { [weak self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await newTransport.connect() }
                    group.addTask {
                        try await Task.sleep(for: .seconds(10))
                        throw CancellationError()
                    }
                    // First to finish wins, cancel the other
                    try await group.next()
                    group.cancelAll()
                }
                log.info("Connected via \(mode.rawValue)")
            } catch {
                log.error("Connect failed (\(mode.rawValue)): \(error.localizedDescription)")
            }
        }
    }

    /// Send decision via active transport
    func sendDecision(requestId: String, decision: Decision) {
        guard let transport else {
            log.error("No transport — cannot send decision")
            return
        }
        Task {
            do {
                try await transport.sendDecision(requestId: requestId, decision: decision)
            } catch {
                log.error("sendDecision failed: \(error.localizedDescription)")
            }
        }
    }
}
