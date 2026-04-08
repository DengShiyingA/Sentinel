import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';

const SESSIONS_DIR = join(getSentinelDir(), 'sessions');

export interface SessionEvent {
  type: 'tool_use' | 'tool_result' | 'notification' | 'stop' | 'user_message' | 'claude_response';
  toolName?: string;
  filePath?: string;
  summary?: string;
  decision?: string;
  message?: string;
  stopReason?: string;
  timestamp: string;
}

export interface Session {
  id: string;
  startedAt: string;
  endedAt?: string;
  events: SessionEvent[];
  stats: { tools: number; approved: number; blocked: number };
}

let currentSession: Session | null = null;

export function startSession(): Session {
  if (!existsSync(SESSIONS_DIR)) mkdirSync(SESSIONS_DIR, { recursive: true });

  currentSession = {
    id: new Date().toISOString().replace(/[:.]/g, '-'),
    startedAt: new Date().toISOString(),
    events: [],
    stats: { tools: 0, approved: 0, blocked: 0 },
  };
  return currentSession;
}

export function addSessionEvent(event: SessionEvent): void {
  if (!currentSession) return;
  currentSession.events.push(event);

  if (event.type === 'tool_use') currentSession.stats.tools++;
  if (event.decision === 'allowed' || event.decision === 'auto_allow') currentSession.stats.approved++;
  if (event.decision === 'blocked') currentSession.stats.blocked++;
}

export function endSession(): void {
  if (!currentSession) return;
  currentSession.endedAt = new Date().toISOString();

  // Save to file
  const path = join(SESSIONS_DIR, `${currentSession.id}.json`);
  writeFileSync(path, JSON.stringify(currentSession, null, 2));
  currentSession = null;
}

export function getCurrentSession(): Session | null {
  return currentSession;
}

/** List recent sessions (newest first) */
export function listSessions(limit = 10): { id: string; startedAt: string; events: number; stats: Session['stats'] }[] {
  if (!existsSync(SESSIONS_DIR)) return [];

  const files = require('fs').readdirSync(SESSIONS_DIR) as string[];
  return files
    .filter((f: string) => f.endsWith('.json'))
    .sort()
    .reverse()
    .slice(0, limit)
    .map((f: string) => {
      try {
        const s = JSON.parse(readFileSync(join(SESSIONS_DIR, f), 'utf-8')) as Session;
        return { id: s.id, startedAt: s.startedAt, events: s.events.length, stats: s.stats };
      } catch {
        return null;
      }
    })
    .filter(Boolean) as any[];
}
