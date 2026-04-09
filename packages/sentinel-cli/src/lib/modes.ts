import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';

/**
 * Permission modes (better than Happy's 4 modes):
 *
 * strict   — Every non-read tool needs approval (default)
 * relaxed  — Only Bash and destructive ops need approval
 * yolo     — All auto-approve, but everything is logged
 * plan     — Like strict, but groups related calls
 * lockdown — Block everything (same as sentinel block on)
 */

export type PermissionMode = 'strict' | 'relaxed' | 'yolo' | 'plan' | 'lockdown';

const MODES_PATH = join(getSentinelDir(), 'mode.json');

interface ModeConfig {
  mode: PermissionMode;
  changedAt: string;
}

function loadMode(): ModeConfig {
  if (!existsSync(MODES_PATH)) return { mode: 'strict', changedAt: new Date().toISOString() };
  try {
    return JSON.parse(readFileSync(MODES_PATH, 'utf-8'));
  } catch {
    return { mode: 'strict', changedAt: new Date().toISOString() };
  }
}

export function getMode(): PermissionMode {
  return loadMode().mode;
}

export function setMode(mode: PermissionMode): void {
  writeFileSync(MODES_PATH, JSON.stringify({ mode, changedAt: new Date().toISOString() }, null, 2), { mode: 0o600 });
}

export function getModeInfo(): ModeConfig {
  return loadMode();
}

/** Check if a tool should be auto-allowed based on current mode */
export function shouldAutoAllow(toolName: string): 'auto_allow' | 'require' | 'block' {
  const mode = getMode();

  switch (mode) {
    case 'lockdown':
      return 'block';

    case 'yolo':
      return 'auto_allow';

    case 'relaxed':
      // Only Bash and destructive ops need approval
      if (['Bash', 'Delete'].includes(toolName)) return 'require';
      return 'auto_allow';

    case 'plan':
    case 'strict':
    default:
      return 'require'; // Let the rule engine decide
  }
}

export const MODE_DESCRIPTIONS: Record<PermissionMode, string> = {
  strict: 'Every write/bash needs approval (default)',
  relaxed: 'Only bash & destructive ops need approval',
  yolo: 'Auto-approve everything (logged)',
  plan: 'Strict + group related operations',
  lockdown: 'Block all operations',
};

export const ALL_MODES: PermissionMode[] = ['strict', 'relaxed', 'yolo', 'plan', 'lockdown'];
