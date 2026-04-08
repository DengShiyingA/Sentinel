import { spawn } from 'child_process';
import { existsSync, readFileSync, writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { getSentinelDir } from '../crypto/keys';
import { log } from './logger';

const PID_PATH = join(getSentinelDir(), 'daemon.pid');
const LOCK_PATH = join(getSentinelDir(), 'daemon.lock');
const LOG_PATH = join(getSentinelDir(), 'daemon.log');

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
  try { process.kill(pid, 0); return true; } catch { return false; }
}

function acquireLock(): boolean {
  if (existsSync(LOCK_PATH)) {
    const lockPid = parseInt(readFileSync(LOCK_PATH, 'utf-8').trim(), 10);
    if (!isNaN(lockPid) && isProcessRunning(lockPid)) return false;
    // Stale lock
    try { unlinkSync(LOCK_PATH); } catch {}
  }
  writeFileSync(LOCK_PATH, String(process.pid));
  return true;
}

function releaseLock(): void {
  try { unlinkSync(LOCK_PATH); } catch {}
}

/** Start caffeinate to prevent Mac sleep while daemon runs */
function startCaffeinate(daemonPid: number): void {
  try {
    const caf = spawn('caffeinate', ['-i', '-w', String(daemonPid)], {
      detached: true,
      stdio: 'ignore',
    });
    caf.unref();
    log.dim(`  caffeinate: preventing sleep (PID: ${caf.pid})`);
  } catch {
    // caffeinate not available (Linux)
  }
}

export function daemonStart(mode: string, port: number, serverUrl?: string): void {
  const existingPid = readPid();
  if (existingPid && isProcessRunning(existingPid)) {
    log.warn(`Daemon already running (PID: ${existingPid})`);
    return;
  }

  // Lock file check
  if (!acquireLock()) {
    log.error('Another daemon instance is starting. Remove ~/.sentinel/daemon.lock if stale.');
    return;
  }

  const args = ['start', '--mode', mode, '--port', String(port)];
  if (serverUrl) args.push('--server', serverUrl);

  const script = join(__dirname, 'index.js');
  const out = require('fs').openSync(LOG_PATH, 'a');

  const child = spawn('node', [script, ...args], {
    detached: true,
    stdio: ['ignore', out, out],
    env: { ...process.env, SENTINEL_DAEMON: '1' },
  });

  child.unref();
  releaseLock();

  if (child.pid) {
    savePid(child.pid);
    startCaffeinate(child.pid);
    log.success(`Sentinel daemon started (PID: ${child.pid})`);
    log.dim(`  Hook server: localhost:${port}`);
    log.dim(`  Mode: ${mode}`);
    log.dim(`  Log: ${LOG_PATH}`);
    log.dim(`  PID file: ${PID_PATH}`);
  } else {
    log.error('Failed to start daemon');
  }
}

export function daemonStop(): void {
  const pid = readPid();
  if (!pid) { log.warn('No daemon PID file found'); return; }

  if (!isProcessRunning(pid)) {
    log.warn(`Daemon not running (stale PID: ${pid})`);
    try { unlinkSync(PID_PATH); } catch {}
    return;
  }

  try {
    process.kill(pid, 'SIGTERM');
    // Wait briefly for graceful shutdown
    let tries = 0;
    while (tries < 10 && isProcessRunning(pid)) {
      require('child_process').execSync('sleep 0.2');
      tries++;
    }
    if (isProcessRunning(pid)) process.kill(pid, 'SIGKILL');
    log.success(`Daemon stopped (PID: ${pid})`);
    try { unlinkSync(PID_PATH); } catch {}
    releaseLock();
  } catch (err) {
    log.error(`Failed to stop daemon: ${(err as Error).message}`);
  }
}

export async function daemonStatus(): Promise<void> {
  const pid = readPid();
  if (!pid) { log.warn('No daemon running (no PID file)'); return; }

  const running = isProcessRunning(pid);
  if (!running) {
    log.warn(`Daemon not running (stale PID: ${pid})`);
    try { unlinkSync(PID_PATH); } catch {}
    return;
  }

  log.success(`Daemon running (PID: ${pid})`);

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

  // Show log tail
  if (existsSync(LOG_PATH)) {
    log.dim(`  Log: ${LOG_PATH}`);
  }
}

export function daemonRestart(mode: string, port: number, serverUrl?: string): void {
  daemonStop();
  setTimeout(() => daemonStart(mode, port, serverUrl), 800);
}

/** Generate macOS launchd plist for auto-start */
export function daemonInstallLaunchd(mode: string, port: number): void {
  const plistName = 'com.sentinel.daemon';
  const plistDir = join(homedir(), 'Library', 'LaunchAgents');
  const plistPath = join(plistDir, `${plistName}.plist`);
  const nodePath = process.execPath;
  const scriptPath = join(__dirname, 'index.js');

  const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${plistName}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${nodePath}</string>
    <string>${scriptPath}</string>
    <string>start</string>
    <string>--mode</string>
    <string>${mode}</string>
    <string>--port</string>
    <string>${port}</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>${LOG_PATH}</string>
  <key>StandardErrorPath</key><string>${LOG_PATH}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>SENTINEL_DAEMON</key><string>1</string>
  </dict>
</dict>
</plist>`;

  writeFileSync(plistPath, plist);
  log.success(`LaunchAgent installed: ${plistPath}`);
  log.dim(`  Will auto-start on login.`);
  log.dim(`  Load now: launchctl load ${plistPath}`);
  log.dim(`  Unload:   launchctl unload ${plistPath}`);
}
