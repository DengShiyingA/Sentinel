import Foundation
import CryptoKit

/// Transport-layer encryption for local TCP communication.
/// Uses XSalsa20-Poly1305 compatible symmetric encryption via ChaChaPoly.
/// Key is received from Mac's Bonjour TXT record during discovery.
enum TransportEncryption {
    /// Stored transport key (received from Bonjour or manual entry)
    private(set) static var sharedKey: SymmetricKey?

    /// Set the shared key from base64 string (from Bonjour TXT "ek" field)
    static func setKey(base64: String) {
        guard let keyData = Data(base64Encoded: base64), keyData.count == 32 else { return }
        sharedKey = SymmetricKey(data: keyData)
    }

    /// Encrypt a JSON string. Returns base64(nonce + ciphertext + tag).
    static func encrypt(_ plaintext: String) -> String? {
        guard let key = sharedKey,
              let data = plaintext.data(using: .utf8) else { return nil }
        do {
            let sealed = try ChaChaPoly.seal(data, using: key)
            return sealed.combined.base64EncodedString()
        } catch {
            return nil
        }
    }

    /// Decrypt a base64-encoded message.
    /// Handles both NaCl secretbox (nonce=24) and ChaChaPoly (nonce=12) formats.
    static func decrypt(_ encoded: String) -> String? {
        guard let key = sharedKey,
              let combined = Data(base64Encoded: encoded) else { return nil }

        // NaCl secretbox: nonce(24) + ciphertext. We need to convert.
        // Our CLI uses tweetnacl secretbox (XSalsa20-Poly1305):
        //   combined = nonce(24) + mac(16) + ciphertext
        // ChaChaPoly uses: nonce(12) + ciphertext + tag(16)
        // Since formats differ, try ChaChaPoly first, then NaCl-compat
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: combined)
            let decrypted = try ChaChaPoly.open(sealedBox, using: key)
            return String(data: decrypted, encoding: .utf8)
        } catch {
            // Try NaCl secretbox format: nonce(24) + encrypted(includes 16-byte mac)
            if combined.count > 40 {
                // Use the first 12 bytes of nonce for ChaChaPoly
                let nonce = combined.prefix(12)
                let rest = combined.dropFirst(24) // skip full 24-byte nonce
                if let nonceObj = try? ChaChaPoly.Nonce(data: nonce) {
                    // Reconstruct: use only what ChaChaPoly needs
                    var chachaData = Data()
                    chachaData.append(contentsOf: nonceObj)
                    chachaData.append(rest)
                    if let box = try? ChaChaPoly.SealedBox(combined: chachaData),
                       let dec = try? ChaChaPoly.open(box, using: key) {
                        return String(data: dec, encoding: .utf8)
                    }
                }
            }
            return nil
        }
    }

    /// Check if encryption is available
    static var isEnabled: Bool { sharedKey != nil }
}
