// packages/sentinel-cli/src/lib/claude-process.ts
import { spawn, type ChildProcess } from 'child_process';
import { log } from './logger';

let child: ChildProcess | null = null;

export function isClaudeRunning(): boolean {
  return child !== null && !child.killed && child.exitCode === null;
}

/**
 * Spawn Claude Code as a managed child process.
 * stdio: 'inherit' so Claude gets a real TTY and runs in interactive mode.
 * SIGINT can be sent via interruptClaude() to stop mid-task.
 * @param args Extra args passed to `claude` (e.g. ['--continue'])
 */
export function startClaude(args: string[] = []): void {
  if (isClaudeRunning()) {
    log.warn('[claude-process] Already running — ignoring startClaude call');
    return;
  }

  log.info(`[claude-process] Spawning: claude ${args.join(' ')}`);

  child = spawn('claude', args, {
    stdio: 'inherit',
    env: { ...process.env },
  });

  child.on('exit', (code) => {
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
