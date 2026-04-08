import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "RelayService")

@Observable
final class RelayService {
    private(set) var currentMode: ConnectionMode
    private(set) var isConnected = false
    private(set) var connectionError: String?

    private var transport: TransportProtocol?
    private var connectTask: Task<Void, Never>?

    private let socket: SocketClient
    private let local: LocalDiscoveryService
    private let pairing: PairingService

    var onRequest: ((ApprovalRequest) -> Void)?

    init(socket: SocketClient, local: LocalDiscoveryService, pairing: PairingService) {
        self.socket = socket
        self.local = local
        self.pairing = pairing
        self.currentMode = ConnectionMode.current
    }

    func connectCurrentMode() {
        switchMode(currentMode)
    }

    func switchMode(_ mode: ConnectionMode) {
        // Cancel any pending connect
        connectTask?.cancel()

        // Tear down old
        transport?.onRequest = nil
        transport?.disconnect()
        transport = nil
        isConnected = false
        connectionError = nil

        // Update mode
        currentMode = mode
        ConnectionMode.current = mode

        // Create new transport
        let newTransport = TransportFactory.makeTransport(
            mode: mode,
            socket: socket,
            local: local,
            pairing: pairing
        )
        newTransport.onRequest = onRequest
        transport = newTransport

        // Connect async
        connectTask = Task { [weak self] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await newTransport.connect() }
                    group.addTask {
                        try await Task.sleep(for: .seconds(10))
                        throw CancellationError()
                    }
                    try await group.next()
                    group.cancelAll()
                }
                await MainActor.run { self?.isConnected = true }
                log.info("Connected via \(mode.rawValue)")
            } catch is CancellationError {
                log.warning("Connect timeout (\(mode.rawValue))")
                await MainActor.run { self?.connectionError = "连接超时" }
            } catch {
                log.error("Connect failed: \(error.localizedDescription)")
                await MainActor.run { self?.connectionError = error.localizedDescription }
            }
        }
    }

    func disconnect() {
        connectTask?.cancel()
        transport?.disconnect()
        isConnected = false
        connectionError = nil
        log.info("Disconnected")
    }

    func sendDecision(requestId: String, decision: Decision) {
        guard let transport else { return }
        Task {
            try? await transport.sendDecision(requestId: requestId, decision: decision)
        }
    }
}
