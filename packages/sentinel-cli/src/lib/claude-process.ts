// packages/sentinel-cli/src/lib/claude-process.ts
import { spawn, type ChildProcess } from 'child_process';
// strip-ansi v6 is CommonJS — require() works with esModuleInterop
// eslint-disable-next-line @typescript-eslint/no-var-requires
const stripAnsi = require('strip-ansi') as (str: string) => string;
import { log } from './logger';

let child: ChildProcess | null = null;
let lineCallback: ((line: string) => void) | null = null;

/** Register a callback that receives each stripped output line from Claude. */
export function setLineCallback(cb: (line: string) => void): void {
  lineCallback = cb;
}

export function isClaudeRunning(): boolean {
  return child !== null && !child.killed && child.exitCode === null;
}

/**
 * Spawn Claude Code as a managed child process.
 * stdout/stderr → Mac terminal (inherited write) + iOS via lineCallback.
 * @param args Extra args passed to `claude` (e.g. ['--continue'])
 */
export function startClaude(args: string[] = []): void {
  if (isClaudeRunning()) {
    log.warn('[claude-process] Already running — ignoring startClaude call');
    return;
  }

  log.info(`[claude-process] Spawning: claude ${args.join(' ')}`);

  child = spawn('claude', args, {
    stdio: ['inherit', 'pipe', 'pipe'],
    env: { ...process.env },
  });

  let lineBuffer = '';

  const handleChunk = (chunk: Buffer): void => {
    const raw = chunk.toString();
    // Forward raw bytes to Mac terminal so colours/TUI work normally
    process.stdout.write(raw);

    // Strip ANSI and split into lines for iOS forwarding
    lineBuffer += stripAnsi(raw);
    const lines = lineBuffer.split('\n');
    lineBuffer = lines.pop() ?? '';
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.length === 0) continue;
      // Skip lines that are only control characters after stripping
      if (/^[\x00-\x1F\x7F]+$/.test(trimmed)) continue;
      const capped = trimmed.length > 500 ? trimmed.slice(0, 500) + '…' : trimmed;
      lineCallback?.(capped);
    }
  };

  child.stdout?.on('data', handleChunk);
  child.stderr?.on('data', handleChunk);

  child.on('exit', (code) => {
    // Flush any remaining line buffer
    if (lineBuffer.trim()) {
      lineCallback?.(lineBuffer.trim());
      lineBuffer = '';
    }
    log.info(`[claude-process] Exited with code ${code}`);
    child = null;
  });

  child.on('error', (err) => {
    log.error(`[claude-process] Spawn error: ${err.message}`);
    child = null;
  });
}

/**
 * Send SIGINT to the running Claude process (equivalent to Ctrl+C).
 * Returns false if Claude is not running.
 */
export function interruptClaude(): boolean {
  if (!isClaudeRunning()) {
    log.warn('[claude-process] interruptClaude called but no process running');
    return false;
  }
  log.info('[claude-process] Sending SIGINT to Claude');
  child!.kill('SIGINT');
  return true;
}

/** Kill Claude process on sentinel shutdown. */
export function stopClaude(): void {
  if (child && !child.killed) {
    child.kill('SIGTERM');
    child = null;
  }
}
