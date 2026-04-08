import Foundation

enum ConnectionMode: String, CaseIterable, Identifiable, Codable {
    case local    = "local"
    case cloudkit = "cloudkit"
    case server   = "server"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .local:    String(localized: "局域网")
        case .cloudkit: String(localized: "CloudKit")
        case .server:   String(localized: "自建服务器")
        }
    }

    var description: String {
        switch self {
        case .local:    String(localized: "直连 Mac，无需服务器")
        case .cloudkit: String(localized: "通过 iCloud 同步，需同一 Apple ID")
        case .server:   String(localized: "通过自建服务器中继")
        }
    }

    var systemImage: String {
        switch self {
        case .local:    "wifi"
        case .cloudkit: "icloud"
        case .server:   "globe"
        }
    }

    static var current: ConnectionMode {
        get {
            let raw = UserDefaults.standard.string(forKey: "sentinel.connectionMode") ?? "local"
            return ConnectionMode(rawValue: raw) ?? .local
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "sentinel.connectionMode")
        }
    }
}
