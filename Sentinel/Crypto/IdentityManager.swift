import Foundation
import CryptoKit

enum CryptoError: LocalizedError {
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
    case invalidPublicKey
    case signatureFailed
    case invalidSeed

    var errorDescription: String? {
        switch self {
        case .keyNotFound: "Identity key not found in Keychain"
        case .encryptionFailed: "Encryption failed"
        case .decryptionFailed: "Decryption failed"
        case .invalidPublicKey: "Invalid public key"
        case .signatureFailed: "Signature generation failed"
        case .invalidSeed: "Invalid seed (must be 32 bytes)"
        }
    }
}

/// Manages the device's identity key pairs, stored in Keychain.
///
/// Key derivation from seed (matches CLI's tweetnacl behavior):
/// - Ed25519 signing key: `Curve25519.Signing.PrivateKey(rawRepresentation: seed)`
/// - X25519 key agreement: `Curve25519.KeyAgreement.PrivateKey(rawRepresentation: seed)`
///
/// During pairing, the seed comes from the QR code's secret.
/// This ensures Mac and iOS derive the same identity from the shared secret.
final class IdentityManager {
    static let shared = IdentityManager()

    private let seedTag = "sentinel.identity.seed"
    private let x25519KeyTag = "sentinel.identity.x25519"
    private let ed25519KeyTag = "sentinel.identity.ed25519"

    private var _x25519Private: Curve25519.KeyAgreement.PrivateKey?
    private var _ed25519Private: Curve25519.Signing.PrivateKey?

    private init() {
        loadFromKeychain()
    }

    // MARK: - Seed-based Initialization

    /// Initialize identity from an external seed (32 bytes from pairing secret).
    /// Derives both Ed25519 (signing) and X25519 (key agreement) keys from the seed,
    /// then persists to Keychain.
    func initializeFromSeed(_ seed: Data) throws {
        guard seed.count == 32 else {
            throw CryptoError.invalidSeed
        }

        let ed25519Key = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
        let x25519Key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: seed)

        // Persist all three: seed, ed25519, x25519
        try KeychainHelper.save(key: seedTag, data: seed)
        try KeychainHelper.save(key: ed25519KeyTag, data: ed25519Key.rawRepresentation)
        try KeychainHelper.save(key: x25519KeyTag, data: x25519Key.rawRepresentation)

        _ed25519Private = ed25519Key
        _x25519Private = x25519Key
    }

    /// Whether identity keys have been initialized (via seed or prior pairing)
    var isInitialized: Bool {
        _ed25519Private != nil && _x25519Private != nil
    }

    // MARK: - Load from Keychain

    private func loadFromKeychain() {
        if let raw = try? KeychainHelper.load(key: ed25519KeyTag) {
            _ed25519Private = try? Curve25519.Signing.PrivateKey(rawRepresentation: raw)
        }
        if let raw = try? KeychainHelper.load(key: x25519KeyTag) {
            _x25519Private = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: raw)
        }
    }

    private func requireX25519() throws -> Curve25519.KeyAgreement.PrivateKey {
        guard let key = _x25519Private else { throw CryptoError.keyNotFound }
        return key
    }

    private func requireEd25519() throws -> Curve25519.Signing.PrivateKey {
        guard let key = _ed25519Private else { throw CryptoError.keyNotFound }
        return key
    }

    // MARK: - Public Keys

    /// Ed25519 signing public key as base64 (used for auth challenge-response)
    func publicKeyBase64() throws -> String {
        try requireEd25519().publicKey.rawRepresentation.base64EncodedString()
    }

    /// X25519 key agreement public key as base64
    func x25519PublicKeyBase64() throws -> String {
        try requireX25519().publicKey.rawRepresentation.base64EncodedString()
    }

    // MARK: - Auth Challenge (matches CLI's authChallenge())

    struct AuthChallenge {
        let challenge: String   // base64
        let publicKey: String   // base64
        let signature: String   // base64
    }

    /// Generate auth challenge: random 32 bytes, sign with Ed25519, return all base64.
    /// Server verifies with `nacl.sign.detached.verify(challenge, signature, publicKey)`.
    func authChallenge() throws -> AuthChallenge {
        let ed25519Key = try requireEd25519()

        var challengeBytes = Data(count: 32)
        let result = challengeBytes.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard result == errSecSuccess else { throw CryptoError.signatureFailed }

        let signature = try ed25519Key.signature(for: challengeBytes)

        return AuthChallenge(
            challenge: challengeBytes.base64EncodedString(),
            publicKey: ed25519Key.publicKey.rawRepresentation.base64EncodedString(),
            signature: signature.base64EncodedString()
        )
    }

    // MARK: - Encrypt / Decrypt (X25519 ECDH + ChaChaPoly)

    func encrypt(message: Data, recipientPublicKey: Data) throws -> Data {
        guard let recipientKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPublicKey) else {
            throw CryptoError.invalidPublicKey
        }

        let sharedSecret = try requireX25519().sharedSecretFromKeyAgreement(with: recipientKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("sentinel-v1".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        let sealed = try ChaChaPoly.seal(message, using: symmetricKey)
        return sealed.combined
    }

    func decrypt(encrypted: Data, senderPublicKey: Data) throws -> Data {
        guard let senderKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderPublicKey) else {
            throw CryptoError.invalidPublicKey
        }

        let sharedSecret = try requireX25519().sharedSecretFromKeyAgreement(with: senderKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("sentinel-v1".utf8),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        let sealedBox = try ChaChaPoly.SealedBox(combined: encrypted)
        return try ChaChaPoly.open(sealedBox, using: symmetricKey)
    }

    // MARK: - Sign (Ed25519)

    func sign(_ message: Data) throws -> Data {
        try requireEd25519().signature(for: message)
    }

    // MARK: - Reset

    func resetIdentity() {
        KeychainHelper.delete(key: seedTag)
        KeychainHelper.delete(key: x25519KeyTag)
        KeychainHelper.delete(key: ed25519KeyTag)
        _x25519Private = nil
        _ed25519Private = nil
    }
}
