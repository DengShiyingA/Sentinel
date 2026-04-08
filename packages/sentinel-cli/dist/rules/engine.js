"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRules = getRules;
exports.matchRules = matchRules;
exports.riskToLevel = riskToLevel;
const fs_1 = require("fs");
const path_1 = require("path");
const keys_1 = require("../crypto/keys");
const logger_1 = require("../lib/logger");
// ==================== Default Rules ====================
const DEFAULT_RULES = [
    {
        id: 'builtin-bash-high',
        toolPattern: 'Bash',
        pathPattern: null,
        risk: 'require_faceid',
        priority: 10,
        description: 'Bash commands require Face ID',
    },
    {
        id: 'builtin-write-confirm',
        toolPattern: 'Write',
        pathPattern: null,
        risk: 'require_confirm',
        priority: 20,
        description: 'File writes require confirmation',
    },
    {
        id: 'builtin-edit-confirm',
        toolPattern: 'Edit',
        pathPattern: null,
        risk: 'require_confirm',
        priority: 20,
        description: 'File edits require confirmation',
    },
    {
        id: 'builtin-tmp-allow',
        toolPattern: '*',
        pathPattern: '/tmp/**',
        risk: 'auto_allow',
        priority: 5,
        description: 'Auto-allow /tmp operations',
    },
    {
        id: 'builtin-env-faceid',
        toolPattern: '*',
        pathPattern: '**/.env*',
        risk: 'require_faceid',
        priority: 1,
        description: '.env files require Face ID',
    },
    {
        id: 'builtin-read-allow',
        toolPattern: 'Read',
        pathPattern: null,
        risk: 'auto_allow',
        priority: 50,
        description: 'Auto-allow file reads',
    },
    {
        id: 'builtin-glob-allow',
        toolPattern: 'Glob',
        pathPattern: null,
        risk: 'auto_allow',
        priority: 50,
        description: 'Auto-allow glob searches',
    },
    {
        id: 'builtin-grep-allow',
        toolPattern: 'Grep',
        pathPattern: null,
        risk: 'auto_allow',
        priority: 50,
        description: 'Auto-allow grep searches',
    },
];
// ==================== Rules File ====================
const RULES_PATH = (0, path_1.join)((0, keys_1.getSentinelDir)(), 'rules.json');
function loadRules() {
    if (!(0, fs_1.existsSync)(RULES_PATH)) {
        (0, fs_1.writeFileSync)(RULES_PATH, JSON.stringify(DEFAULT_RULES, null, 2));
        return DEFAULT_RULES;
    }
    try {
        return JSON.parse((0, fs_1.readFileSync)(RULES_PATH, 'utf-8'));
    }
    catch {
        return DEFAULT_RULES;
    }
}
function getRules() {
    return loadRules();
}
// ==================== Glob Matching ====================
/**
 * 简单 glob 匹配，支持 * 和 **
 */
function globMatch(pattern, value) {
    // Escape regex special chars, then convert glob patterns
    const regex = pattern
        .replace(/[.+^${}()|[\]\\]/g, '\\$&')
        .replace(/\*\*/g, '{{DOUBLESTAR}}')
        .replace(/\*/g, '[^/]*')
        .replace(/{{DOUBLESTAR}}/g, '.*');
    return new RegExp(`^${regex}$`).test(value);
}
// ==================== Engine ====================
/**
 * 匹配工具调用 against 规则列表
 *
 * @param toolName   - 工具名，e.g. "Bash", "Write", "Edit"
 * @param filePath   - 文件路径（可选），e.g. "/tmp/foo.txt"
 * @returns          - 匹配结果：{ matched, rule, action }
 */
function matchRules(toolName, filePath) {
    const rules = loadRules().sort((a, b) => a.priority - b.priority);
    for (const rule of rules) {
        let toolMatch = true;
        let pathMatch = true;
        // Tool pattern
        if (rule.toolPattern) {
            toolMatch = globMatch(rule.toolPattern, toolName);
        }
        // Path pattern — 只有当规则有 pathPattern 且调用有 filePath 时才匹配
        if (rule.pathPattern) {
            if (!filePath) {
                pathMatch = false; // 规则要求路径但调用没有路径
            }
            else {
                pathMatch = globMatch(rule.pathPattern, filePath);
            }
        }
        if (toolMatch && pathMatch) {
            logger_1.log.debug(`Rule matched: [${rule.id}] ${rule.description} → ${rule.risk}`);
            return { matched: true, rule, action: rule.risk };
        }
    }
    // 无匹配 → 默认需要确认
    return { matched: false, rule: null, action: 'require_confirm' };
}
/**
 * 将工具调用的风险等级映射为 server riskLevel
 */
function riskToLevel(action) {
    switch (action) {
        case 'auto_allow': return 'low';
        case 'require_confirm': return 'medium';
        case 'require_faceid': return 'high';
    }
}
//# sourceMappingURL=engine.js.map