import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';

const OVERRIDES_PATH = join(getSentinelDir(), 'overrides.json');

interface Overrides {
  blockAll: boolean;
  allowAll: boolean;
  blockUntil: string | null;  // ISO timestamp
  allowUntil: string | null;  // ISO timestamp
}

function loadOverrides(): Overrides {
  if (!existsSync(OVERRIDES_PATH)) return { blockAll: false, allowAll: false, blockUntil: null, allowUntil: null };
  try {
    return JSON.parse(readFileSync(OVERRIDES_PATH, 'utf-8'));
  } catch {
    return { blockAll: false, allowAll: false, blockUntil: null, allowUntil: null };
  }
}

function saveOverrides(o: Overrides): void {
  writeFileSync(OVERRIDES_PATH, JSON.stringify(o, null, 2));
}

function isExpired(until: string | null): boolean {
  if (!until) return false;
  return new Date(until) <= new Date();
}

/** Check current override state (auto-clears expired) */
export function getOverrideState(): { blockAll: boolean; allowAll: boolean } {
  const o = loadOverrides();
  let changed = false;

  if (o.blockAll && o.blockUntil && isExpired(o.blockUntil)) {
    o.blockAll = false;
    o.blockUntil = null;
    changed = true;
  }
  if (o.allowAll && o.allowUntil && isExpired(o.allowUntil)) {
    o.allowAll = false;
    o.allowUntil = null;
    changed = true;
  }
  if (changed) saveOverrides(o);

  return { blockAll: o.blockAll, allowAll: o.allowAll };
}

export function setBlockAll(on: boolean, durationMinutes?: number): void {
  const o = loadOverrides();
  o.blockAll = on;
  o.allowAll = false;
  o.allowUntil = null;
  o.blockUntil = on && durationMinutes
    ? new Date(Date.now() + durationMinutes * 60_000).toISOString()
    : null;
  saveOverrides(o);
}

export function setAllowAll(on: boolean, durationMinutes?: number): void {
  const o = loadOverrides();
  o.allowAll = on;
  o.blockAll = false;
  o.blockUntil = null;
  o.allowUntil = on && durationMinutes
    ? new Date(Date.now() + durationMinutes * 60_000).toISOString()
    : null;
  saveOverrides(o);
}

export function getOverrideInfo(): { blockAll: boolean; allowAll: boolean; blockUntil: string | null; allowUntil: string | null } {
  const o = loadOverrides();
  // Check expiry
  getOverrideState();
  const fresh = loadOverrides();
  return fresh;
}
