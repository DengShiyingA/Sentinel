import { Server, Socket } from 'socket.io';
import type { FastifyInstance } from 'fastify';
import { verifyJwt, type JwtPayload } from '../auth/challenge';
import { isTokenRevoked, findDeviceById } from '../db/client';
import { logger } from '../lib/logger';
import { config } from '../lib/config';
import { registerApprovalHandlers } from './handlers/approvalHandler';

// ==================== Types ====================

export interface ConnectedDevice {
  deviceId: string;
  type: string;
  publicKey: string;
  pairedWithId: string | null;
  socket: Socket;
  connectedAt: number;
}

// ==================== Hub ====================

/** deviceId → Socket 在线设备映射 */
const devices = new Map<string, ConnectedDevice>();

let io: Server;

export function getIO(): Server {
  return io;
}

export function getOnlineDevice(deviceId: string): ConnectedDevice | undefined {
  return devices.get(deviceId);
}

export function isOnline(deviceId: string): boolean {
  return devices.has(deviceId);
}

/**
 * 转发消息到目标设备
 */
export function relay(toDeviceId: string, event: string, payload: unknown): boolean {
  const target = devices.get(toDeviceId);
  if (!target) {
    logger.debug({ toDeviceId, event }, 'Relay failed: target offline');
    return false;
  }
  target.socket.emit(event, payload);
  return true;
}

/**
 * 初始化 Socket.IO，挂载到 Fastify server
 */
export function initSocketHub(app: FastifyInstance): Server {
  io = new Server(app.server, {
    cors: { origin: '*' },
    pingInterval: config.APPROVAL_TIMEOUT_S * 250, // ~30s
    pingTimeout: 60_000,
    transports: ['websocket', 'polling'],
  });

  // ==================== JWT 认证中间件 ====================

  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      return next(new Error('Missing auth token'));
    }

    const payload = verifyJwt(token);
    if (!payload) {
      return next(new Error('Invalid or expired token'));
    }

    // Check if token has been revoked
    const revoked = await isTokenRevoked(payload.deviceId);
    if (revoked) {
      logger.warn({ deviceId: payload.deviceId }, 'Connection rejected: token revoked');
      return next(new Error('Token has been revoked'));
    }

    // 注入到 socket.data
    socket.data.deviceId = payload.deviceId;
    socket.data.publicKey = payload.publicKey;
    socket.data.type = payload.type;

    next();
  });

  // ==================== Connection ====================

  io.on('connection', async (socket) => {
    const { deviceId, type, publicKey } = socket.data as JwtPayload;

    // 踢掉同设备旧连接
    const existing = devices.get(deviceId);
    if (existing) {
      logger.warn({ deviceId }, 'Duplicate connection, disconnecting old socket');
      existing.socket.disconnect(true);
    }

    // Load pairedWithId from DB so we can filter broadcasts correctly
    let pairedWithId: string | null = null;
    try {
      const dbDevice = await findDeviceById(deviceId);
      pairedWithId = dbDevice?.pairedWithId ?? null;
      socket.data.pairedWithId = pairedWithId;
    } catch (err) {
      logger.error({ err, deviceId }, 'Failed to load device pairing info');
    }

    devices.set(deviceId, {
      deviceId,
      type,
      publicKey,
      pairedWithId,
      socket,
      connectedAt: Date.now(),
    });

    logger.info({ deviceId, type, pairedWithId, socketId: socket.id }, 'Device connected');

    // 注册事件处理器
    registerApprovalHandlers(socket);

    // Heartbeat
    socket.on('heartbeat', () => {
      socket.emit('heartbeat_ack', { ts: Date.now() });
    });

    // 断连清理
    socket.on('disconnect', (reason) => {
      devices.delete(deviceId);
      logger.info({ deviceId, reason }, 'Device disconnected');
    });
  });

  logger.info('Socket.IO hub initialized');
  return io;
}

/**
 * Broadcast to all online iOS devices paired with a given Mac,
 * excluding one device (the one that made the decision).
 */
export function broadcastToIosDevices(
  macDeviceId: string,
  event: string,
  payload: unknown,
  excludeDeviceId?: string,
): number {
  let sent = 0;
  for (const [deviceId, device] of devices) {
    if (device.type !== 'ios') continue;
    if (deviceId === excludeDeviceId) continue;
    // Only send to iOS devices that are paired with this Mac
    if (device.pairedWithId !== macDeviceId) continue;
    device.socket.emit(event, payload);
    sent++;
  }
  if (sent > 0) {
    logger.debug({ macDeviceId, event, sent, excludeDeviceId }, 'Broadcast to iOS devices');
  }
  return sent;
}

/**
 * 关闭所有连接
 */
export function shutdownHub(): void {
  for (const [, device] of devices) {
    device.socket.disconnect(true);
  }
  devices.clear();
  if (io) io.close();
  logger.info('Hub shutdown');
}
