import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';
/**
 * 获取 Ed25519 签名密钥对（从 seed 派生）
 */
export declare function getKeyPair(): nacl.SignKeyPair;
/**
 * 公钥 base64
 */
export declare function getPublicKeyBase64(): string;
export interface AuthChallenge {
    challenge: string;
    publicKey: string;
    signature: string;
}
/**
 * 生成认证 challenge：
 * 1. 生成 32 字节随机 challenge
 * 2. 用 Ed25519 私钥签名
 * 3. 返回 { challenge, publicKey, signature } — 全部 base64
 */
export declare function authChallenge(): AuthChallenge;
/**
 * 加密数据给目标设备（参考 Happy encryption.ts）：
 *
 * 1. 生成 ephemeral X25519 密钥对
 * 2. 生成 24 字节随机 nonce
 * 3. nacl.box(data, nonce, recipientPublicKey, ephemeral.secretKey)
 * 4. 返回: ephemeralPubKey(32) + nonce(24) + encryptedData
 */
export declare function encryptForDevice(data: Uint8Array, recipientPublicKey: Uint8Array): Uint8Array;
/**
 * 解密来自设备的数据（反向 encryptForDevice）：
 *
 * 1. 提取 ephemeralPubKey(32) + nonce(24) + encryptedData
 * 2. nacl.box.open(encryptedData, nonce, ephemeralPubKey, mySecretKey)
 */
export declare function decryptFromDevice(bundle: Uint8Array, mySecretKey: Uint8Array): Uint8Array;
export declare function getSentinelDir(): string;
export { encodeBase64, decodeBase64 };
