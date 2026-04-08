/**
 * 将 Sentinel hook 注入到 ~/.claude/settings.json
 *
 * 添加 PreToolUse HTTP hook 指向 http://localhost:7749/hook
 */
export declare function installHook(port?: number): void;
/**
 * 从 settings.json 移除 Sentinel hook
 */
export declare function uninstallHook(port?: number): void;
