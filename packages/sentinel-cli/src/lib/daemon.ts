import { spawn } from 'child_process';
import { existsSync, readFileSync, writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';
import { log } from './logger';

const PID_PATH = join(getSentinelDir(), 'daemon.pid');

function savePid(pid: number): void {
  writeFileSync(PID_PATH, String(pid));
}

function readPid(): number | null {
  if (!existsSync(PID_PATH)) return null;
  try {
    const pid = parseInt(readFileSync(PID_PATH, 'utf-8').trim(), 10);
    return isNaN(pid) ? null : pid;
  } catch {
    return null;
  }
}

function isProcessRunning(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

export function daemonStart(mode: string, port: number, serverUrl?: string): void {
  // Check if already running
  const existingPid = readPid();
  if (existingPid && isProcessRunning(existingPid)) {
    log.warn(`Daemon already running (PID: ${existingPid})`);
    return;
  }

  // Build args
  const args = ['start', '--mode', mode, '--port', String(port)];
  if (serverUrl) args.push('--server', serverUrl);

  // Find the CLI entry point
  const script = join(__dirname, 'index.js');

  const child = spawn('node', [script, ...args], {
    detached: true,
    stdio: 'ignore',
    env: { ...process.env },
  });

  child.unref();

  if (child.pid) {
    savePid(child.pid);
    log.success(`Sentinel daemon started (PID: ${child.pid})`);
    log.dim(`  Hook server: localhost:${port}`);
    log.dim(`  Mode: ${mode}`);
    log.dim(`  PID file: ${PID_PATH}`);
  } else {
    log.error('Failed to start daemon');
  }
}

export function daemonStop(): void {
  const pid = readPid();
  if (!pid) {
    log.warn('No daemon PID file found');
    return;
  }

  if (!isProcessRunning(pid)) {
    log.warn(`Daemon not running (stale PID: ${pid})`);
    try { unlinkSync(PID_PATH); } catch {}
    return;
  }

  try {
    process.kill(pid, 'SIGTERM');
    log.success(`Daemon stopped (PID: ${pid})`);
    try { unlinkSync(PID_PATH); } catch {}
  } catch (err) {
    log.error(`Failed to stop daemon: ${(err as Error).message}`);
  }
}

export async function daemonStatus(): Promise<void> {
  const pid = readPid();

  if (!pid) {
    log.warn('No daemon running (no PID file)');
    return;
  }

  const running = isProcessRunning(pid);
  if (!running) {
    log.warn(`Daemon not running (stale PID: ${pid})`);
    try { unlinkSync(PID_PATH); } catch {}
    return;
  }

  log.success(`Daemon running (PID: ${pid})`);

  // Check hook server
  try {
    const res = await fetch('http://localhost:7749/status');
    const data = (await res.json()) as Record<string, unknown>;
    log.info(`  Mode: ${data.mode}`);
    log.info(`  Connected: ${data.connected}`);
    log.info(`  Pending: ${data.pendingRequests}`);
    log.info(`  Uptime: ${Math.round(data.uptime as number)}s`);
  } catch {
    log.warn('  Hook server not responding');
  }
}

export function daemonRestart(mode: string, port: number, serverUrl?: string): void {
  daemonStop();
  // Small delay for port release
  setTimeout(() => daemonStart(mode, port, serverUrl), 500);
}
