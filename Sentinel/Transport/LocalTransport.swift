import Foundation
import CryptoKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "LocalTransport")

final class LocalTransport: TransportProtocol {
    private let discovery: LocalDiscoveryService

    var onRequest: ((ApprovalRequest) -> Void)? { didSet { rebindListener() } }
    var onActivity: ((ActivityItem) -> Void)? { didSet { rebindListener() } }
    var onDecisionSync: ((String) -> Void)? { didSet { rebindListener() } }
    var onTerminal: ((String) -> Void)? { didSet { rebindListener() } }

    init(discovery: LocalDiscoveryService) {
        self.discovery = discovery
        rebindListener()
    }

    var isConnected: Bool { discovery.isConnected }

    func connect() async throws {
        await MainActor.run { discovery.startDiscovery() }
    }

    func disconnect() {
        discovery.disconnect()
        discovery.stopDiscovery()
    }

    func sendDecision(requestId: String, decision: Decision) async throws {
        discovery.emit("decision", dict: [
            "requestId": requestId,
            "action": decision.rawValue,
        ])
    }

    func sendRulesUpdate(rules: [[String: Any]]) async throws {
        discovery.emit("rules_update", dict: ["rules": rules])
    }

    /// Re-set discovery.onEvent every time a callback changes,
    /// so closures always reference the latest callbacks.
    private func rebindListener() {
        let onReq = onRequest
        let onAct = onActivity
        let onSync = onDecisionSync
        let onTerm = onTerminal

        discovery.onEvent = { event, data in
            switch event {
            case "handshake":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let version = dict["version"] as? String ?? "2"
                    if version == "3", let x25519PubB64 = dict["x25519PublicKey"] as? String,
                       let pubKeyData = Data(base64Encoded: x25519PubB64),
                       pubKeyData.count == 32 {
                        // V3: derive shared key via X25519 ECDH (no plaintext key exchange)
                        do {
                            let serverPubKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: pubKeyData)
                            let ephemeral = Curve25519.KeyAgreement.PrivateKey()
                            let shared = try ephemeral.sharedSecretFromKeyAgreement(with: serverPubKey)
                            let derivedKey = shared.hkdfDerivedSymmetricKey(
                                using: SHA256.self,
                                salt: Data("sentinel-transport-v2".utf8),
                                sharedInfo: Data(),
                                outputByteCount: 32
                            )
                            TransportEncryption.setDerivedKey(derivedKey)
                            log.info("Encryption key derived via X25519 ECDH (v3)")
                        } catch {
                            log.error("X25519 key agreement failed: \(error)")
                            // Fall back to v2 ek if available
                            if let ek = dict["ek"] as? String {
                                TransportEncryption.setKey(base64: ek)
                                log.info("Fell back to v2 plaintext key")
                            }
                        }
                    } else if let ek = dict["ek"] as? String {
                        // V2 fallback: plaintext key
                        TransportEncryption.setKey(base64: ek)
                        log.info("Encryption key received (v2 plaintext)")
                    }
                }

            case "approval_request":
                do {
                    let request = try JSONDecoder.sentinelDecoder.decode(ApprovalRequest.self, from: data)
                    log.info("Request: \(request.id) tool=\(request.toolName)")
                    onReq?(request)
                } catch {
                    log.error("Decode error: \(error)")
                    if let raw = String(data: data, encoding: .utf8) {
                        log.error("Raw: \(raw.prefix(200))")
                    }
                }

            case "notification":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let title = dict["title"] as? String ?? "Sentinel"
                    let message = dict["message"] as? String ?? ""
                    NotificationService.shared.postSimpleNotification(title: title, body: message)
                }

            case "terminal":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = dict["text"] as? String {
                    onTerm?(text)
                }

            case "activity":
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let typeStr = dict["type"] as? String ?? ""
                    let type = ActivityType(rawValue: typeStr) ?? .toolCompleted
                    let item = ActivityItem(
                        id: UUID().uuidString,
                        type: type,
                        summary: dict["summary"] as? String ?? dict["message"] as? String ?? dict["text"] as? String ?? typeStr,
                        toolName: dict["toolName"] as? String,
                        timestamp: Date(),
                        stopReason: dict["stopReason"] as? String,
                        message: dict["message"] as? String
                    )
                    onAct?(item)
                }

            default:
                break
            }
        }
    }
}
