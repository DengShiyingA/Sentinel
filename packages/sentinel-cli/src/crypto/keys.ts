import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';
import { randomBytes } from 'crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const SENTINEL_DIR = join(homedir(), '.sentinel');
const IDENTITY_PATH = join(SENTINEL_DIR, 'identity.json');

interface IdentityFile {
  seed: string;         // base64, 32 bytes — Ed25519 seed
  createdAt: string;
}

// ==================== Identity (Ed25519) ====================

function ensureDir(): void {
  if (!existsSync(SENTINEL_DIR)) {
    mkdirSync(SENTINEL_DIR, { recursive: true, mode: 0o700 });
  }
}

/**
 * 首次运行生成 Ed25519 seed（32 随机字节），存 ~/.sentinel/identity.json
 * 后续直接读取
 */
function loadOrCreateSeed(): Uint8Array {
  ensureDir();

  if (existsSync(IDENTITY_PATH)) {
    const raw = JSON.parse(readFileSync(IDENTITY_PATH, 'utf-8')) as IdentityFile;
    return decodeBase64(raw.seed);
  }

  const seed = randomBytes(32);
  const identity: IdentityFile = {
    seed: encodeBase64(seed),
    createdAt: new Date().toISOString(),
  };
  writeFileSync(IDENTITY_PATH, JSON.stringify(identity, null, 2), { mode: 0o600 });
  return seed;
}

let _seed: Uint8Array | null = null;

function getSeed(): Uint8Array {
  if (!_seed) _seed = loadOrCreateSeed();
  return _seed;
}

/**
 * 获取 Ed25519 签名密钥对（从 seed 派生）
 */
export function getKeyPair(): nacl.SignKeyPair {
  return nacl.sign.keyPair.fromSeed(getSeed());
}

/**
 * 公钥 base64
 */
export function getPublicKeyBase64(): string {
  return encodeBase64(getKeyPair().publicKey);
}

// ==================== Auth Challenge ====================

export interface AuthChallenge {
  challenge: string;    // base64
  publicKey: string;    // base64
  signature: string;    // base64
}

/**
 * 生成认证 challenge：
 * 1. 生成 32 字节随机 challenge
 * 2. 用 Ed25519 私钥签名
 * 3. 返回 { challenge, publicKey, signature } — 全部 base64
 */
export function authChallenge(): AuthChallenge {
  const kp = getKeyPair();
  const challengeBytes = randomBytes(32);
  const signature = nacl.sign.detached(challengeBytes, kp.secretKey);

  return {
    challenge: encodeBase64(challengeBytes),
    publicKey: encodeBase64(kp.publicKey),
    signature: encodeBase64(signature),
  };
}

// ==================== Encryption (X25519 box) ====================

/**
 * 加密数据给目标设备（参考 Happy encryption.ts）：
 *
 * 1. 生成 ephemeral X25519 密钥对
 * 2. 生成 24 字节随机 nonce
 * 3. nacl.box(data, nonce, recipientPublicKey, ephemeral.secretKey)
 * 4. 返回: ephemeralPubKey(32) + nonce(24) + encryptedData
 */
export function encryptForDevice(
  data: Uint8Array,
  recipientPublicKey: Uint8Array,
): Uint8Array {
  const ephemeral = nacl.box.keyPair();
  const nonce = randomBytes(24);

  const encrypted = nacl.box(data, nonce, recipientPublicKey, ephemeral.secretKey);
  if (!encrypted) throw new Error('Encryption failed');

  // concat: ephemeralPubKey(32) + nonce(24) + encrypted
  const bundle = new Uint8Array(32 + 24 + encrypted.length);
  bundle.set(ephemeral.publicKey, 0);
  bundle.set(nonce, 32);
  bundle.set(encrypted, 56);
  return bundle;
}

/**
 * 解密来自设备的数据（反向 encryptForDevice）：
 *
 * 1. 提取 ephemeralPubKey(32) + nonce(24) + encryptedData
 * 2. nacl.box.open(encryptedData, nonce, ephemeralPubKey, mySecretKey)
 */
export function decryptFromDevice(
  bundle: Uint8Array,
  mySecretKey: Uint8Array,
): Uint8Array {
  if (bundle.length < 57) throw new Error('Bundle too short');

  const ephemeralPubKey = bundle.slice(0, 32);
  const nonce = bundle.slice(32, 56);
  const ciphertext = bundle.slice(56);

  const decrypted = nacl.box.open(ciphertext, nonce, ephemeralPubKey, mySecretKey);
  if (!decrypted) throw new Error('Decryption failed — invalid key or corrupted data');

  return decrypted;
}

// ==================== Helpers ====================

export function getSentinelDir(): string {
  ensureDir();
  return SENTINEL_DIR;
}

export { encodeBase64, decodeBase64 };
