// packages/sentinel-cli/src/lib/claude-process.ts
import { spawn, type ChildProcess } from 'child_process';
import { log, silenceForClaude, unsilence } from './logger';

let child: ChildProcess | null = null;
let shuttingDown = false;
let spawnCwd: string = process.cwd();
let restartCount = 0;
let lastExitTime = 0;
let currentModel: string = '';

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
export function startClaude(args: string[] = [], model?: string): void {
  if (isClaudeRunning()) {
    log.warn('[claude-process] Already running — ignoring startClaude call');
    return;
  }

  shuttingDown = false;
  restartCount = 0;
  lastExitTime = 0;
  spawnCwd = process.cwd();
  if (model !== undefined) {
    currentModel = model;
  }
  spawnClaude(args);
}

function spawnClaude(args: string[]): void {
  silenceForClaude(); // suppress sentinel logs while Claude TUI is active
  const modelArgs = currentModel ? ['--model', currentModel] : [];
  const fullArgs = [...args, ...modelArgs];
  log.info(`[claude-process] Spawning: claude ${fullArgs.join(' ')}`);

  child = spawn('claude', fullArgs, {
    stdio: 'inherit',
    cwd: spawnCwd,
    env: { ...process.env },
  });

  child.on('exit', (code) => {
    unsilence(); // restore terminal logs between Claude sessions
    log.info(`[claude-process] Exited with code ${code}`);
    child = null;

    if (!shuttingDown) {
      const now = Date.now();
      const elapsed = now - lastExitTime;
      lastExitTime = now;

      // Reset counter if Claude ran for more than 10 seconds
      if (elapsed > 10_000) {
        restartCount = 0;
      } else {
        restartCount++;
      }

      // Exponential backoff: 500ms, 1s, 2s, 4s... max 30s
      const delay = Math.min(500 * Math.pow(2, restartCount - 1), 30_000);
      if (restartCount > 1) {
        log.warn(`[claude-process] Fast exit detected (${restartCount}x). Restarting in ${delay}ms...`);
      }

      setTimeout(() => {
        if (!shuttingDown) {
          log.info('[claude-process] Restarting with --continue...');
          spawnClaude(['--continue']);
        }
      }, delay);
    }
  });

  child.on('error', (err) => {
    log.error(`[claude-process] Spawn error: ${err.message}`);
    child = null;
  });
}

export function getCurrentModel(): string {
  return currentModel;
}

export function setModel(model: string): void {
  currentModel = model;
  log.info(`[claude-process] Model set to: ${model}`);
  if (isClaudeRunning()) {
    log.info('[claude-process] Interrupting Claude to restart with new model...');
    child!.kill('SIGINT');
  }
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
  if (child && !child.killed) {
    child.kill('SIGTERM');
    child = null;
  }
}
