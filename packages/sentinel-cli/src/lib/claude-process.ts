// packages/sentinel-cli/src/lib/claude-process.ts
import { spawn, type ChildProcess } from 'child_process';
import { log } from './logger';

let child: ChildProcess | null = null;
let shuttingDown = false;
let spawnCwd: string = process.cwd();
let managedStdin: import('stream').Writable | null = null;

export function isClaudeRunning(): boolean {
  return child !== null && !child.killed && child.exitCode === null;
}

/**
 * Spawn Claude Code as a managed child process.
 * stdio: 'inherit' so Claude gets a real TTY and runs in interactive mode.
 * SIGINT can be sent via interruptClaude() to stop mid-task.
 * On exit (unless shutting down), auto-restarts with --continue.
 * @param args Extra args passed to `claude` on first launch
 */
export function startClaude(args: string[] = []): void {
  if (isClaudeRunning()) {
    log.warn('[claude-process] Already running — ignoring startClaude call');
    return;
  }

  shuttingDown = false;
  spawnCwd = process.cwd();
  spawnClaude(args);
}

function spawnClaude(args: string[]): void {
  log.info(`[claude-process] Spawning: claude ${args.join(' ')}`);

  child = spawn('claude', args, {
    stdio: ['pipe', 'inherit', 'inherit'],
    cwd: spawnCwd,
    env: { ...process.env },
  });

  managedStdin = child.stdin ?? null;

  child.on('exit', (code) => {
    log.info(`[claude-process] Exited with code ${code}`);
    managedStdin = null;
    child = null;

    if (!shuttingDown) {
      // Auto-restart with --continue so user can keep working in the terminal
      setTimeout(() => {
        if (!shuttingDown) {
          log.info('[claude-process] Restarting with --continue...');
          spawnClaude(['--continue']);
        }
      }, 500);
    }
  });

  child.on('error', (err) => {
    log.error(`[claude-process] Spawn error: ${err.message}`);
    child = null;
  });
}

/**
 * Write a message to the managed Claude process stdin (as if typed by user).
 * Returns false if Claude is not running or stdin is unavailable.
 */
export function sendToManagedClaude(text: string): boolean {
  if (!managedStdin || managedStdin.destroyed) return false;
  managedStdin.write(text + '\n');
  log.info(`[claude-process] Sent to stdin: ${text.slice(0, 60)}`);
  return true;
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
  shuttingDown = true;
  managedStdin = null;
  if (child && !child.killed) {
    child.kill('SIGTERM');
    child = null;
  }
}
