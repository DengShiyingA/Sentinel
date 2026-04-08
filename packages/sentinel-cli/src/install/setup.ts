import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { log } from '../lib/logger';

const CLAUDE_DIR = join(homedir(), '.claude');
const SETTINGS_PATH = join(CLAUDE_DIR, 'settings.json');

/**
 * Claude Code 2026 hook format:
 * {
 *   "hooks": {
 *     "PreToolUse": [{
 *       "hooks": [{
 *         "type": "command",
 *         "command": "curl -s -X POST http://localhost:7749/hook -H 'Content-Type: application/json' -d @-"
 *       }]
 *     }]
 *   }
 * }
 */
export function installHook(port: number = 7749): void {
  if (!existsSync(CLAUDE_DIR)) {
    mkdirSync(CLAUDE_DIR, { recursive: true });
  }

  let settings: Record<string, any> = {};

  if (existsSync(SETTINGS_PATH)) {
    try {
      settings = JSON.parse(readFileSync(SETTINGS_PATH, 'utf-8'));
    } catch {
      log.warn('Could not parse existing settings.json, creating new one');
    }
  }

  const curlCmd = `curl -s -X POST http://localhost:${port}/hook -H 'Content-Type: application/json' -d @-`;

  if (!settings.hooks) settings.hooks = {};

  // Check if already installed (any format)
  const existing = JSON.stringify(settings.hooks);
  if (existing.includes(`localhost:${port}/hook`)) {
    log.info('Sentinel hook already installed');
    return;
  }

  // Write correct 2026 format
  if (!Array.isArray(settings.hooks.PreToolUse)) {
    settings.hooks.PreToolUse = [];
  }

  settings.hooks.PreToolUse.push({
    hooks: [{
      type: 'command',
      command: curlCmd,
    }],
  });

  writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
  log.success('Hook installed');
  log.dim(`  Command: ${curlCmd}`);
  log.dim(`  Config:  ${SETTINGS_PATH}`);
}

export function uninstallHook(port: number = 7749): void {
  if (!existsSync(SETTINGS_PATH)) return;

  try {
    const settings = JSON.parse(readFileSync(SETTINGS_PATH, 'utf-8'));

    if (Array.isArray(settings.hooks?.PreToolUse)) {
      settings.hooks.PreToolUse = settings.hooks.PreToolUse.filter(
        (entry: any) => {
          const hooks = entry?.hooks;
          if (!Array.isArray(hooks)) return true;
          return !hooks.some((h: any) =>
            h.type === 'command' && typeof h.command === 'string' && h.command.includes(`localhost:${port}`),
          );
        },
      );
      writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
      log.success('Sentinel hook removed');
    }
  } catch {
    log.warn('Could not update settings.json');
  }
}
