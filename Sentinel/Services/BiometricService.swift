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
    static func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !success {
                throw BiometricError.authFailed(String(localized: "认证失败"))
            }
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel:
                throw BiometricError.authFailed(String(localized: "用户取消"))
            case .userFallback:
                throw BiometricError.authFailed(String(localized: "用户选择了密码"))
            default:
                throw BiometricError.authFailed(authError.localizedDescription)
            }
        }
    }
}
