import Foundation
import CloudKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "CloudKitTransport")

final class CloudKitTransport: TransportProtocol {
    // Lazy — don't access CKContainer until connect() is called
    private var database: CKDatabase?
    private var pollTask: Task<Void, Never>?

    var onRequest: ((ApprovalRequest) -> Void)?
    var onActivity: ((ActivityItem) -> Void)?
    var onDecisionSync: ((String) -> Void)?
    var onTerminal: ((String) -> Void)?
    var onWorkspaceInfo: ((_ cwd: String, _ hostname: String?) -> Void)?
    var onModel: ((String) -> Void)?
    var onBrowseResult: ((BrowseResult) -> Void)?  // not supported in CloudKit mode
    private(set) var isConnected = false
    /// Bounded cache of processed request IDs to prevent unbounded memory growth.
    /// Stores the most recent 500 IDs using FIFO eviction.
    private var processedIds = Set<String>()
    private var processedOrder: [String] = []
    private static let maxProcessedIds = 500
    /// Consecutive error count — used to back off polling frequency
    private var consecutiveErrors = 0

    func connect() async throws {
        let container = CKContainer(identifier: "iCloud.com.sentinel.app")

        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                throw TransportError.iCloudUnavailable
            }
        } catch is TransportError {
            throw TransportError.iCloudUnavailable
        } catch {
            log.error("CloudKit check failed: \(error.localizedDescription)")
            throw TransportError.iCloudUnavailable
        }

        database = container.privateCloudDatabase
        isConnected = true
        log.info("CloudKit connected")

        // Note: CloudKit mode only supports approval requests and decisions.
        // Activity feed and terminal output require real-time transport (Local/Server)
        // and are not available in CloudKit polling mode.
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollRequests()
                await self?.pollDecisionSync()
                let errors = self?.consecutiveErrors ?? 0
                let interval = errors > 0 ? min(Double(2 << min(errors, 5)), 60.0) : 3.0
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func disconnect() {
        pollTask?.cancel()
        pollTask = nil
        isConnected = false
        database = nil
        processedIds.removeAll()
        processedOrder.removeAll()
    }

    func sendRulesUpdate(rules: [[String: Any]]) async throws {
        // CloudKit mode: rules sync not supported yet — local persistence only
        log.info("Rules sync not supported in CloudKit mode")
    }

    func sendDecision(requestId: String, decision: Decision) async throws {
        guard let database else { throw TransportError.iCloudUnavailable }

        let record = CKRecord(recordType: "Decision")
        record["requestId"] = requestId as CKRecordValue
        record["action"] = (decision == .allowed ? "allow" : "block") as CKRecordValue
        record["status"] = "new" as CKRecordValue
        record["timestamp"] = Date() as CKRecordValue

        try await database.save(record)
    }

    private func pollRequests() async {
        guard let database else { return }

        let predicate = NSPredicate(format: "status == %@", "pending")
        let query = CKQuery(recordType: "ApprovalRequest", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 20)

            self.consecutiveErrors = 0
            for (_, result) in results {
                guard let record = try? result.get() else { continue }
                let recordId = record.recordID.recordName
                guard !processedIds.contains(recordId) else { continue }
                processedIds.insert(recordId)
                processedOrder.append(recordId)
                // Evict oldest entries when cache exceeds limit
                while processedIds.count > Self.maxProcessedIds, let oldest = processedOrder.first {
                    processedOrder.removeFirst()
                    processedIds.remove(oldest)
                }

                guard let requestId = record["requestId"] as? String,
                      let toolName = record["toolName"] as? String,
                      let toolInputJSON = record["toolInput"] as? String,
                      let riskLevelRaw = record["riskLevel"] as? String,
                      let timestamp = record["timestamp"] as? Int,
                      let timeoutAt = record["timeoutAt"] as? Int else {
                    continue
                }

                let toolInput: [String: AnyCodable]
                if let data = toolInputJSON.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    toolInput = dict.mapValues { AnyCodable($0) }
                } else {
                    toolInput = [:]
                }

                let request = ApprovalRequest(
                    id: requestId,
                    toolName: toolName,
                    toolInput: toolInput,
                    riskLevel: riskLevelRaw == "high" ? .requireFaceID : .requireConfirm,
                    timestamp: Date(timeIntervalSince1970: Double(timestamp) / 1000),
                    macDeviceId: "cloudkit",
                    timeoutAt: Date(timeIntervalSince1970: Double(timeoutAt) / 1000),
                    diff: nil,
                    contextSummary: nil
                )

                onRequest?(request)
            }
        } catch {
            self.consecutiveErrors += 1
            log.error("Poll error (\(self.consecutiveErrors)x): \(error.localizedDescription)")
            // Only show UI error on first failure to avoid spamming
            if self.consecutiveErrors == 1 {
                await MainActor.run {
                    ErrorBus.shared.post("iCloud 同步失败：\(error.localizedDescription)", source: "cloudkit", recovery: "请检查网络连接和 iCloud 登录状态")
                }
            }
        }
    }

    /// Poll for decisions made by other devices (multi-device sync via CloudKit)
    private func pollDecisionSync() async {
        guard let database else { return }

        let predicate = NSPredicate(format: "status == %@", "new")
        let query = CKQuery(recordType: "Decision", predicate: predicate)

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 20)
            for (_, result) in results {
                guard let record = try? result.get() else { continue }
                let recordId = record.recordID.recordName
                guard !processedIds.contains(recordId) else { continue }
                processedIds.insert(recordId)
                processedOrder.append(recordId)
                while processedIds.count > Self.maxProcessedIds, let oldest = processedOrder.first {
                    processedOrder.removeFirst()
                    processedIds.remove(oldest)
                }

                if let requestId = record["requestId"] as? String {
                    onDecisionSync?(requestId)
                }
            }
        } catch {
            // Decision sync errors are non-critical — just log
            log.debug("Decision sync poll error: \(error.localizedDescription)")
        }
    }
}

enum TransportError: LocalizedError {
    case iCloudUnavailable

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable: String(localized: "iCloud 不可用，请检查登录状态")
        }
    }
}
