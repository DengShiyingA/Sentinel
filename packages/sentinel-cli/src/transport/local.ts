import net from 'net';
import { randomBytes } from 'crypto';
import { Bonjour } from 'bonjour-service';
import type { Transport, ApprovalPayload } from './interface';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';
import { networkInterfaces } from 'os';
import type { Rule } from '../rules/engine';

const TCP_PORT = 7750;
const SERVICE_TYPE = 'sentinel';
const PROTOCOL = 'tcp';

/**
 * Local transport — TCP server + Bonjour (mDNS) for LAN-direct mode.
 *
 * - Opens a TCP server on port 7750
 * - Publishes _sentinel._tcp via Bonjour so iOS can auto-discover
 * - iOS connects directly, same JSON message format as remote mode
 * - Messages are newline-delimited JSON over raw TCP
 */
export class LocalTransport implements Transport {
  readonly mode = 'local' as const;

  private server: net.Server | null = null;
  private bonjour: Bonjour | null = null;
  private iosSocket: net.Socket | null = null;
  private buffer = '';
  private decisionCb: ((id: string, action: 'allowed' | 'blocked' | 'timeout') => void) | null = null;
  private rulesUpdateCb: ((rules: Rule[]) => void) | null = null;

  get isConnected(): boolean {
    return this.iosSocket !== null && !this.iosSocket.destroyed;
  }

  async start(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.server = net.createServer((socket) => {
        // Accept one iOS connection at a time
        if (this.iosSocket && !this.iosSocket.destroyed) {
          log.warn('[local] New connection replacing old one');
          this.iosSocket.destroy();
        }

        this.iosSocket = socket;
        this.buffer = '';
        log.success(`[local] iOS connected from ${socket.remoteAddress}`);

        socket.on('data', (chunk) => {
          this.buffer += chunk.toString();
          this.processBuffer();
        });

        socket.on('close', () => {
          log.warn('[local] iOS disconnected');
          if (this.iosSocket === socket) this.iosSocket = null;
        });

        socket.on('error', (err) => {
          log.error(`[local] Socket error: ${err.message}`);
          if (this.iosSocket === socket) this.iosSocket = null;
        });
      });

      this.server.listen(TCP_PORT, () => {
        log.success(`[local] TCP server listening on port ${TCP_PORT}`);
        this.publishBonjour();
        resolve();
      });

      this.server.on('error', (err) => {
        log.error(`[local] Server error: ${err.message}`);
        reject(err);
      });
    });
  }

  private publishBonjour(): void {
    this.bonjour = new Bonjour();
    this.bonjour.publish({
      name: `Sentinel-${process.env.USER ?? 'mac'}`,
      type: SERVICE_TYPE,
      protocol: PROTOCOL,
      port: TCP_PORT,
      txt: { version: '1' },
    });
    log.success(`[local] Bonjour: publishing _${SERVICE_TYPE}._${PROTOCOL}`);

    const ip = getLocalIP();
    if (ip) log.info(`[local] LAN address: ${ip}:${TCP_PORT}`);
  }

  /** Process newline-delimited JSON from buffer */
  private processBuffer(): void {
    const lines = this.buffer.split('\n');
    this.buffer = lines.pop() ?? '';

    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const msg = JSON.parse(line);
        this.handleMessage(msg);
      } catch {
        log.debug(`[local] Invalid JSON: ${line.slice(0, 80)}`);
      }
    }
  }

  private handleMessage(msg: { event: string; data: any }): void {
    if (msg.event === 'decision') {
      const { requestId, action } = msg.data;
      log.info(`[local] Decision: ${requestId} → ${action}`);
      pending.resolve(requestId, action);
      this.decisionCb?.(requestId, action);
    } else if (msg.event === 'rules_update') {
      const rules = msg.data?.rules as Rule[] | undefined;
      if (rules) {
        log.info(`[local] Rules update from iOS: ${rules.length} custom rules`);
        this.rulesUpdateCb?.(rules);
      }
    } else if (msg.event === 'heartbeat_ack') {
      // iOS responded to heartbeat
    }
  }

  /** Send a JSON message to connected iOS */
  private send(event: string, data: any): void {
    if (!this.iosSocket || this.iosSocket.destroyed) return;
    const msg = JSON.stringify({ event, data }) + '\n';
    this.iosSocket.write(msg);
  }

  async sendApprovalRequest(payload: ApprovalPayload): Promise<string> {
    if (!this.isConnected) throw new Error('iOS not connected');

    const requestId = randomBytes(12).toString('hex');
    this.send('approval_request', {
      id: requestId,
      toolName: payload.toolName,
      toolInput: payload.toolInput,
      riskLevel: payload.riskLevel,
      timestamp: new Date().toISOString(),
      timeoutAt: new Date(Date.now() + 120_000).toISOString(),
    });

    return requestId;
  }

  onDecision(cb: (id: string, action: 'allowed' | 'blocked' | 'timeout') => void): void {
    this.decisionCb = cb;
  }

  /** Register callback for rules updates from iOS */
  onRulesUpdate(cb: (rules: Rule[]) => void): void {
    this.rulesUpdateCb = cb;
  }

  stop(): void {
    this.iosSocket?.destroy();
    this.iosSocket = null;
    this.server?.close();
    this.server = null;
    if (this.bonjour) {
      this.bonjour.unpublishAll();
      this.bonjour.destroy();
      this.bonjour = null;
    }
  }

  /** Get info for pairing display */
  getConnectionInfo(): { ip: string; port: number } {
    return { ip: getLocalIP() ?? '0.0.0.0', port: TCP_PORT };
  }
}

function getLocalIP(): string | null {
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] ?? []) {
      if (net.family === 'IPv4' && !net.internal) return net.address;
    }
  }
  return null;
}
