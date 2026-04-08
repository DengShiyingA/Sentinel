"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authGetToken = authGetToken;
exports.loadToken = loadToken;
exports.ensureToken = ensureToken;
exports.getStoredServerURL = getStoredServerURL;
exports.clearToken = clearToken;
const fs_1 = require("fs");
const path_1 = require("path");
const keys_1 = require("../crypto/keys");
const logger_1 = require("../lib/logger");
const TOKEN_PATH = (0, path_1.join)((0, keys_1.getSentinelDir)(), 'token.json');
// ==================== Auth ====================
/**
 * POST /v1/auth — 用 Ed25519 challenge-response 换 JWT
 */
async function authGetToken(serverURL) {
    const challenge = (0, keys_1.authChallenge)();
    const url = `${serverURL.replace(/\/$/, '')}/v1/auth`;
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            ...challenge,
            deviceName: `${process.env.USER ?? 'unknown'}@${require('os').hostname()}`,
            deviceType: 'mac',
        }),
    });
    if (!res.ok) {
        const body = await res.text();
        throw new Error(`Auth failed (${res.status}): ${body}`);
    }
    const json = (await res.json());
    if (!json.success) {
        throw new Error('Auth response: success=false');
    }
    const tokenFile = {
        serverURL: serverURL.replace(/\/$/, ''),
        token: json.data.token,
        deviceId: json.data.deviceId,
        expiresAt: new Date(Date.now() + json.data.expiresIn * 1000).toISOString(),
    };
    (0, fs_1.writeFileSync)(TOKEN_PATH, JSON.stringify(tokenFile, null, 2), { mode: 0o600 });
    logger_1.log.info(`Authenticated. Device ID: ${tokenFile.deviceId}`);
    return tokenFile;
}
// ==================== Token Storage ====================
/**
 * 读取已保存的 JWT — 如果过期或不存在返回 null
 */
function loadToken() {
    if (!(0, fs_1.existsSync)(TOKEN_PATH))
        return null;
    try {
        const raw = JSON.parse((0, fs_1.readFileSync)(TOKEN_PATH, 'utf-8'));
        if (new Date(raw.expiresAt) < new Date()) {
            logger_1.log.warn('Token expired, re-auth needed');
            return null;
        }
        return raw;
    }
    catch {
        return null;
    }
}
/**
 * 确保有有效 token — 没有则走 auth 流程
 */
async function ensureToken(serverURL) {
    const existing = loadToken();
    if (existing && existing.serverURL === serverURL.replace(/\/$/, '')) {
        return existing;
    }
    return authGetToken(serverURL);
}
/**
 * 获取已存 serverURL（如果有）
 */
function getStoredServerURL() {
    return loadToken()?.serverURL ?? null;
}
/**
 * 清除 token
 */
function clearToken() {
    const { unlinkSync } = require('fs');
    if ((0, fs_1.existsSync)(TOKEN_PATH)) {
        unlinkSync(TOKEN_PATH);
    }
}
//# sourceMappingURL=client.js.map