import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { log } from '../lib/logger';

const CLAUDE_DIR = join(homedir(), '.claude');
const SETTINGS_PATH = join(CLAUDE_DIR, 'settings.json');

interface ClaudeSettings {
  hooks?: {
    PreToolUse?: Array<{
      type: string;
      url: string;
    }>;
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

/**
 * 将 Sentinel hook 注入到 ~/.claude/settings.json
 *
 * 添加 PreToolUse HTTP hook 指向 http://localhost:7749/hook
 */
export function installHook(port: number = 7749): void {
  if (!existsSync(CLAUDE_DIR)) {
    mkdirSync(CLAUDE_DIR, { recursive: true });
  }

  let settings: ClaudeSettings = {};

  if (existsSync(SETTINGS_PATH)) {
    try {
      settings = JSON.parse(readFileSync(SETTINGS_PATH, 'utf-8'));
    } catch {
      log.warn('Could not parse existing settings.json, creating new one');
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
  const existing = settings.hooks.PreToolUse.find(
    (h) => h.type === 'http' && h.url.includes('localhost') && h.url.includes(String(port)),
  );

  if (existing) {
    log.info('Sentinel hook already installed in Claude Code settings');
    return;
  }

  settings.hooks.PreToolUse.push({
    type: 'http',
    url: hookURL,
  });

  writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
  log.success(`Hook installed: ${hookURL}`);
  log.dim(`  Config: ${SETTINGS_PATH}`);
}

/**
 * 从 settings.json 移除 Sentinel hook
 */
export function uninstallHook(port: number = 7749): void {
  if (!existsSync(SETTINGS_PATH)) return;

  try {
    const settings: ClaudeSettings = JSON.parse(readFileSync(SETTINGS_PATH, 'utf-8'));

    if (Array.isArray(settings.hooks?.PreToolUse)) {
      settings.hooks!.PreToolUse = settings.hooks!.PreToolUse.filter(
        (h) => !(h.type === 'http' && h.url.includes(String(port))),
      );
      writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
      log.success('Sentinel hook removed');
    }
  } catch {
    log.warn('Could not update settings.json');
  }
}
