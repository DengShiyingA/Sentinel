import { spawn, ChildProcess } from 'child_process';
import { log } from './logger';

let tunnelProcess: ChildProcess | null = null;

export async function startTunnel(port: number): Promise<string> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Tunnel timed out (30s). Is cloudflared installed?')), 30000);

    tunnelProcess = spawn('cloudflared', ['tunnel', '--url', `tcp://localhost:${port}`, '--no-tls-verify'], {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    tunnelProcess.on('error', (err) => {
      clearTimeout(timeout);
      if ((err as any).code === 'ENOENT') {
        reject(new Error('cloudflared not found. Install: brew install cloudflared'));
      } else {
        reject(err);
      }
    });

    const handleOutput = (data: Buffer) => {
      const line = data.toString();
      const match = line.match(/https?:\/\/[a-z0-9-]+\.trycloudflare\.com/);
      if (match) {
        clearTimeout(timeout);
        resolve(match[0]);
      }
    };

    tunnelProcess.stdout?.on('data', handleOutput);
    tunnelProcess.stderr?.on('data', handleOutput);

    tunnelProcess.on('exit', (code) => {
      clearTimeout(timeout);
      if (code !== 0 && code !== null) {
        reject(new Error(`cloudflared exited with code ${code}`));
      }
    });
  });
}

export function stopTunnel() {
  if (tunnelProcess) {
    tunnelProcess.kill();
    tunnelProcess = null;
    log.info('Tunnel stopped');
  }
}
