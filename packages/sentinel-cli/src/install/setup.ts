import { existsSync, mkdirSync, readFileSync, writeFileSync, copyFileSync, renameSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { log } from '../lib/logger';

/**
 * Atomically write JSON to a settings file with backup of the previous version.
 * Backup goes to <path>.bak (overwritten on each install).
 * Write goes to <path>.tmp then renames to <path> so a crash mid-write
 * never leaves Claude with a corrupted settings.json.
 */
function safeWriteJson(path: string, data: unknown): void {
  if (existsSync(path)) {
    try { copyFileSync(path, `${path}.bak`); } catch { /* ignore */ }
  }
  const tmp = `${path}.tmp`;
  writeFileSync(tmp, JSON.stringify(data, null, 2));
  renameSync(tmp, path);
}

const CLAUDE_DIR = join(homedir(), '.claude');
const SETTINGS_PATH = join(CLAUDE_DIR, 'settings.json');

const HOOK_TYPES = ['PreToolUse', 'PostToolUse', 'Notification', 'Stop'] as const;

function makeHookEntry(port: number, endpoint: string) {
  return {
    hooks: [{
      type: 'command',
      command: `curl -s -X POST http://localhost:${port}${endpoint} -H 'Content-Type: application/json' -d @-`,
    }],
  };
}

export function installHook(port: number = 7749): void {
  if (!existsSync(CLAUDE_DIR)) {
    mkdirSync(CLAUDE_DIR, { recursive: true });
  }

  let settings: Record<string, any> = {};
  if (existsSync(SETTINGS_PATH)) {
    try { settings = JSON.parse(readFileSync(SETTINGS_PATH, 'utf-8')); } catch {}
  }

  // Check if already installed
  const existing = JSON.stringify(settings.hooks ?? {});
  if (existing.includes(`localhost:${port}/hook`)) {
    log.info('Sentinel hooks already installed');
    return;
  }

  if (!settings.hooks) settings.hooks = {};

  // PreToolUse → /hook (approval), others → /event (fire-and-forget)
  const hookMap: Record<string, string> = {
    PreToolUse: '/hook',
    PostToolUse: '/event',
    Notification: '/event',
    Stop: '/event',
  };

  for (const [hookType, endpoint] of Object.entries(hookMap)) {
    if (!Array.isArray(settings.hooks[hookType])) {
      settings.hooks[hookType] = [];
    }
    settings.hooks[hookType].push(makeHookEntry(port, endpoint));
  }

  safeWriteJson(SETTINGS_PATH, settings);
  log.success('Hooks installed (PreToolUse, PostToolUse, Notification, Stop)');
  log.dim(`  Config: ${SETTINGS_PATH}`);
  if (existsSync(`${SETTINGS_PATH}.bak`)) log.dim(`  Backup: ${SETTINGS_PATH}.bak`);
}

export function uninstallHook(port: number = 7749): void {
  if (!existsSync(SETTINGS_PATH)) return;

  try {
    const settings = JSON.parse(readFileSync(SETTINGS_PATH, 'utf-8'));
    if (!settings.hooks) return;

    for (const hookType of Object.keys(settings.hooks)) {
      if (Array.isArray(settings.hooks[hookType])) {
        settings.hooks[hookType] = settings.hooks[hookType].filter(
          (entry: any) => {
            const hooks = entry?.hooks;
            if (!Array.isArray(hooks)) return true;
            return !hooks.some((h: any) =>
              h.type === 'command' && typeof h.command === 'string' && h.command.includes(`localhost:${port}`),
            );
          },
        );
      }
    }

    safeWriteJson(SETTINGS_PATH, settings);
    log.success('All Sentinel hooks removed');
  } catch {
    log.warn('Could not update settings.json');
  }
}
