type DecisionAction = 'allowed' | 'blocked' | 'timeout';
/**
 * 管理等待决策的审批请求
 * 每个请求对应一个 Promise — Socket 收到 decision 事件时 resolve
 */
declare class PendingStore {
    private requests;
    /**
     * 注册一个等待中的请求，返回 Promise<action>
     * 超时自动 resolve 为 'timeout'
     */
    waitForDecision(requestId: string, toolName: string): Promise<DecisionAction>;
    /**
     * 收到决策时调用 — 从 Socket decision 事件触发
     */
    resolve(requestId: string, action: DecisionAction): void;
    /**
     * 当前等待中的请求数量
     */
    get size(): number;
    /**
     * 清理所有请求（shutdown 时使用）
     */
    clear(): void;
}
export declare const pending: PendingStore;
export {};
