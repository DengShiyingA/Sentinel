import net from 'net';
import { randomBytes } from 'crypto';
import { spawn as cpSpawn } from 'child_process';
import { Bonjour } from 'bonjour-service';
import type { Transport, ApprovalPayload } from './interface';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';
import { networkInterfaces } from 'os';
import type { Rule } from '../rules/engine';
import { getTransportKey, getTransportKeyBase64, encryptMessage, decryptMessage } from '../crypto/transport-encryption';

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
  private userMessageCb: ((text: string) => void) | null = null;

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

        // Send plaintext handshake with encryption key
        const handshake = JSON.stringify({
          event: 'handshake',
          data: { version: '2', ek: getTransportKeyBase64() },
        }) + '\n';
        socket.write(handshake);

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
      txt: { version: '2', ek: getTransportKeyBase64() }, // ek = encryption key
    });
    log.success(`[local] Bonjour: publishing _${SERVICE_TYPE}._${PROTOCOL}`);

    const ip = getLocalIP();
    if (ip) log.info(`[local] LAN address: ${ip}:${TCP_PORT}`);
  }

  /** Process newline-delimited messages from buffer (encrypted or plain) */
  private processBuffer(): void {
    const lines = this.buffer.split('\n');
    this.buffer = lines.pop() ?? '';
    const key = getTransportKey();

    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        // Try decrypt first (encrypted messages are base64, not JSON)
        let json: string;
        if (line.startsWith('{')) {
          json = line; // Plain JSON fallback (handshake)
        } else {
          const decrypted = decryptMessage(line, key);
          if (!decrypted) { log.debug('[local] Decrypt failed'); continue; }
          json = decrypted;
        }
        const msg = JSON.parse(json);
        this.handleMessage(msg);
      } catch {
        log.debug(`[local] Parse error: ${line.slice(0, 40)}`);
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
    } else if (msg.event === 'user_message') {
      const text = msg.data?.text as string | undefined;
      if (text) {
        log.info(`[local] Message from iOS: ${text}`);
        this.userMessageCb?.(text);
        this.runClaude(text);
      }
    } else if (msg.event === 'heartbeat_ack') {
      // iOS responded to heartbeat
    }
  }

  /** Send a notification to iOS */
  sendNotification(title: string, message: string): void {
    this.send('notification', { title, message });
  }

  /** Send an activity event to iOS (fire-and-forget, no response needed) */
  sendEvent(data: Record<string, unknown>): void {
    this.send('activity', data);
  }

  /** Run claude --continue with user message, stream output back to iOS */
  private runClaude(message: string): void {
    // Notify iOS that we're processing
    this.sendEvent({ type: 'claude_status', status: 'thinking', message });

    const child = cpSpawn('claude', ['--continue', '--print', message], {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env },
    });

    let output = '';

    child.stdout?.on('data', (chunk: Buffer) => {
      output += chunk.toString();
    });

    child.stderr?.on('data', (chunk: Buffer) => {
      output += chunk.toString();
    });

    child.on('close', (code) => {
      const trimmed = output.trim();
      if (trimmed) {
        // Send response back to iOS
        this.sendEvent({
          type: 'claude_response',
          message: trimmed,
          exitCode: code,
        });
        log.success(`[local] Claude responded (${trimmed.length} chars)`);
      } else {
        this.sendEvent({
          type: 'claude_response',
          message: code === 0
            ? 'Claude completed (no output)'
            : 'Claude not available — is there an active session?',
          exitCode: code,
        });
      }
    });

    child.on('error', (err) => {
      log.error(`[local] Claude spawn error: ${err.message}`);
      this.sendEvent({
        type: 'claude_response',
        message: `Error: ${err.message}. Make sure \`claude\` is installed and in PATH.`,
        exitCode: -1,
      });
    });
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
    // Map server risk levels to iOS RiskLevel enum values
    const riskMap: Record<string, string> = {
      low: 'require_confirm',
      medium: 'require_confirm',
      high: 'require_faceid',
    };

    this.send('approval_request', {
      id: requestId,
      toolName: payload.toolName,
      toolInput: payload.toolInput,
      riskLevel: riskMap[payload.riskLevel] ?? 'require_confirm',
      macDeviceId: 'local',
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

  /** Register callback for user messages from iOS */
  onUserMessage(cb: (text: string) => void): void {
    this.userMessageCb = cb;
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
