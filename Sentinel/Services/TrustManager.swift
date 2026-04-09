import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "TrustManager")

@MainActor
@Observable
final class TrustManager {
    struct TrustEntry: Identifiable {
        let id = UUID()
        let toolName: String
        let pathPattern: String?
        let expiresAt: Date?
        let createdAt = Date()

        var isSessionOnly: Bool { expiresAt == nil }

        var isExpired: Bool {
            guard let expiresAt else { return false }
            return Date() >= expiresAt
        }

        var remainingSeconds: TimeInterval {
            guard let expiresAt else { return .infinity }
            return max(0, expiresAt.timeIntervalSinceNow)
        }

        var remainingText: String {
            guard let expiresAt else { return String(localized: "本次会话") }
            let secs = Int(max(0, expiresAt.timeIntervalSinceNow))
            let mins = secs / 60
            return mins > 0 ? "\(mins)m \(secs % 60)s" : "\(secs)s"
        }

        var displayLabel: String {
            if let pattern = pathPattern {
                return "\(toolName) · \(pattern)"
            }
            return toolName
        }

        func matches(toolName: String, path: String?) -> Bool {
            guard self.toolName == toolName else { return false }
            guard let pattern = pathPattern else { return true }
            guard let path else { return false }
            return matchGlob(pattern: pattern, path: path)
        }
    }

    enum Duration: CaseIterable {
        case fiveMinutes, fifteenMinutes, thirtyMinutes, oneHour, session

        var label: String {
            switch self {
            case .fiveMinutes: "5 min"
            case .fifteenMinutes: "15 min"
            case .thirtyMinutes: "30 min"
            case .oneHour: "1 hour"
            case .session: String(localized: "本次会话")
            }
        }

        var expiresAt: Date? {
            switch self {
            case .fiveMinutes: Date().addingTimeInterval(300)
            case .fifteenMinutes: Date().addingTimeInterval(900)
            case .thirtyMinutes: Date().addingTimeInterval(1800)
            case .oneHour: Date().addingTimeInterval(3600)
            case .session: nil
            }
        }
    }

    private(set) var activeTrusts: [TrustEntry] = []

    private static let highRiskPatterns = [".env", "secrets", ".secret", "credentials", ".pem", ".key"]

    static func isHighRisk(path: String?) -> Bool {
        guard let path = path?.lowercased() else { return false }
        return highRiskPatterns.contains { path.contains($0) }
    }

    static func suggestPathPattern(from path: String?) -> String? {
        guard let path else { return nil }
        let nsPath = path as NSString
        let dir = nsPath.deletingLastPathComponent
        let ext = nsPath.pathExtension
        guard !dir.isEmpty else { return nil }
        if !ext.isEmpty {
            return "\(dir)/*.\(ext)"
        }
        return "\(dir)/*"
    }

    func trust(toolName: String, pathPattern: String? = nil, duration: Duration) {
        activeTrusts.removeAll { $0.toolName == toolName && $0.pathPattern == pathPattern }
        let entry = TrustEntry(
            toolName: toolName,
            pathPattern: pathPattern,
            expiresAt: duration.expiresAt
        )
        activeTrusts.append(entry)
        log.info("Trusted \(entry.displayLabel) for \(duration.label)")
    }

    func isTrusted(toolName: String, path: String? = nil) -> Bool {
        cleanExpired()
        if TrustManager.isHighRisk(path: path) { return false }
        return activeTrusts.contains { $0.matches(toolName: toolName, path: path) }
    }

    func revoke(id: UUID) {
        if let entry = activeTrusts.first(where: { $0.id == id }) {
            log.info("Revoked trust: \(entry.displayLabel)")
        }
        activeTrusts.removeAll { $0.id == id }
    }

    func revokeAll() {
        activeTrusts.removeAll()
        log.info("All trusts revoked")
    }

    private func cleanExpired() {
        let before = activeTrusts.count
        activeTrusts.removeAll { $0.isExpired }
        let removed = before - activeTrusts.count
        if removed > 0 {
            log.info("Cleaned \(removed) expired trust entries")
        }
    }
}

private func matchGlob(pattern: String, path: String) -> Bool {
    if pattern.hasSuffix("/**") {
        let prefix = String(pattern.dropLast(3))
        return path.hasPrefix(prefix)
    }
    if pattern.contains("*") {
        let parts = pattern.split(separator: "*", maxSplits: 1, omittingEmptySubsequences: false)
        let prefix = String(parts.first ?? "")
        let suffix = parts.count > 1 ? String(parts[1]) : ""
        let pathDir = (path as NSString).deletingLastPathComponent + "/"
        let prefixDir = prefix.hasSuffix("/") ? prefix : (prefix as NSString).deletingLastPathComponent + "/"
        if !pathDir.hasPrefix(prefixDir) { return false }
        if !suffix.isEmpty { return path.hasSuffix(suffix) }
        return true
    }
    return path == pattern
}
