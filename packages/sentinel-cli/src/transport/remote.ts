import { io, Socket } from 'socket.io-client';
import { randomBytes } from 'crypto';
import type { Transport, ApprovalPayload } from './interface';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';

/**
 * Remote transport — wraps existing Socket.IO client for server-relay mode.
 */
export class RemoteTransport implements Transport {
  readonly mode = 'server' as const;

  private socket: Socket | null = null;
  private decisionCb: ((id: string, action: 'allowed' | 'blocked' | 'timeout') => void) | null = null;

  constructor(
    private serverURL: string,
    private token: string,
  ) {}

  get isConnected(): boolean {
    return this.socket?.connected ?? false;
  }

  async start(): Promise<void> {
    // Clean up previous socket to prevent duplicate listeners
    if (this.socket) {
      this.socket.removeAllListeners();
      this.socket.disconnect();
      this.socket = null;
    }

    this.socket = io(this.serverURL, {
      auth: { token: this.token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 30000,
      reconnectionAttempts: 10,
    });

    this.socket.on('connect', () => {
      log.success(`[remote] Connected to ${this.serverURL}`);
    });

    this.socket.on('disconnect', (reason) => {
      log.warn(`[remote] Disconnected: ${reason}`);
    });

    this.socket.on('connect_error', (err) => {
      log.error(`[remote] Connection error: ${err.message}`);
    });

    this.socket.on('decision', (data: { requestId: string; action: string }) => {
      log.info(`[remote] Decision: ${data.requestId} → ${data.action}`);
      pending.resolve(data.requestId, data.action as 'allowed' | 'blocked' | 'timeout');
      this.decisionCb?.(data.requestId, data.action as any);
    });

    this.socket.on('heartbeat', () => {
      this.socket?.emit('heartbeat');
    });

    // Wait for initial connection
    await new Promise<void>((resolve) => {
      const timeout = setTimeout(() => resolve(), 5000);
      this.socket!.once('connect', () => { clearTimeout(timeout); resolve(); });
    });
  }

  async sendApprovalRequest(payload: ApprovalPayload): Promise<string> {
    return new Promise((resolve, reject) => {
      if (!this.socket?.connected) return reject(new Error('Not connected'));
      this.socket.emit('approval_request', payload, (res: { success: boolean; requestId?: string; error?: string }) => {
        if (res.success && res.requestId) resolve(res.requestId);
        else reject(new Error(res.error ?? 'Failed'));
      });
    });
  }

  onDecision(cb: (id: string, action: 'allowed' | 'blocked' | 'timeout') => void): void {
    this.decisionCb = cb;
  }

  stop(): void {
    this.socket?.removeAllListeners();
    this.socket?.disconnect();
    this.socket = null;
  }
}
