import { existsSync } from 'fs';
import { bin, install, Tunnel } from 'cloudflared';
import { log } from './logger';

let activeTunnel: Tunnel | null = null;

const URL_TIMEOUT_MS = 30_000;

// Note: caller (CLI entrypoint) is responsible for calling stopTunnel() on SIGINT.

/**
 * Start a Cloudflare quick tunnel pointing at the local HTTP port.
 * Auto-downloads the cloudflared binary on first run if missing.
 * Returns the tunnel URL (https://xxx.trycloudflare.com).
 */
export async function startTunnel(port: number): Promise<string> {
  if (activeTunnel) {
    log.warn('startTunnel called while another tunnel is active, stopping previous');
    stopTunnel();
  }

  // Auto-download binary if missing
  if (!existsSync(bin)) {
    log.info('cloudflared binary not found, downloading...');
    try {
      await install(bin);
      log.success('cloudflared binary installed');
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      throw new Error(`Failed to install cloudflared binary: ${msg}`);
    }
  }

  log.info(`Starting Cloudflare Tunnel for port ${port}...`);

  // cloudflared v0.7.x: Tunnel.quick() spawns `cloudflared tunnel --url ...`
  // (no named tunnel required). The generic top-level `tunnel()` helper in
  // this version builds `tunnel run --url ...`, which errors out because it
  // expects a named tunnel — so we use the static quick() factory instead.
  // The resulting Tunnel is an EventEmitter wrapping a ChildProcess; the
  // trycloudflare URL arrives asynchronously via the 'url' event parsed from
  // stderr, so we wrap it in a promise.
  //
  // Force --protocol http2: the default QUIC protocol (UDP/443) is blocked by
  // many corporate firewalls, home VPNs, and carrier networks, causing tunnels
  // to fail with "no recent network activity" errors. HTTP/2 runs over TCP/443
  // which is universally reachable. Perf difference is negligible for our
  // low-volume approval traffic.
  const t = Tunnel.quick(`http://localhost:${port}`, { '--protocol': 'http2' });
  activeTunnel = t;

  const url = await new Promise<string>((resolve, reject) => {
    let settled = false;
    let timeoutHandle: NodeJS.Timeout | null = null;

    const cleanup = () => {
      t.off('url', onUrl);
      t.off('error', onError);
      t.off('exit', onExit);
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
        timeoutHandle = null;
      }
    };

    const onUrl = (u: unknown) => {
      if (settled) return;
      if (typeof u !== 'string') return;
      settled = true;
      cleanup();
      resolve(u);
    };

    const onError = (err: Error) => {
      if (settled) return;
      settled = true;
      cleanup();
      activeTunnel = null;
      reject(err);
    };

    const onExit = (code: number | null, signal: NodeJS.Signals | null) => {
      if (settled) return;
      settled = true;
      cleanup();
      activeTunnel = null;
      reject(
        new Error(
          `cloudflared exited before producing a URL (code=${code}, signal=${signal})`,
        ),
      );
    };

    t.on('url', onUrl);
    t.on('error', onError);
    t.on('exit', onExit);

    timeoutHandle = setTimeout(() => {
      if (settled) return;
      settled = true;
      cleanup();
      try {
        t.stop();
      } catch {
        // ignore — we're already on the error path
      }
      activeTunnel = null;
      reject(
        new Error(
          `Timed out after ${URL_TIMEOUT_MS}ms waiting for cloudflared to emit a tunnel URL`,
        ),
      );
    }, URL_TIMEOUT_MS);
  });

  log.success(`Tunnel ready: ${url}`);
  return url;
}

/**
 * Stop the active tunnel, if any.
 */
export function stopTunnel(): void {
  if (activeTunnel) {
    try {
      activeTunnel.stop();
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      log.warn(`Error stopping tunnel: ${msg}`);
    }
    activeTunnel = null;
  }
}
