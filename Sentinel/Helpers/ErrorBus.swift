import Foundation
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "ErrorBus")

/// Centralized error bus for surfacing errors to the UI.
/// Services post errors here; views observe `currentError` to show alerts.
@Observable
final class ErrorBus {
    static let shared = ErrorBus()

    /// The most recent user-facing error. Views bind to this to show an alert.
    var currentError: AppError?

    /// Recent errors for debugging (bounded to last 50)
    private(set) var recentErrors: [AppError] = []

    private init() {}

    @MainActor
    func post(_ error: AppError) {
        log.error("[\(error.source)] \(error.message)")
        currentError = error
        recentErrors.insert(error, at: 0)
        if recentErrors.count > 50 { recentErrors.removeLast() }
    }

    @MainActor
    func post(_ message: String, source: String = "general", recovery: String? = nil) {
        post(AppError(message: message, source: source, recovery: recovery))
    }

    @MainActor
    func dismiss() {
        currentError = nil
    }
}

enum ErrorCode: String {
    case connectionTimeout = "connection_timeout"
    case connectionLost = "connection_lost"
    case transportOffline = "transport_offline"
    case sendFailed = "send_failed"
    case encryptionFailed = "encryption_failed"
    case authFailed = "auth_failed"
    case syncFailed = "sync_failed"
    case parseFailed = "parse_failed"
    case unknown = "unknown"
}

struct AppError: Identifiable {
    let id = UUID()
    let code: ErrorCode
    let message: String
    let source: String
    let recovery: String?
    let timestamp = Date()

    init(code: ErrorCode = .unknown, message: String, source: String = "general", recovery: String? = nil) {
        self.code = code
        self.message = message
        self.source = source
        self.recovery = recovery
    }
}
