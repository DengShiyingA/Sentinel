"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pending = void 0;
const logger_1 = require("../lib/logger");
const TIMEOUT_MS = 120_000; // 120s
/**
 * 管理等待决策的审批请求
 * 每个请求对应一个 Promise — Socket 收到 decision 事件时 resolve
 */
class PendingStore {
    requests = new Map();
    /**
     * 注册一个等待中的请求，返回 Promise<action>
     * 超时自动 resolve 为 'timeout'
     */
    waitForDecision(requestId, toolName) {
        return new Promise((resolve) => {
            const timer = setTimeout(() => {
                if (this.requests.has(requestId)) {
                    this.requests.delete(requestId);
                    logger_1.log.warn(`Request ${requestId} timed out (${TIMEOUT_MS / 1000}s)`);
                    resolve('timeout');
                }
            }, TIMEOUT_MS);
            this.requests.set(requestId, {
                requestId,
                toolName,
                createdAt: Date.now(),
                resolve,
                timer,
            });
        });
    }
    /**
     * 收到决策时调用 — 从 Socket decision 事件触发
     */
    resolve(requestId, action) {
        const entry = this.requests.get(requestId);
        if (!entry) {
            logger_1.log.debug(`Decision for unknown request: ${requestId}`);
            return;
        }
        clearTimeout(entry.timer);
        this.requests.delete(requestId);
        entry.resolve(action);
    }
    /**
     * 当前等待中的请求数量
     */
    get size() {
        return this.requests.size;
    }
    /**
     * 清理所有请求（shutdown 时使用）
     */
    clear() {
        for (const [, entry] of this.requests) {
            clearTimeout(entry.timer);
            entry.resolve('timeout');
        }
        this.requests.clear();
    }
}
exports.pending = new PendingStore();
//# sourceMappingURL=pending.js.map