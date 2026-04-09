import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "TrustManager")

/// Manages temporary tool trust — "trust Write for 15 min" style auto-approvals.
/// When a tool is trusted, incoming approval requests for that tool are auto-allowed
/// without user interaction until the trust expires.
@MainActor
@Observable
final class TrustManager {
    struct TrustEntry: Identifiable {
        let id = UUID()
        let toolName: String
        let expiresAt: Date
        let createdAt = Date()

        var isExpired: Bool { Date() >= expiresAt }
        var remainingSeconds: TimeInterval { max(0, expiresAt.timeIntervalSinceNow) }
        var remainingText: String {
            let mins = Int(remainingSeconds) / 60
            let secs = Int(remainingSeconds) % 60
            return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
        }
    }

    /// Active trust entries (auto-cleaned on access)
    private(set) var activeTrusts: [TrustEntry] = []

    /// Available trust durations shown in the UI
    static let durations: [(label: String, minutes: Int)] = [
        ("5 min", 5),
        ("15 min", 15),
        ("30 min", 30),
        ("1 hour", 60),
    ]

    /// Trust a tool for a given number of minutes
    func trust(toolName: String, minutes: Int) {
        // Remove any existing trust for same tool
        activeTrusts.removeAll { $0.toolName == toolName }
        let entry = TrustEntry(
            toolName: toolName,
            expiresAt: Date().addingTimeInterval(TimeInterval(minutes * 60))
        )
        activeTrusts.append(entry)
        log.info("Trusted \(toolName) for \(minutes) minutes")
    }

    /// Check if a tool is currently trusted (and auto-clean expired entries)
    func isTrusted(toolName: String) -> Bool {
        cleanExpired()
        return activeTrusts.contains { $0.toolName == toolName }
    }

    /// Revoke trust for a specific tool
    func revoke(toolName: String) {
        activeTrusts.removeAll { $0.toolName == toolName }
        log.info("Revoked trust for \(toolName)")
    }

    /// Revoke all trusts
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
