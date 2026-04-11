import Foundation

/// Centralized configuration constants shared across the app.
/// Keeps timeout values, limits, and defaults in one place.
enum SentinelConfig {
    /// How long an approval request stays alive before expiring (seconds)
    static let approvalTimeoutSeconds: TimeInterval = 120

    /// How long to wait when connecting to a transport before giving up (seconds)
    static let connectTimeoutSeconds: TimeInterval = 10

    /// Maximum number of terminal lines kept in memory
    static let maxTerminalLines = 500

    /// Maximum number of activity feed items kept in memory
    static let maxActivityItems = 50

    /// Maximum reconnect attempts before giving up
    static let maxReconnectAttempts = 10

    /// Maximum TCP buffer size (bytes) before dropping connection
    static let maxBufferSize = 1_048_576 // 1 MB

    /// Maximum number of decision history records kept in memory
    static let maxHistoryItems = 500

    /// Maximum number of user-typed messages kept in the active session timeline
    static let maxUserMessages = 100

    /// Maximum number of session summaries kept in the active session timeline
    static let maxSessionSummaries = 50
}
