import Foundation
import UIKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "PairingService")

enum PairingError: LocalizedError {
    case invalidURL
    case invalidDeepLink
    case invalidSecret
    case networkError(String)
    case secretExpired
    case authFailed(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: String(localized: "无效的服务器地址")
        case .invalidDeepLink: String(localized: "无效的配对链接")
        case .invalidSecret: String(localized: "无效的配对密钥")
        case .networkError(let msg): String(localized: "网络错误: \(msg)")
        case .secretExpired: String(localized: "配对链接已过期")
        case .authFailed(let msg): String(localized: "认证失败: \(msg)")
        case .serverError(let msg): String(localized: "服务器错误: \(msg)")
        }
    }
}

@Observable
final class PairingService {
    // MARK: - Persisted State

    var serverURL: String {
        get { UserDefaults.standard.string(forKey: "sentinel.serverURL") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sentinel.serverURL") }
    }

    var macDeviceId: String {
        get { UserDefaults.standard.string(forKey: "sentinel.macDeviceId") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sentinel.macDeviceId") }
    }

    var jwtToken: String {
        get { KeychainHelper.loadString(key: "sentinel.jwtToken") ?? "" }
        set { try? KeychainHelper.saveString(key: "sentinel.jwtToken", value: newValue) }
    }

    var deviceId: String {
        get {
            if let existing = UserDefaults.standard.string(forKey: "sentinel.deviceId"), !existing.isEmpty {
                return existing
            }
            let newId = UUID().uuidString.lowercased()
            UserDefaults.standard.set(newId, forKey: "sentinel.deviceId")
            return newId
        }
    }

    var isPaired: Bool {
        !serverURL.isEmpty && !macDeviceId.isEmpty && !jwtToken.isEmpty
    }

    // MARK: - Parse Deep Link

    struct DeepLinkResult {
        let secret: Data
        let serverURL: String?  // Embedded in link since v2, e.g. sentinel://pair/<secret>?s=<url>
    }

    /// Parse sentinel://pair/<base64url_secret>?s=<serverURL> into secret + optional server URL
    static func parseDeepLink(_ link: String) throws -> DeepLinkResult {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed),
              url.scheme == "sentinel",
              url.host == "pair" else {
            throw PairingError.invalidDeepLink
        }

        // Path is "/<secret>" — drop leading "/"
        let base64url = String(url.path.dropFirst())
        guard !base64url.isEmpty else {
            throw PairingError.invalidDeepLink
        }

        // base64url → base64 → Data
        let base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .padding(toLength: ((base64url.count + 3) / 4) * 4, withPad: "=", startingAt: 0)

        guard let data = Data(base64Encoded: base64), data.count == 32 else {
            throw PairingError.invalidSecret
        }

        // Extract embedded server URL from ?s= query parameter
        let components = URLComponents(string: trimmed)
        let serverURL = components?.queryItems?.first(where: { $0.name == "s" })?.value

        return DeepLinkResult(secret: data, serverURL: serverURL)
    }

    // MARK: - Full Pair Flow

    /// Complete pairing from a deep link secret:
    /// 1. Initialize identity from seed (secret)
    /// 2. Authenticate with server (Ed25519 challenge-response → JWT)
    /// 3. POST /v1/pair/confirm with JWT + secret → establish Mac-iOS pairing
    func pair(serverURL: String, secret: Data) async throws {
        let baseURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let _ = URL(string: baseURL) else {
            throw PairingError.invalidURL
        }

        // 1. Initialize identity from seed
        try IdentityManager.shared.initializeFromSeed(secret)
        log.info("Identity initialized from pairing secret")

        // 2. Auth: challenge-response → JWT
        let token = try await authenticate(baseURL: baseURL)
        log.info("Authenticated with server")

        // 3. Confirm pairing
        let pairResult = try await confirmPairing(
            baseURL: baseURL,
            token: token,
            secret: secret
        )

        // 4. Persist
        self.serverURL = baseURL
        self.jwtToken = token
        self.macDeviceId = pairResult.pairedDeviceId

        if let macPubKey = pairResult.macPublicKey {
            do {
                try KeychainHelper.saveString(key: "sentinel.macPublicKey", value: macPubKey)
            } catch {
                log.error("Failed to save Mac public key to Keychain: \(error.localizedDescription)")
                ErrorBus.shared.post( String(localized: "无法保存 Mac 公钥到钥匙串"),
                                     recovery: String(localized: "请重新配对"))
            }
        }

        log.info("Paired with Mac device: \(pairResult.pairedDeviceId)")
    }

    // MARK: - Auth (POST /v1/auth)

    private func authenticate(baseURL: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/v1/auth") else {
            throw PairingError.invalidURL
        }

        let challenge = try IdentityManager.shared.authChallenge()
        let name = await MainActor.run { UIDevice.current.name }

        let body: [String: Any] = [
            "challenge": challenge.challenge,
            "publicKey": challenge.publicKey,
            "signature": challenge.signature,
            "deviceName": name,
            "deviceType": "ios",
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PairingError.networkError("Invalid response")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let respData = json["data"] as? [String: Any],
              let token = respData["token"] as? String else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if httpResponse.statusCode == 401 {
                throw PairingError.authFailed("Signature verification failed")
            }
            throw PairingError.serverError("Auth failed (HTTP \(status))")
        }

        // Update deviceId if server assigned one
        if let serverDeviceId = respData["deviceId"] as? String {
            UserDefaults.standard.set(serverDeviceId, forKey: "sentinel.deviceId")
        }

        return token
    }

    // MARK: - Confirm Pairing (POST /v1/pair/confirm)

    private struct PairResult {
        let pairedDeviceId: String
        let macPublicKey: String?
    }

    private func confirmPairing(
        baseURL: String,
        token: String,
        secret: Data
    ) async throws -> PairResult {
        guard let url = URL(string: "\(baseURL)/v1/pair/confirm") else {
            throw PairingError.invalidURL
        }

        // Encode secret as base64url (same format as deep link)
        let secretBase64Url = secret.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let body: [String: Any] = [
            "secret": secretBase64Url,
            "token": token,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PairingError.networkError("Invalid response")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PairingError.serverError("Invalid JSON")
        }

        if httpResponse.statusCode == 404 || httpResponse.statusCode == 410 {
            throw PairingError.secretExpired
        }

        guard let success = json["success"] as? Bool, success,
              let respData = json["data"] as? [String: Any],
              let pairedDeviceId = respData["pairedDeviceId"] as? String else {
            let msg = (json["error"] as? [String: Any])?["message"] as? String ?? "Unknown"
            throw PairingError.serverError(msg)
        }

        return PairResult(
            pairedDeviceId: pairedDeviceId,
            macPublicKey: respData["macPublicKey"] as? String
        )
    }

    // MARK: - Unpair

    func unpair() {
        UserDefaults.standard.removeObject(forKey: "sentinel.serverURL")
        UserDefaults.standard.removeObject(forKey: "sentinel.macDeviceId")
        KeychainHelper.delete(key: "sentinel.jwtToken")
        KeychainHelper.delete(key: "sentinel.macPublicKey")
        IdentityManager.shared.resetIdentity()
        log.info("Unpaired")
    }

    // MARK: - Helpers

}
