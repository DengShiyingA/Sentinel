import net from 'net';
import { randomBytes } from 'crypto';
import { spawn as cpSpawn } from 'child_process';
import nacl from 'tweetnacl';
import { encodeBase64 } from 'tweetnacl-util';
import { Bonjour } from 'bonjour-service';
import type { Transport, ApprovalPayload } from './interface';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';
import { networkInterfaces } from 'os';
import type { Rule } from '../rules/engine';
import { getTransportKey, getTransportKeyBase64, encryptMessage, decryptMessage } from '../crypto/transport-encryption';
import { interruptClaude, isClaudeRunning, sendToManagedClaude } from '../lib/claude-process';

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
  private static readonly MAX_BUFFER_SIZE = 1_048_576; // 1 MB
  private decisionCb: ((id: string, action: 'allowed' | 'blocked' | 'timeout') => void) | null = null;
  private rulesUpdateCb: ((rules: Rule[]) => void) | null = null;
  private userMessageCb: ((text: string) => void) | null = null;
  private activeClaudeProcess: import('child_process').ChildProcess | null = null;

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

        // Send handshake with X25519 ephemeral public key for key agreement.
        // The transport key is derived: HMAC-SHA256(sharedSecret, "sentinel-transport-v2").
        // This replaces sending the raw symmetric key in plaintext.
        const ephemeral = nacl.box.keyPair();
        const handshake = JSON.stringify({
          event: 'handshake',
          data: {
            version: '3',
            x25519PublicKey: encodeBase64(ephemeral.publicKey),
            // Still include ek for backward compatibility with older iOS versions
            ek: getTransportKeyBase64(),
          },
        }) + '\n';
        socket.write(handshake);

        // Store ephemeral secret key for this connection to derive shared key
        // when iOS responds with its public key
        (socket as any)._ephemeralSecretKey = ephemeral.secretKey;

        setTimeout(() => {
          this.send('workspace_info', {
            cwd: process.cwd(),
            hostname: require('os').hostname(),
          });
        }, 500);

        socket.on('data', (chunk) => {
          this.buffer += chunk.toString();
          if (this.buffer.length > LocalTransport.MAX_BUFFER_SIZE) {
            log.error('[local] Buffer exceeded 1MB, dropping connection');
            this.buffer = '';
            socket.destroy();
            return;
          }
          this.processBuffer();
        });

        socket.on('close', () => {
          log.warn('[local] iOS disconnected');
          // Clear ephemeral key material
          if ((socket as any)._ephemeralSecretKey) {
            (socket as any)._ephemeralSecretKey = null;
          }
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
        // If sentinel run is active, write directly to managed Claude's stdin
        // instead of spawning a separate --print process
        if (isClaudeRunning() && sendToManagedClaude(text)) {
          log.info(`[local] Forwarded to managed Claude stdin`);
        } else {
          this.runClaude(text);
        }
      }
    } else if (msg.event === 'interrupt') {
      log.info('[local] Interrupt from iOS');
      interruptClaude();
    } else if (msg.event === 'heartbeat_ack') {
      // iOS responded to heartbeat
    }
  }

  /** Send a notification to iOS */
  sendNotification(title: string, message: string): void {
    this.send('notification', { title, message });
  }

  sendEvent(data: Record<string, unknown>): void {
    const type = data.type as string | undefined;
    if (type === 'terminal') {
      this.send('terminal', data);
    } else {
      this.send('activity', data);
    }
  }

  private runClaude(message: string): void {
    this.send('terminal', { type: 'terminal', text: `> ${message}` });
    this.sendEvent({ type: 'claude_status', status: 'thinking', message });

    // Kill any previous Claude process before starting a new one
    if (this.activeClaudeProcess && !this.activeClaudeProcess.killed) {
      this.activeClaudeProcess.kill('SIGTERM');
    }

    const child = cpSpawn('claude', ['--continue', '--print', message], {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env },
    });
    this.activeClaudeProcess = child;

    let output = '';
    let lineBuffer = '';

    const streamLines = (chunk: Buffer) => {
      lineBuffer += chunk.toString();
      const lines = lineBuffer.split('\n');
      lineBuffer = lines.pop() ?? '';
      for (const line of lines) {
        if (line.trim()) {
          this.send('terminal', { type: 'terminal', text: line });
        }
      }
      output += chunk.toString();
    };

    child.stdout?.on('data', streamLines);
    child.stderr?.on('data', streamLines);

    child.on('close', (code) => {
      if (lineBuffer.trim()) {
        this.send('terminal', { type: 'terminal', text: lineBuffer });
      }

      const trimmed = output.trim();
      this.sendEvent({
        type: 'claude_response',
        message: trimmed || (code === 0 ? '完成（无输出）' : '无活跃会话'),
        exitCode: code,
      });
      log.success(`[local] Claude responded (${trimmed.length} chars, exit ${code})`);
    });

    child.on('error', (err) => {
      log.error(`[local] Claude error: ${err.message}`);
      this.sendEvent({
        type: 'claude_response',
        message: `错误: ${err.message}`,
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
      ...(payload.diff ? { diff: payload.diff } : {}),
      ...(payload.contextSummary ? { contextSummary: payload.contextSummary } : {}),
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
    if (this.activeClaudeProcess && !this.activeClaudeProcess.killed) {
      this.activeClaudeProcess.kill('SIGTERM');
      this.activeClaudeProcess = null;
    }
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
