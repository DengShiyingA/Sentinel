import Foundation

struct TerminalProfile: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var port: Int = 7750
    var useBonjour: Bool = true   // true = Bonjour auto-discovery, false = direct IP:port
    var host: String = ""          // used when useBonjour = false
    var lastPath: String?          // last known workspace path, shown in list
    var lastUsedAt: Date?          // for sorting most-recently-used first
    var createdAt: Date = Date()

    /// Cloudflare tunnel URL for remote access (e.g., "wss://xxx.trycloudflare.com"). Nil = LAN-only.
    var remoteUrl: String?

    /// Base64 X25519 public key / transport key shared at pairing time. Nil if not paired remotely.
    var remotePublicKey: String?

    var hasRemote: Bool { remoteUrl != nil }

    static let storageKey = "sentinel.terminalProfiles"

    static func load() -> [TerminalProfile] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profiles = try? JSONDecoder().decode([TerminalProfile].self, from: data),
              !profiles.isEmpty else {
            return [TerminalProfile(name: String(localized: "终端 1"))]
        }
        return profiles
    }

    static func save(_ profiles: [TerminalProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
