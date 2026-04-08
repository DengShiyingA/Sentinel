interface TokenFile {
    serverURL: string;
    token: string;
    deviceId: string;
    expiresAt: string;
}
/**
 * POST /v1/auth — 用 Ed25519 challenge-response 换 JWT
 */
export declare function authGetToken(serverURL: string): Promise<TokenFile>;
/**
 * 读取已保存的 JWT — 如果过期或不存在返回 null
 */
export declare function loadToken(): TokenFile | null;
/**
 * 确保有有效 token — 没有则走 auth 流程
 */
export declare function ensureToken(serverURL: string): Promise<TokenFile>;
/**
 * 获取已存 serverURL（如果有）
 */
export declare function getStoredServerURL(): string | null;
/**
 * 清除 token
 */
export declare function clearToken(): void;
export {};
