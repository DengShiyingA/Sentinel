"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.installHook = installHook;
exports.uninstallHook = uninstallHook;
const fs_1 = require("fs");
const path_1 = require("path");
const os_1 = require("os");
const logger_1 = require("../lib/logger");
const CLAUDE_DIR = (0, path_1.join)((0, os_1.homedir)(), '.claude');
const SETTINGS_PATH = (0, path_1.join)(CLAUDE_DIR, 'settings.json');
/**
 * 将 Sentinel hook 注入到 ~/.claude/settings.json
 *
 * 添加 PreToolUse HTTP hook 指向 http://localhost:7749/hook
 */
function installHook(port = 7749) {
    if (!(0, fs_1.existsSync)(CLAUDE_DIR)) {
        (0, fs_1.mkdirSync)(CLAUDE_DIR, { recursive: true });
    }
    let settings = {};
    if ((0, fs_1.existsSync)(SETTINGS_PATH)) {
        try {
            settings = JSON.parse((0, fs_1.readFileSync)(SETTINGS_PATH, 'utf-8'));
        }
        catch {
            logger_1.log.warn('Could not parse existing settings.json, creating new one');
        }
    }
    const hookURL = `http://localhost:${port}/hook`;
    // Initialize hooks structure
    if (!settings.hooks) {
        settings.hooks = {};
    }
    if (!Array.isArray(settings.hooks.PreToolUse)) {
        settings.hooks.PreToolUse = [];
    }
    // Check if already installed
    const existing = settings.hooks.PreToolUse.find((h) => h.type === 'http' && h.url.includes('localhost') && h.url.includes(String(port)));
    if (existing) {
        logger_1.log.info('Sentinel hook already installed in Claude Code settings');
        return;
    }
    settings.hooks.PreToolUse.push({
        type: 'http',
        url: hookURL,
    });
    (0, fs_1.writeFileSync)(SETTINGS_PATH, JSON.stringify(settings, null, 2));
    logger_1.log.success(`Hook installed: ${hookURL}`);
    logger_1.log.dim(`  Config: ${SETTINGS_PATH}`);
}
/**
 * 从 settings.json 移除 Sentinel hook
 */
function uninstallHook(port = 7749) {
    if (!(0, fs_1.existsSync)(SETTINGS_PATH))
        return;
    try {
        const settings = JSON.parse((0, fs_1.readFileSync)(SETTINGS_PATH, 'utf-8'));
        if (Array.isArray(settings.hooks?.PreToolUse)) {
            settings.hooks.PreToolUse = settings.hooks.PreToolUse.filter((h) => !(h.type === 'http' && h.url.includes(String(port))));
            (0, fs_1.writeFileSync)(SETTINGS_PATH, JSON.stringify(settings, null, 2));
            logger_1.log.success('Sentinel hook removed');
        }
    }
    catch {
        logger_1.log.warn('Could not update settings.json');
    }
}
//# sourceMappingURL=setup.js.map