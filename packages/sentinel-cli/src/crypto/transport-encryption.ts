import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';
import { randomBytes } from 'crypto';
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from './keys';

const SHARED_KEY_PATH = join(getSentinelDir(), 'transport.key');

/**
 * Transport encryption using NaCl secretbox (XSalsa20-Poly1305).
 * Shared key generated on first start, stored in ~/.sentinel/transport.key.
 * iOS receives the key during Bonjour handshake.
 */

/** Get or create the 32-byte shared transport key */
export function getTransportKey(): Uint8Array {
  if (existsSync(SHARED_KEY_PATH)) {
    return decodeBase64(readFileSync(SHARED_KEY_PATH, 'utf-8').trim());
  }
  const key = nacl.randomBytes(32);
  writeFileSync(SHARED_KEY_PATH, encodeBase64(key), { mode: 0o600 });
  return key;
}

/** Encrypt a JSON message string. Returns base64(nonce + ciphertext) */
export function encryptMessage(plaintext: string, key: Uint8Array): string {
  const nonce = nacl.randomBytes(24);
  const msgBytes = new TextEncoder().encode(plaintext);
  const encrypted = nacl.secretbox(msgBytes, nonce, key);

  // Concat nonce(24) + ciphertext
  const combined = new Uint8Array(24 + encrypted.length);
  combined.set(nonce, 0);
  combined.set(encrypted, 24);

  return encodeBase64(combined);
}

/** Decrypt a base64-encoded message. Returns the JSON string */
export function decryptMessage(encoded: string, key: Uint8Array): string | null {
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

/** Get transport key as base64 (for sharing with iOS during handshake) */
export function getTransportKeyBase64(): string {
  return encodeBase64(getTransportKey());
}
