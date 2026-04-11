import { log } from '../lib/logger';

type DecisionAction = 'allowed' | 'blocked' | 'timeout';

/**
 * Result of a pending approval. `modifiedInput` is set when the user edited
 * the tool arguments on the phone before approving — in that case the hook
 * handler must return `updatedInput` to Claude Code so the tool runs with
 * the modified args instead of the original.
 */
export interface DecisionResult {
  action: DecisionAction;
  modifiedInput?: Record<string, unknown>;
}

interface PendingRequest {
  requestId: string;
  toolName: string;
  createdAt: number;
  resolve: (result: DecisionResult) => void;
  timer: NodeJS.Timeout;
}

const TIMEOUT_MS = 120_000; // 120s

/**
 * 管理等待决策的审批请求
 * 每个请求对应一个 Promise — Socket 收到 decision 事件时 resolve
 */
class PendingStore {
  private requests = new Map<string, PendingRequest>();

  /**
   * 注册一个等待中的请求，返回 Promise<DecisionResult>
   * 超时自动 resolve 为 { action: 'timeout' }
   */
  waitForDecision(requestId: string, toolName: string): Promise<DecisionResult> {
    return new Promise<DecisionResult>((resolve) => {
      const timer = setTimeout(() => {
        if (this.requests.has(requestId)) {
          this.requests.delete(requestId);
          log.warn(`Request ${requestId} timed out (${TIMEOUT_MS / 1000}s)`);
          resolve({ action: 'timeout' });
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
   * 收到决策时调用 — 从 Socket decision 事件触发.
   * `modifiedInput` is optional; when present the hook handler returns it as
   * `updatedInput` so Claude Code runs the modified args instead of the original.
   */
  resolve(requestId: string, action: DecisionAction, modifiedInput?: Record<string, unknown>): void {
    const entry = this.requests.get(requestId);
    if (!entry) {
      log.debug(`Decision for unknown request: ${requestId}`);
      return;
    }

    clearTimeout(entry.timer);
    this.requests.delete(requestId);
    entry.resolve({ action, modifiedInput });
  }

  /**
   * 当前等待中的请求数量
   */
  get size(): number {
    return this.requests.size;
  }

  /**
   * 清理所有请求（shutdown 时使用）
   */
  clear(): void {
    for (const [, entry] of this.requests) {
      clearTimeout(entry.timer);
      entry.resolve({ action: 'timeout' });
    }
    this.requests.clear();
  }
}

export const pending = new PendingStore();
