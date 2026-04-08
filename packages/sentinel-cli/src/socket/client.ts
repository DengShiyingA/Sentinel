import { io, Socket } from 'socket.io-client';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';

let socket: Socket | null = null;
let reconnectAttempts = 0;
const MAX_RECONNECT = 10;

/**
 * 连接 Socket.IO，带 JWT auth 和指数退避重连
 */
export function connectSocket(serverURL: string, token: string): Socket {
  if (socket?.connected) return socket;

  socket = io(serverURL, {
    auth: { token },
    transports: ['websocket', 'polling'],
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 30000,
    reconnectionAttempts: MAX_RECONNECT,
  });

  socket.on('connect', () => {
    reconnectAttempts = 0;
    log.success(`Socket connected (id: ${socket!.id})`);
  });

  socket.on('disconnect', (reason) => {
    log.warn(`Socket disconnected: ${reason}`);
  });

  socket.on('connect_error', (err) => {
    reconnectAttempts++;
    const delay = Math.min(Math.pow(2, reconnectAttempts - 1) * 1000, 30000);
    log.error(`Connection error: ${err.message} (retry in ${delay / 1000}s)`);
  });

  // ==================== 收到决策 ====================

  socket.on('decision', (data: { requestId: string; action: string }) => {
    log.info(`Decision received: ${data.requestId} → ${data.action}`);
    pending.resolve(data.requestId, data.action as 'allowed' | 'blocked' | 'timeout');
  });

  socket.on('heartbeat', () => {
    socket?.emit('heartbeat');
  });

  socket.on('heartbeat_ack', () => {
    log.debug('Heartbeat ack');
  });

  return socket;
}

/**
 * 发送审批请求到 server，返回 requestId
 */
export async function emitApprovalRequest(data: {
  toolName: string;
  toolInput: Record<string, unknown>;
  riskLevel: string;
}): Promise<string> {
  return new Promise((resolve, reject) => {
    if (!socket?.connected) {
      return reject(new Error('Socket not connected'));
    }

    socket.emit('approval_request', data, (res: { success: boolean; requestId?: string; error?: string }) => {
      if (res.success && res.requestId) {
        resolve(res.requestId);
      } else {
        reject(new Error(res.error ?? 'Failed to send approval request'));
      }
    });
  });
}

export function getSocket(): Socket | null {
  return socket;
}

export function disconnectSocket(): void {
  socket?.disconnect();
  socket = null;
}

export function isConnected(): boolean {
  return socket?.connected ?? false;
}
