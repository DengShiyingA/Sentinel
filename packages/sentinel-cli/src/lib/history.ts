import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';

const MAX_ENTRIES = 100;
const HISTORY_PATH = join(getSentinelDir(), 'logs.json');

export interface LogEntry {
  id: string;
  toolName: string;
  filePath: string | null;
  riskLevel: string;
  decision: string;   // 'allowed' | 'blocked' | 'timeout' | 'auto_allow' | 'offline'
  timestamp: string;   // ISO 8601
  result?: string;     // 'success' | 'error' (for PostToolUse)
  summary?: string;    // human-readable summary
}

function loadHistory(): LogEntry[] {
  if (!existsSync(HISTORY_PATH)) return [];
  try {
    return JSON.parse(readFileSync(HISTORY_PATH, 'utf-8')) as LogEntry[];
  } catch {
    return [];
  }
}

function saveHistory(entries: LogEntry[]): void {
  writeFileSync(HISTORY_PATH, JSON.stringify(entries, null, 2), { mode: 0o600 });
}

export function appendLog(entry: LogEntry): void {
  const history = loadHistory();
  history.unshift(entry); // newest first
  if (history.length > MAX_ENTRIES) history.length = MAX_ENTRIES;
  saveHistory(history);
}

export function getHistory(): LogEntry[] {
  return loadHistory();
}

export interface DayStats {
  allowed: number;
  blocked: number;
  timeout: number;
  autoAllow: number;
  offline: number;
  total: number;
  lastRequestTime: string | null;
}

export function getTodayStats(): DayStats {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const entries = loadHistory().filter((e) => e.timestamp.startsWith(today));

  const stats: DayStats = {
    allowed: 0, blocked: 0, timeout: 0, autoAllow: 0, offline: 0, total: entries.length,
    lastRequestTime: entries[0]?.timestamp ?? null,
  };

  for (const e of entries) {
    switch (e.decision) {
      case 'allowed': stats.allowed++; break;
      case 'blocked': stats.blocked++; break;
      case 'timeout': stats.timeout++; break;
      case 'auto_allow': stats.autoAllow++; break;
      case 'offline': stats.offline++; break;
    }
  }
  return stats;
}
