import LocalAuthentication

enum BiometricError: LocalizedError {
    case notAvailable
    case authFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable: String(localized: "生物识别不可用")
        case .authFailed(let msg): msg
        }
    }
}

enum BiometricService {
    /// Authenticate using Face ID / Touch ID.
    /// On Simulator (no biometrics), falls back to device passcode.
    static func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        // Try biometrics first
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !success { throw BiometricError.authFailed(String(localized: "认证失败")) }
            return
        }

        // Fallback: device passcode (works on Simulator)
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if !success { throw BiometricError.authFailed(String(localized: "认证失败")) }
            return
        }

        // No auth available (Simulator without passcode) — allow directly
        #if targetEnvironment(simulator)
        return  // Skip auth on Simulator
        #else
        throw BiometricError.notAvailable
        #endif
    }
}
