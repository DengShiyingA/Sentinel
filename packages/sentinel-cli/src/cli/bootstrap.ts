// packages/sentinel-cli/src/cli/bootstrap.ts
import { createTransport } from '../transport/factory';
import { LocalTransport } from '../transport/local';
import { setTransport, getTransport, type TransportMode } from '../transport/interface';
import { startHttpServer, setupUserMessageHandler } from '../server/http';
import { watchRules, setCustomRules } from '../rules/engine';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';
import { execSync } from 'child_process';

export interface BootstrapOpts {
  mode: TransportMode;
  port: number;
  server?: string;
  remote?: boolean;
}

/** Kill any stale process holding the given port (best-effort, silent). */
function freePort(port: number): void {
  try { execSync(`lsof -ti :${port} | xargs kill -9`, { stdio: 'ignore' }); } catch {}
}

/**
 * Start transport + HTTP hook server. Used by both `sentinel start` and `sentinel run`.
 * Returns a shutdown callback.
 */
export async function bootstrapSentinel(opts: BootstrapOpts): Promise<() => void> {
  const { mode, port, remote } = opts;

  // Free stale processes on both ports before binding
  freePort(port);       // hook server port (7749)
  freePort(7750);       // TCP transport port

  if (mode === 'server') {
    const { ensureToken, getStoredServerURL } = await import('../api/client');
    const serverURL = opts.server ?? getStoredServerURL();
    if (!serverURL) { log.error('Server mode requires -s URL.'); process.exit(1); }
    log.info('Authenticating...');
    const tokenData = await ensureToken(serverURL);
    const transport = createTransport('server', { serverUrl: serverURL, token: tokenData.token });
    setTransport(transport);
    log.info(`Connecting to ${serverURL}...`);
    await transport.start();
  } else if (mode === 'cloudkit') {
    const transport = createTransport('cloudkit');
    setTransport(transport);
    await transport.start();
  } else {
    // local
    const transport = createTransport('local');
    setTransport(transport);
    await transport.start();
    if (transport instanceof LocalTransport) {
      const info = transport.getConnectionInfo();
      log.info(`iOS can connect to: ${info.ip}:${info.port}`);
      try {
        const qrcode = require('qrcode-terminal');
        const qrData = `sentinel://${info.ip}:${info.port}`;
        console.log('');
        log.info('Scan QR code with Sentinel iOS app:');
        qrcode.generate(qrData, { small: true }, (code: string) => { console.log(code); });
      } catch {}
      transport.onRulesUpdate((rules) => setCustomRules(rules));
    }
  }

  watchRules();
  await startHttpServer(port);
  setupUserMessageHandler();

  const cleanupFns: Array<() => void> = [];

  if (remote) {
    try {
      const { startTunnel, stopTunnel } = require('../lib/tunnel');
      const { getTransportKeyBase64 } = require('../crypto/transport-encryption');

      log.info('Starting Cloudflare Tunnel for port 7750...');
      const tunnelUrl: string = await startTunnel(7750);
      const tunnelHost = tunnelUrl.replace(/^https?:\/\//, '');
      const pubKey = getTransportKeyBase64();
      const qrData = `sentinel-remote://${tunnelHost}#key=${encodeURIComponent(pubKey)}`;

      console.log('');
      log.success(`远程地址：${tunnelUrl}`);
      log.info('iPhone 端选择"添加远程终端"扫描下方二维码：');
      console.log('');

      const qrcode = require('qrcode-terminal');
      qrcode.generate(qrData, { small: true }, (code: string) => { console.log(code); });

      cleanupFns.push(stopTunnel);
    } catch (err) {
      log.error(`Tunnel failed: ${(err as Error).message}`);
      log.warn('继续以 LAN-only 模式运行');
    }
  }

  return () => {
    for (const fn of cleanupFns) fn();
    pending.clear();
    getTransport()?.stop();
  };
}
