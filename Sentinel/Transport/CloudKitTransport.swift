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
    private(set) var isConnected = false
    private var processedIds = Set<String>()

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

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollRequests()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func disconnect() {
        pollTask?.cancel()
        pollTask = nil
        isConnected = false
        database = nil
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

            for (_, result) in results {
                guard let record = try? result.get() else { continue }
                let recordId = record.recordID.recordName
                guard !processedIds.contains(recordId) else { continue }
                processedIds.insert(recordId)

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
                    timeoutAt: Date(timeIntervalSince1970: Double(timeoutAt) / 1000)
                )

                onRequest?(request)
            }
        } catch {
            log.debug("Poll error: \(error.localizedDescription)")
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
