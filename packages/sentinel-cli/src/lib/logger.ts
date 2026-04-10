import chalk from 'chalk';
import fs from 'fs';
import path from 'path';
import os from 'os';

// Log file for sentinel output when Claude TUI is active
const LOG_DIR = path.join(os.homedir(), '.sentinel');
const LOG_FILE = path.join(LOG_DIR, 'run.log');

let silenced = false;
let logStream: fs.WriteStream | null = null;

/** Silence terminal output and redirect logs to ~/.sentinel/run.log */
export function silenceForClaude(): void {
  if (silenced) return;
  silenced = true;
  try {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    logStream = fs.createWriteStream(LOG_FILE, { flags: 'a' });
  } catch {
    // ignore
  }
}

export function unsilence(): void {
  silenced = false;
  logStream?.end();
  logStream = null;
}

function write(prefix: string, msg: string): void {
  const line = `${prefix} ${msg}`;
  if (silenced) {
    const ts = new Date().toISOString().slice(11, 19);
    logStream?.write(`${ts} ${line}\n`);
  } else {
    console.log(line);
  }
}

export const log = {
  info: (msg: string) => write(chalk.blue('ℹ'), msg),
  success: (msg: string) => write(chalk.green('✓'), msg),
  warn: (msg: string) => write(chalk.yellow('⚠'), msg),
  error: (msg: string) => {
    // Always print errors, even when silenced
    const line = `${chalk.red('✗')} ${msg}`;
    console.error(line);
    logStream?.write(`${new Date().toISOString().slice(11, 19)} ${line}\n`);
  },
  debug: (msg: string) => {
    if (process.env.DEBUG) write(chalk.gray('⋯'), msg);
  },
  dim: (msg: string) => write(chalk.dim(msg), ''),
};
