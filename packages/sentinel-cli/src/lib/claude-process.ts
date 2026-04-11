// packages/sentinel-cli/src/lib/claude-process.ts
import { spawn, type ChildProcess } from 'child_process';
import { existsSync } from 'fs';
import { log, silenceForClaude, unsilence } from './logger';

let child: ChildProcess | null = null;
let shuttingDown = false;
let spawnCwd: string = process.cwd();
let restartCount = 0;
let lastExitTime = 0;
let currentModel: string = '';
let initialArgs: string[] = []; // user-provided args from `sentinel run -- ...`, preserved across restarts
let pendingModelRestart = false; // set when setModel() kills Claude — don't treat exit as clean
let pendingCwdRestart = false;  // set when setCwd() kills Claude — restart fresh in new dir

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
  // Filter out --continue from initial args — that's a restart-only flag
  initialArgs = args.filter((a) => a !== '--continue');
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

  child.on('exit', (code, signal) => {
    unsilence(); // restore terminal logs between Claude sessions
    log.info(`[claude-process] Exited with code ${code}${signal ? ` (signal ${signal})` : ''}`);
    child = null;

    // Model change triggered this exit — restart with --continue in same dir
    if (pendingModelRestart) {
      pendingModelRestart = false;
      if (!shuttingDown) {
        log.info('[claude-process] Restarting with new model...');
        spawnClaude(['--continue', ...initialArgs]);
      }
      return;
    }

    // Directory change triggered this exit — restart fresh (no --continue) in new dir
    if (pendingCwdRestart) {
      pendingCwdRestart = false;
      if (!shuttingDown) {
        log.info(`[claude-process] Restarting in new directory: ${spawnCwd}`);
        spawnClaude([...initialArgs]);
      }
      return;
    }

    // Clean exit (code 0) means user typed /exit — don't restart
    // Restart only on signal-induced exits (SIGINT from iPhone interrupt) or crashes
    const wasInterrupted = signal === 'SIGINT' || code === 130;
    const wasCrash = code !== 0 && !wasInterrupted;

    // If user cleanly exited Claude, also exit sentinel
    if (!shuttingDown && code === 0 && !wasInterrupted) {
      log.info('[claude-process] Claude exited cleanly — shutting down sentinel');
      shuttingDown = true;
      setTimeout(() => process.exit(0), 100);
      return;
    }

    if (!shuttingDown && (wasInterrupted || wasCrash)) {
      const now = Date.now();
      const elapsed = now - lastExitTime;
      lastExitTime = now;

      // Reset counter if Claude ran for more than 10 seconds
      if (elapsed > 10_000) {
        restartCount = 1;
      } else {
        restartCount++;
      }

      // Give up after 5 rapid-fire exits (prevents infinite loop when
      // `--continue` targets a stale/missing session that always fails).
      if (restartCount >= 5) {
        log.error(
          `[claude-process] Claude crashed ${restartCount} times in a row. Aborting restart loop.`,
        );
        log.warn('[claude-process] Run `sentinel run` again to retry with a fresh session.');
        shuttingDown = true;
        setTimeout(() => process.exit(1), 100);
        return;
      }

      // After 3 fast-fail retries, assume `--continue` is broken (stale session,
      // "No deferred tool marker" error, etc) and start fresh without it.
      const useContinue = restartCount < 3;

      // Exponential backoff: 500ms, 1s, 2s, 4s... max 30s
      // restartCount is always >= 1 here so 2^(n-1) is safe
      const delay = Math.min(500 * Math.pow(2, restartCount - 1), 30_000);
      if (restartCount > 1) {
        log.warn(`[claude-process] Fast exit detected (${restartCount}x). Restarting in ${delay}ms...`);
      }

      setTimeout(() => {
        if (!shuttingDown) {
          if (useContinue) {
            log.info('[claude-process] Restarting with --continue...');
            spawnClaude(['--continue', ...initialArgs]);
          } else {
            log.warn('[claude-process] --continue keeps failing, restarting fresh...');
            spawnClaude([...initialArgs]);
          }
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

export function getSpawnCwd(): string {
  return spawnCwd;
}

export function setCwd(newCwd: string): void {
  if (!existsSync(newCwd)) {
    log.warn(`[claude-process] setCwd: path does not exist: ${newCwd}`);
    return;
  }
  spawnCwd = newCwd;
  log.info(`[claude-process] Working directory set to: ${newCwd}`);
  if (isClaudeRunning()) {
    log.info('[claude-process] Interrupting Claude to restart in new directory...');
    pendingCwdRestart = true;
    child!.kill('SIGINT');
  }
}

export function setModel(model: string): void {
  currentModel = model;
  log.info(`[claude-process] Model set to: ${model}`);
  if (isClaudeRunning()) {
    log.info('[claude-process] Interrupting Claude to restart with new model...');
    pendingModelRestart = true;
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
