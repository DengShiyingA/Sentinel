import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { authChallenge, getSentinelDir } from '../crypto/keys';
import { log } from '../lib/logger';

const TOKEN_PATH = join(getSentinelDir(), 'token.json');

interface TokenFile {
  serverURL: string;
  token: string;
  deviceId: string;
  expiresAt: string;
}

// ==================== Auth ====================

/**
 * POST /v1/auth — 用 Ed25519 challenge-response 换 JWT
 */
export async function authGetToken(serverURL: string): Promise<TokenFile> {
  const challenge = authChallenge();

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

  const json = (await res.json()) as {
    success: boolean;
    data: { token: string; deviceId: string; expiresIn: number };
  };

  if (!json.success) {
    throw new Error('Auth response: success=false');
  }

  const tokenFile: TokenFile = {
    serverURL: serverURL.replace(/\/$/, ''),
    token: json.data.token,
    deviceId: json.data.deviceId,
    expiresAt: new Date(Date.now() + json.data.expiresIn * 1000).toISOString(),
  };

  writeFileSync(TOKEN_PATH, JSON.stringify(tokenFile, null, 2), { mode: 0o600 });
  log.info(`Authenticated. Device ID: ${tokenFile.deviceId}`);

  return tokenFile;
}

// ==================== Token Storage ====================

/**
 * 读取已保存的 JWT — 如果过期或不存在返回 null
 */
export function loadToken(): TokenFile | null {
  if (!existsSync(TOKEN_PATH)) return null;

  try {
    const raw = JSON.parse(readFileSync(TOKEN_PATH, 'utf-8')) as TokenFile;
    if (new Date(raw.expiresAt) < new Date()) {
      log.warn('Token expired, re-auth needed');
      return null;
    }
    return raw;
  } catch {
    return null;
  }
}

/**
 * 确保有有效 token — 没有则走 auth 流程
 */
export async function ensureToken(serverURL: string): Promise<TokenFile> {
  const existing = loadToken();
  if (existing && existing.serverURL === serverURL.replace(/\/$/, '')) {
    return existing;
  }
  return authGetToken(serverURL);
}

/**
 * 获取已存 serverURL（如果有）
 */
export function getStoredServerURL(): string | null {
  return loadToken()?.serverURL ?? null;
}

/**
 * 清除 token
 */
export function clearToken(): void {
  const { unlinkSync } = require('fs');
  if (existsSync(TOKEN_PATH)) {
    unlinkSync(TOKEN_PATH);
  }
}
