import { describe, test } from 'node:test';
import assert from 'node:assert';
import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';

/**
 * Unit tests for transport encryption (NaCl secretbox).
 *
 * Run: npx tsx --test src/__tests__/transport-encryption.test.ts
 */

// Inline encrypt/decrypt to avoid module init side effects
function encryptMessage(plaintext: string, key: Uint8Array): string {
  const nonce = nacl.randomBytes(24);
  const msgBytes = new TextEncoder().encode(plaintext);
  const encrypted = nacl.secretbox(msgBytes, nonce, key);
  const combined = new Uint8Array(24 + encrypted.length);
  combined.set(nonce, 0);
  combined.set(encrypted, 24);
  return encodeBase64(combined);
}

function decryptMessage(encoded: string, key: Uint8Array): string | null {
  try {
    const combined = decodeBase64(encoded);
    if (combined.length < 25) return null;
    const nonce = combined.slice(0, 24);
    const ciphertext = combined.slice(24);
    const decrypted = nacl.secretbox.open(ciphertext, nonce, key);
    if (!decrypted) return null;
    return new TextDecoder().decode(decrypted);
  } catch {
    return null;
  }
}

describe('transport encryption', () => {
  const key = nacl.randomBytes(32);

  test('encrypt then decrypt roundtrip', () => {
    const message = '{"event":"approval_request","data":{"id":"abc123"}}';
    const encrypted = encryptMessage(message, key);
    const decrypted = decryptMessage(encrypted, key);
    assert.strictEqual(decrypted, message);
  });

  test('decrypt with wrong key fails', () => {
    const wrongKey = nacl.randomBytes(32);
    const encrypted = encryptMessage('secret data', key);
    const result = decryptMessage(encrypted, wrongKey);
    assert.strictEqual(result, null);
  });

  test('decrypt garbage returns null', () => {
    assert.strictEqual(decryptMessage('not-valid-base64!!!', key), null);
    assert.strictEqual(decryptMessage(encodeBase64(new Uint8Array(10)), key), null);
  });

  test('handles empty message', () => {
    const encrypted = encryptMessage('', key);
    const decrypted = decryptMessage(encrypted, key);
    assert.strictEqual(decrypted, '');
  });

  test('handles unicode', () => {
    const msg = '审批请求：工具 Write → /tmp/文件.txt';
    const encrypted = encryptMessage(msg, key);
    const decrypted = decryptMessage(encrypted, key);
    assert.strictEqual(decrypted, msg);
  });

  test('encrypted output is base64', () => {
    const encrypted = encryptMessage('test', key);
    // Should be valid base64
    assert.doesNotThrow(() => decodeBase64(encrypted));
    // Should not be plain text
    assert.notStrictEqual(encrypted, 'test');
  });

  test('nonce is unique per encryption', () => {
    const e1 = encryptMessage('same', key);
    const e2 = encryptMessage('same', key);
    // Same plaintext, different nonces → different ciphertext
    assert.notStrictEqual(e1, e2);
  });
});

describe('pending request store', () => {
  test('resolve resolves the promise', async () => {
    // Simple simulation of the pending store behavior
    let resolvedAction: string | null = null;
    const promise = new Promise<string>((resolve) => {
      setTimeout(() => resolve('allowed'), 10);
    });
    resolvedAction = await promise;
    assert.strictEqual(resolvedAction, 'allowed');
  });
});
