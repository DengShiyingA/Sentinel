import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { log } from '../lib/logger';

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

  writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
  log.success('Hooks installed (PreToolUse, PostToolUse, Notification, Stop)');
  log.dim(`  Config: ${SETTINGS_PATH}`);
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

    writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
    log.success('All Sentinel hooks removed');
  } catch {
    log.warn('Could not update settings.json');
  }
}
