import Foundation
import CloudKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "CloudKitTransport")

/// CloudKit transport — uses iCloud private database for Mac ↔ iOS messaging.
///
/// - Mac writes ApprovalRequest records (via CloudKit Web Services)
/// - iOS subscribes to new records via CKQuerySubscription
/// - iOS writes Decision records
/// - Mac polls for Decision records
final class CloudKitTransport: TransportProtocol {
    private let database: CKDatabase
    private var subscription: CKQuerySubscription?
    private var pollTask: Task<Void, Never>?

    var onRequest: ((ApprovalRequest) -> Void)?
    private(set) var isConnected = false
    private var processedIds = Set<String>()

    init() {
        self.database = CKContainer(identifier: "iCloud.com.sentinel.app").privateCloudDatabase
    }

    func connect() async throws {
        // Verify account access — gracefully handle missing entitlement
        do {
            let status = try await CKContainer(identifier: "iCloud.com.sentinel.app").accountStatus()
            guard status == .available else {
                throw TransportError.iCloudUnavailable
            }
        } catch let error as TransportError {
            throw error
        } catch {
            log.error("CloudKit account check failed: \(error.localizedDescription)")
            throw TransportError.iCloudUnavailable
        }

        // Subscribe (best-effort, don't block if it fails)
        Task { await self.setupSubscription() }

        // Start polling as fallback
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollRequests()
                try? await Task.sleep(for: .seconds(2))
            }
        }

        isConnected = true
        log.info("CloudKit transport connected")
    }

    func disconnect() {
        pollTask?.cancel()
        pollTask = nil
        isConnected = false
        log.info("CloudKit transport disconnected")
    }

    func sendDecision(requestId: String, decision: Decision) async throws {
        let record = CKRecord(recordType: "Decision")
        record["requestId"] = requestId as CKRecordValue
        record["action"] = (decision == .allowed ? "allow" : "block") as CKRecordValue
        record["status"] = "new" as CKRecordValue
        record["timestamp"] = Date() as CKRecordValue

        try await database.save(record)
        log.info("Decision saved to CloudKit: \(requestId) → \(decision.rawValue)")
    }

    // MARK: - Subscription

    private func setupSubscription() async {
        let predicate = NSPredicate(format: "status == %@", "pending")
        let subscription = CKQuerySubscription(
            recordType: "ApprovalRequest",
            predicate: predicate,
            options: [.firesOnRecordCreation]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        do {
            try await database.save(subscription)
            self.subscription = subscription
            log.info("CloudKit subscription created")
        } catch {
            log.error("Failed to create subscription: \(error.localizedDescription)")
        }
    }

    // MARK: - Polling

    private func pollRequests() async {
        let predicate = NSPredicate(format: "status == %@", "pending")
        let query = CKQuery(recordType: "ApprovalRequest", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 20)

            for (_, result) in results {
                guard let record = try? result.get() else { continue }
                let recordId = record.recordID.recordName

                guard !processedIds.contains(recordId) else { continue }
                processedIds.add(recordId)

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

                let riskLevel = riskLevelRaw == "high" ? RiskLevel.requireFaceID : .requireConfirm

                let request = ApprovalRequest(
                    id: requestId,
                    toolName: toolName,
                    toolInput: toolInput,
                    riskLevel: riskLevel,
                    timestamp: Date(timeIntervalSince1970: Double(timestamp) / 1000),
                    macDeviceId: "cloudkit",
                    timeoutAt: Date(timeIntervalSince1970: Double(timeoutAt) / 1000)
                )

                onRequest?(request)
                log.info("CloudKit request: \(requestId) tool=\(toolName)")
            }
        } catch {
            log.debug("CloudKit poll error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helpers

private extension Set where Element == String {
    mutating func add(_ member: String) {
        insert(member)
        // Keep set bounded
        if count > 500 {
            let excess = count - 200
            for id in prefix(excess) { remove(id) }
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
