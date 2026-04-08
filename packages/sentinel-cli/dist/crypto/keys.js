"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.decodeBase64 = exports.encodeBase64 = void 0;
exports.getKeyPair = getKeyPair;
exports.getPublicKeyBase64 = getPublicKeyBase64;
exports.authChallenge = authChallenge;
exports.encryptForDevice = encryptForDevice;
exports.decryptFromDevice = decryptFromDevice;
exports.getSentinelDir = getSentinelDir;
const tweetnacl_1 = __importDefault(require("tweetnacl"));
const tweetnacl_util_1 = require("tweetnacl-util");
Object.defineProperty(exports, "encodeBase64", { enumerable: true, get: function () { return tweetnacl_util_1.encodeBase64; } });
Object.defineProperty(exports, "decodeBase64", { enumerable: true, get: function () { return tweetnacl_util_1.decodeBase64; } });
const crypto_1 = require("crypto");
const fs_1 = require("fs");
const path_1 = require("path");
const os_1 = require("os");
const SENTINEL_DIR = (0, path_1.join)((0, os_1.homedir)(), '.sentinel');
const IDENTITY_PATH = (0, path_1.join)(SENTINEL_DIR, 'identity.json');
// ==================== Identity (Ed25519) ====================
function ensureDir() {
    if (!(0, fs_1.existsSync)(SENTINEL_DIR)) {
        (0, fs_1.mkdirSync)(SENTINEL_DIR, { recursive: true, mode: 0o700 });
    }
}
/**
 * 首次运行生成 Ed25519 seed（32 随机字节），存 ~/.sentinel/identity.json
 * 后续直接读取
 */
function loadOrCreateSeed() {
    ensureDir();
    if ((0, fs_1.existsSync)(IDENTITY_PATH)) {
        const raw = JSON.parse((0, fs_1.readFileSync)(IDENTITY_PATH, 'utf-8'));
        return (0, tweetnacl_util_1.decodeBase64)(raw.seed);
    }
    const seed = (0, crypto_1.randomBytes)(32);
    const identity = {
        seed: (0, tweetnacl_util_1.encodeBase64)(seed),
        createdAt: new Date().toISOString(),
    };
    (0, fs_1.writeFileSync)(IDENTITY_PATH, JSON.stringify(identity, null, 2), { mode: 0o600 });
    return seed;
}
let _seed = null;
function getSeed() {
    if (!_seed)
        _seed = loadOrCreateSeed();
    return _seed;
}
/**
 * 获取 Ed25519 签名密钥对（从 seed 派生）
 */
function getKeyPair() {
    return tweetnacl_1.default.sign.keyPair.fromSeed(getSeed());
}
/**
 * 公钥 base64
 */
function getPublicKeyBase64() {
    return (0, tweetnacl_util_1.encodeBase64)(getKeyPair().publicKey);
}
/**
 * 生成认证 challenge：
 * 1. 生成 32 字节随机 challenge
 * 2. 用 Ed25519 私钥签名
 * 3. 返回 { challenge, publicKey, signature } — 全部 base64
 */
function authChallenge() {
    const kp = getKeyPair();
    const challengeBytes = (0, crypto_1.randomBytes)(32);
    const signature = tweetnacl_1.default.sign.detached(challengeBytes, kp.secretKey);
    return {
        challenge: (0, tweetnacl_util_1.encodeBase64)(challengeBytes),
        publicKey: (0, tweetnacl_util_1.encodeBase64)(kp.publicKey),
        signature: (0, tweetnacl_util_1.encodeBase64)(signature),
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
function encryptForDevice(data, recipientPublicKey) {
    const ephemeral = tweetnacl_1.default.box.keyPair();
    const nonce = (0, crypto_1.randomBytes)(24);
    const encrypted = tweetnacl_1.default.box(data, nonce, recipientPublicKey, ephemeral.secretKey);
    if (!encrypted)
        throw new Error('Encryption failed');
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
function decryptFromDevice(bundle, mySecretKey) {
    if (bundle.length < 57)
        throw new Error('Bundle too short');
    const ephemeralPubKey = bundle.slice(0, 32);
    const nonce = bundle.slice(32, 56);
    const ciphertext = bundle.slice(56);
    const decrypted = tweetnacl_1.default.box.open(ciphertext, nonce, ephemeralPubKey, mySecretKey);
    if (!decrypted)
        throw new Error('Decryption failed — invalid key or corrupted data');
    return decrypted;
}
// ==================== Helpers ====================
function getSentinelDir() {
    ensureDir();
    return SENTINEL_DIR;
}
//# sourceMappingURL=keys.js.map