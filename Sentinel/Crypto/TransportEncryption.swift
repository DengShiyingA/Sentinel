import Foundation
import CryptoKit

/// Transport-layer encryption for local TCP communication.
/// Uses XSalsa20-Poly1305 compatible symmetric encryption via ChaChaPoly.
/// Key is received from Mac's Bonjour TXT record during discovery.
enum TransportEncryption {
    /// Stored transport key (received from Bonjour or manual entry)
    private(set) static var sharedKey: SymmetricKey?

    /// Set the shared key from base64 string (from Bonjour TXT "ek" field, v2 fallback)
    static func setKey(base64: String) {
        guard let keyData = Data(base64Encoded: base64), keyData.count == 32 else { return }
        sharedKey = SymmetricKey(data: keyData)
    }

    /// Set the shared key from an ECDH-derived SymmetricKey (v3 secure handshake)
    static func setDerivedKey(_ key: SymmetricKey) {
        sharedKey = key
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
    /// Handles both ChaChaPoly (nonce=12) and NaCl secretbox (XSalsa20-Poly1305, nonce=24) formats.
    ///
    /// ChaChaPoly combined = nonce(12) + ciphertext + tag(16), minimum 28 bytes.
    /// NaCl secretbox combined = nonce(24) + mac(16) + ciphertext, minimum 40 bytes.
    ///
    /// Note: XSalsa20-Poly1305 and ChaChaPoly are different algorithms sharing the same key.
    /// CryptoKit does not support XSalsa20, so for NaCl-encrypted messages we implement
    /// the XSalsa20-Poly1305 open manually using the raw key bytes.
    static func decrypt(_ encoded: String) -> String? {
        guard let key = sharedKey,
              let combined = Data(base64Encoded: encoded) else { return nil }

        // Try ChaChaPoly first (iOS-native format)
        if let result = decryptChaChaPoly(combined, key: key) {
            return result
        }

        // Try NaCl secretbox format (CLI uses tweetnacl)
        if let result = decryptNaClSecretbox(combined, key: key) {
            return result
        }

        return nil
    }

    private static func decryptChaChaPoly(_ combined: Data, key: SymmetricKey) -> String? {
        // ChaChaPoly.SealedBox(combined:) expects nonce(12) + ciphertext + tag(16)
        guard combined.count >= 28 else { return nil }
        guard let sealedBox = try? ChaChaPoly.SealedBox(combined: combined),
              let decrypted = try? ChaChaPoly.open(sealedBox, using: key) else {
            return nil
        }
        return String(data: decrypted, encoding: .utf8)
    }

    /// Decrypt NaCl secretbox (XSalsa20-Poly1305) format.
    /// combined = nonce(24) + box(mac(16) + ciphertext)
    ///
    /// Since CryptoKit doesn't support XSalsa20, we use a pure-Swift implementation
    /// of the Salsa20/HSalsa20 core to derive the subkey and stream.
    private static func decryptNaClSecretbox(_ combined: Data, key: SymmetricKey) -> String? {
        guard combined.count > 40 else { return nil }

        let keyBytes = key.withUnsafeBytes { Array($0) }
        guard keyBytes.count == 32 else { return nil }

        let nonce = Array(combined.prefix(24))
        let box = Array(combined.dropFirst(24))

        guard let decrypted = naclSecretboxOpen(box: box, nonce: nonce, key: keyBytes) else {
            return nil
        }
        return String(bytes: decrypted, encoding: .utf8)
    }

    // MARK: - NaCl secretbox (XSalsa20-Poly1305) pure Swift implementation

    /// Open a NaCl secretbox. box = mac(16) + ciphertext.
    private static func naclSecretboxOpen(box: [UInt8], nonce: [UInt8], key: [UInt8]) -> [UInt8]? {
        guard box.count >= 16, nonce.count == 24, key.count == 32 else { return nil }

        // XSalsa20: derive subkey via HSalsa20(key, nonce[0..16])
        let subkey = hsalsa20(key: key, nonce: Array(nonce[0..<16]))

        // Build 8-byte subnonce from nonce[16..24] padded to match xsalsa20 spec
        var subNonce = [UInt8](repeating: 0, count: 8)
        for i in 0..<8 { subNonce[i] = nonce[16 + i] }

        // Salsa20 stream for Poly1305 key (first 32 bytes) and decryption
        // We need stream bytes for: 32 bytes (poly key) + box.count bytes
        let fullLen = 32 + box.count
        let stream = salsa20XOR(message: [UInt8](repeating: 0, count: fullLen), nonce: subNonce, key: subkey)

        // Poly1305 verify: tag over the ciphertext using first 32 bytes of stream as key
        let polyKey = Array(stream[0..<32])
        let mac = Array(box[0..<16])
        let ciphertext = Array(box[16...])

        guard poly1305Verify(mac: mac, message: ciphertext, key: polyKey) else { return nil }

        // Decrypt: XOR ciphertext with stream[32...]
        var plaintext = [UInt8](repeating: 0, count: ciphertext.count)
        for i in 0..<ciphertext.count {
            plaintext[i] = ciphertext[i] ^ stream[32 + i]
        }
        return plaintext
    }

    /// HSalsa20 core: produces 32-byte subkey from 32-byte key and 16-byte nonce.
    private static func hsalsa20(key: [UInt8], nonce: [UInt8]) -> [UInt8] {
        func load32(_ b: [UInt8], _ i: Int) -> UInt32 {
            UInt32(b[i]) | (UInt32(b[i+1]) << 8) | (UInt32(b[i+2]) << 16) | (UInt32(b[i+3]) << 24)
        }
        func store32(_ v: UInt32) -> [UInt8] {
            [UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 24) & 0xff)]
        }

        let sigma: [UInt32] = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]

        var x0 = sigma[0], x1 = load32(key, 0), x2 = load32(key, 4), x3 = load32(key, 8)
        var x4 = load32(key, 12), x5 = sigma[1], x6 = load32(nonce, 0), x7 = load32(nonce, 4)
        var x8 = load32(nonce, 8), x9 = load32(nonce, 12), x10 = sigma[2], x11 = load32(key, 16)
        var x12 = load32(key, 20), x13 = load32(key, 24), x14 = load32(key, 28), x15 = sigma[3]

        for _ in 0..<10 {
            // Column rounds
            x0  &+= x4;  x12 = (x12 ^ x0).rotl(7)
            x8  &+= x12; x4  = (x4  ^ x8).rotl(9)
            x0  &+= x4;  x12 = (x12 ^ x0).rotl(13)
            x8  &+= x12; x4  = (x4  ^ x8).rotl(18)

            x5  &+= x9;  x1  = (x1  ^ x5).rotl(7)
            x13 &+= x1;  x9  = (x9  ^ x13).rotl(9)
            x5  &+= x9;  x1  = (x1  ^ x5).rotl(13)
            x13 &+= x1;  x9  = (x9  ^ x13).rotl(18)

            x10 &+= x14; x6  = (x6  ^ x10).rotl(7)
            x2  &+= x6;  x14 = (x14 ^ x2).rotl(9)
            x10 &+= x14; x6  = (x6  ^ x10).rotl(13)
            x2  &+= x6;  x14 = (x14 ^ x2).rotl(18)

            x15 &+= x3;  x11 = (x11 ^ x15).rotl(7)
            x7  &+= x11; x3  = (x3  ^ x7).rotl(9)
            x15 &+= x3;  x11 = (x11 ^ x15).rotl(13)
            x7  &+= x11; x3  = (x3  ^ x7).rotl(18)

            // Diagonal rounds
            x0  &+= x1;  x3  = (x3  ^ x0).rotl(7)
            x2  &+= x3;  x1  = (x1  ^ x2).rotl(9)
            x0  &+= x1;  x3  = (x3  ^ x0).rotl(13)
            x2  &+= x3;  x1  = (x1  ^ x2).rotl(18)

            x5  &+= x6;  x4  = (x4  ^ x5).rotl(7)
            x7  &+= x4;  x6  = (x6  ^ x7).rotl(9)
            x5  &+= x6;  x4  = (x4  ^ x5).rotl(13)
            x7  &+= x4;  x6  = (x6  ^ x7).rotl(18)

            x10 &+= x11; x9  = (x9  ^ x10).rotl(7)
            x8  &+= x9;  x11 = (x11 ^ x8).rotl(9)
            x10 &+= x11; x9  = (x9  ^ x10).rotl(13)
            x8  &+= x9;  x11 = (x11 ^ x8).rotl(18)

            x15 &+= x12; x14 = (x14 ^ x15).rotl(7)
            x13 &+= x14; x12 = (x12 ^ x13).rotl(9)
            x15 &+= x12; x14 = (x14 ^ x15).rotl(13)
            x13 &+= x14; x12 = (x12 ^ x13).rotl(18)
        }

        // HSalsa20 output: x0, x5, x10, x15, x6, x7, x8, x9
        var out = [UInt8]()
        out.append(contentsOf: store32(x0))
        out.append(contentsOf: store32(x5))
        out.append(contentsOf: store32(x10))
        out.append(contentsOf: store32(x15))
        out.append(contentsOf: store32(x6))
        out.append(contentsOf: store32(x7))
        out.append(contentsOf: store32(x8))
        out.append(contentsOf: store32(x9))
        return out
    }

    /// Salsa20 XOR: encrypts/decrypts message using Salsa20 stream with 8-byte nonce.
    private static func salsa20XOR(message: [UInt8], nonce: [UInt8], key: [UInt8]) -> [UInt8] {
        func load32(_ b: [UInt8], _ i: Int) -> UInt32 {
            UInt32(b[i]) | (UInt32(b[i+1]) << 8) | (UInt32(b[i+2]) << 16) | (UInt32(b[i+3]) << 24)
        }
        func store32(_ v: UInt32) -> [UInt8] {
            [UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 24) & 0xff)]
        }

        let sigma: [UInt32] = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
        var output = [UInt8](repeating: 0, count: message.count)
        let blocks = (message.count + 63) / 64

        for block in 0..<blocks {
            let j0 = sigma[0], j1 = load32(key, 0), j2 = load32(key, 4), j3 = load32(key, 8)
            let j4 = load32(key, 12), j5 = sigma[1], j6 = load32(nonce, 0), j7 = load32(nonce, 4)
            let j8 = UInt32(block & 0xffffffff), j9 = UInt32(block >> 32), j10 = sigma[2]
            let j11 = load32(key, 16), j12 = load32(key, 20), j13 = load32(key, 24)
            let j14 = load32(key, 28), j15 = sigma[3]

            var x0 = j0, x1 = j1, x2 = j2, x3 = j3
            var x4 = j4, x5 = j5, x6 = j6, x7 = j7
            var x8 = j8, x9 = j9, x10 = j10, x11 = j11
            var x12 = j12, x13 = j13, x14 = j14, x15 = j15

            for _ in 0..<10 {
                x0  &+= x4;  x12 = (x12 ^ x0).rotl(7)
                x8  &+= x12; x4  = (x4  ^ x8).rotl(9)
                x0  &+= x4;  x12 = (x12 ^ x0).rotl(13)
                x8  &+= x12; x4  = (x4  ^ x8).rotl(18)

                x5  &+= x9;  x1  = (x1  ^ x5).rotl(7)
                x13 &+= x1;  x9  = (x9  ^ x13).rotl(9)
                x5  &+= x9;  x1  = (x1  ^ x5).rotl(13)
                x13 &+= x1;  x9  = (x9  ^ x13).rotl(18)

                x10 &+= x14; x6  = (x6  ^ x10).rotl(7)
                x2  &+= x6;  x14 = (x14 ^ x2).rotl(9)
                x10 &+= x14; x6  = (x6  ^ x10).rotl(13)
                x2  &+= x6;  x14 = (x14 ^ x2).rotl(18)

                x15 &+= x3;  x11 = (x11 ^ x15).rotl(7)
                x7  &+= x11; x3  = (x3  ^ x7).rotl(9)
                x15 &+= x3;  x11 = (x11 ^ x15).rotl(13)
                x7  &+= x11; x3  = (x3  ^ x7).rotl(18)

                x0  &+= x1;  x3  = (x3  ^ x0).rotl(7)
                x2  &+= x3;  x1  = (x1  ^ x2).rotl(9)
                x0  &+= x1;  x3  = (x3  ^ x0).rotl(13)
                x2  &+= x3;  x1  = (x1  ^ x2).rotl(18)

                x5  &+= x6;  x4  = (x4  ^ x5).rotl(7)
                x7  &+= x4;  x6  = (x6  ^ x7).rotl(9)
                x5  &+= x6;  x4  = (x4  ^ x5).rotl(13)
                x7  &+= x4;  x6  = (x6  ^ x7).rotl(18)

                x10 &+= x11; x9  = (x9  ^ x10).rotl(7)
                x8  &+= x9;  x11 = (x11 ^ x8).rotl(9)
                x10 &+= x11; x9  = (x9  ^ x10).rotl(13)
                x8  &+= x9;  x11 = (x11 ^ x8).rotl(18)

                x15 &+= x12; x14 = (x14 ^ x15).rotl(7)
                x13 &+= x14; x12 = (x12 ^ x13).rotl(9)
                x15 &+= x12; x14 = (x14 ^ x15).rotl(13)
                x13 &+= x14; x12 = (x12 ^ x13).rotl(18)
            }

            var stream = [UInt8]()
            for v in [x0 &+ j0, x1 &+ j1, x2 &+ j2, x3 &+ j3,
                       x4 &+ j4, x5 &+ j5, x6 &+ j6, x7 &+ j7,
                       x8 &+ j8, x9 &+ j9, x10 &+ j10, x11 &+ j11,
                       x12 &+ j12, x13 &+ j13, x14 &+ j14, x15 &+ j15] {
                stream.append(contentsOf: store32(v))
            }

            let start = block * 64
            let end = min(start + 64, message.count)
            for i in start..<end {
                output[i] = message[i] ^ stream[i - start]
            }
        }
        return output
    }

    /// Poly1305 one-time authenticator verify.
    private static func poly1305Verify(mac: [UInt8], message: [UInt8], key: [UInt8]) -> Bool {
        guard mac.count == 16, key.count == 32 else { return false }

        // r = key[0..16] clamped, s = key[16..32]
        var r = [UInt32](repeating: 0, count: 5)
        r[0] = (UInt32(key[0]) | (UInt32(key[1]) << 8) | (UInt32(key[2]) << 16) | (UInt32(key[3]) << 24)) & 0x3ffffff
        r[1] = ((UInt32(key[3]) | (UInt32(key[4]) << 8) | (UInt32(key[5]) << 16) | (UInt32(key[6]) << 24)) >> 2) & 0x3ffff03
        r[2] = ((UInt32(key[6]) | (UInt32(key[7]) << 8) | (UInt32(key[8]) << 16) | (UInt32(key[9]) << 24)) >> 4) & 0x3ffc0ff
        r[3] = ((UInt32(key[9]) | (UInt32(key[10]) << 8) | (UInt32(key[11]) << 16) | (UInt32(key[12]) << 24)) >> 6) & 0x3f03fff
        r[4] = ((UInt32(key[12]) | (UInt32(key[13]) << 8) | (UInt32(key[14]) << 16) | (UInt32(key[15]) << 24)) >> 8) & 0x00fffff

        var h = [UInt32](repeating: 0, count: 5)
        let blocks = (message.count + 15) / 16

        for i in 0..<blocks {
            let start = i * 16
            let end = min(start + 16, message.count)
            var n = [UInt8](repeating: 0, count: 17)
            for j in start..<end { n[j - start] = message[j] }
            n[end - start] = 1 // hibit

            h[0] &+= (UInt32(n[0]) | (UInt32(n[1]) << 8) | (UInt32(n[2]) << 16) | (UInt32(n[3]) << 24)) & 0x3ffffff
            h[1] &+= ((UInt32(n[3]) | (UInt32(n[4]) << 8) | (UInt32(n[5]) << 16) | (UInt32(n[6]) << 24)) >> 2) & 0x3ffffff
            h[2] &+= ((UInt32(n[6]) | (UInt32(n[7]) << 8) | (UInt32(n[8]) << 16) | (UInt32(n[9]) << 24)) >> 4) & 0x3ffffff
            h[3] &+= ((UInt32(n[9]) | (UInt32(n[10]) << 8) | (UInt32(n[11]) << 16) | (UInt32(n[12]) << 24)) >> 6) & 0x3ffffff
            h[4] &+= ((UInt32(n[12]) | (UInt32(n[13]) << 8) | (UInt32(n[14]) << 16) | (UInt32(n[15]) << 24)) >> 8) | (UInt32(n[16]) << 24)

            // Multiply h * r mod 2^130-5
            var d = [UInt64](repeating: 0, count: 5)
            for j in 0..<5 {
                for k in 0..<5 {
                    let rval: UInt64 = (k <= j) ? UInt64(r[j - k]) : UInt64(r[j + 5 - k]) * 5
                    d[j] &+= UInt64(h[k]) &* rval
                }
            }

            // Carry propagation
            var c: UInt32 = 0
            for j in 0..<5 {
                d[j] += UInt64(c)
                c = UInt32(d[j] >> 26)
                h[j] = UInt32(d[j] & 0x3ffffff)
            }
            h[0] &+= c &* 5
            c = h[0] >> 26; h[0] &= 0x3ffffff
            h[1] &+= c
        }

        // Final reduction mod 2^130-5
        var c: UInt32 = 0
        for j in 1..<5 { c = h[j] >> 26; h[j] &= 0x3ffffff; h[(j+1) % 5] &+= c }
        h[0] &+= (h[0] >> 26) * 5; h[0] &= 0x3ffffff

        // Compute h + s
        var s = [UInt32](repeating: 0, count: 4)
        for i in 0..<4 {
            s[i] = UInt32(key[16 + i*4]) | (UInt32(key[17 + i*4]) << 8) |
                   (UInt32(key[18 + i*4]) << 16) | (UInt32(key[19 + i*4]) << 24)
        }

        // Convert h from radix-2^26 to 4 x UInt32
        var f: UInt64 = 0
        var g = [UInt32](repeating: 0, count: 4)
        f = UInt64(h[0]) | (UInt64(h[1]) << 26); g[0] = UInt32(f & 0xffffffff)
        f = (f >> 32) &+ (UInt64(h[2]) << 20); g[1] = UInt32(f & 0xffffffff)
        f = (f >> 32) &+ (UInt64(h[3]) << 14); g[2] = UInt32(f & 0xffffffff)
        f = (f >> 32) &+ (UInt64(h[4]) << 8);  g[3] = UInt32(f & 0xffffffff)

        // Add s
        var carry: UInt64 = 0
        for i in 0..<4 {
            carry &+= UInt64(g[i]) &+ UInt64(s[i])
            g[i] = UInt32(carry & 0xffffffff)
            carry >>= 32
        }

        // Compare
        var computed = [UInt8](repeating: 0, count: 16)
        for i in 0..<4 {
            computed[i*4]     = UInt8(g[i] & 0xff)
            computed[i*4 + 1] = UInt8((g[i] >> 8) & 0xff)
            computed[i*4 + 2] = UInt8((g[i] >> 16) & 0xff)
            computed[i*4 + 3] = UInt8((g[i] >> 24) & 0xff)
        }

        // Constant-time comparison
        var diff: UInt8 = 0
        for i in 0..<16 { diff |= computed[i] ^ mac[i] }
        return diff == 0
    }

    /// Check if encryption is available
    static var isEnabled: Bool { sharedKey != nil }
}

// MARK: - UInt32 rotate left helper for Salsa20

private extension UInt32 {
    func rotl(_ n: Int) -> UInt32 {
        (self << n) | (self >> (32 - n))
    }
}
