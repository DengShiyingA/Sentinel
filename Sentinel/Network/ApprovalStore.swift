import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "ApprovalStore")

/// Central store for approval requests. Receives requests from RelayService,
/// manages pending queue, timeouts, and sends decisions back.
@Observable
final class ApprovalStore {
    var pendingRequests: [ApprovalRequest] = []
    var resolvedCount: Int = 0

    private let relay: RelayService
    private var timeoutTasks: [String: Task<Void, Never>] = [:]

    init(relay: RelayService) {
        self.relay = relay
        setupRelay()
    }

    private func setupRelay() {
        relay.onRequest = { [weak self] request in
            self?.handleIncomingRequest(request)
        }
    }

    private func handleIncomingRequest(_ request: ApprovalRequest) {
        Task { @MainActor in
            guard !self.pendingRequests.contains(where: { $0.id == request.id }) else { return }
            self.pendingRequests.insert(request, at: 0)
            log.info("New request: \(request.id) tool=\(request.toolName)")
        }
        scheduleTimeout(for: request)
    }

    // MARK: - Send Decision

    func sendDecision(requestId: String, decision: Decision) {
        timeoutTasks[requestId]?.cancel()
        timeoutTasks.removeValue(forKey: requestId)

        relay.sendDecision(requestId: requestId, decision: decision)

        Task { @MainActor in
            self.removeRequest(id: requestId)
            self.resolvedCount += 1
        }
        log.info("Decision: \(requestId) → \(decision.rawValue)")
    }

    // MARK: - Timeout

    private func scheduleTimeout(for request: ApprovalRequest) {
        let requestId = request.id
        let remaining = request.remainingSeconds

        guard remaining > 0 else {
            sendDecision(requestId: requestId, decision: .blocked)
            return
        }

        let task = Task {
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            let stillPending = await MainActor.run {
                self.pendingRequests.contains { $0.id == requestId }
            }
            if stillPending {
                log.info("Timeout: \(requestId)")
                self.sendDecision(requestId: requestId, decision: .blocked)
            }
        }
        timeoutTasks[requestId] = task
    }

    @MainActor
    private func removeRequest(id: String) {
        pendingRequests.removeAll { $0.id == id }
    }

    func request(for id: String) -> ApprovalRequest? {
        pendingRequests.first { $0.id == id }
    }
}
