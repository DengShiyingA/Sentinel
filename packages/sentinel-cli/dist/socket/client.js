"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.connectSocket = connectSocket;
exports.emitApprovalRequest = emitApprovalRequest;
exports.getSocket = getSocket;
exports.disconnectSocket = disconnectSocket;
exports.isConnected = isConnected;
const socket_io_client_1 = require("socket.io-client");
const pending_1 = require("../relay/pending");
const logger_1 = require("../lib/logger");
let socket = null;
let reconnectAttempts = 0;
const MAX_RECONNECT = 10;
/**
 * 连接 Socket.IO，带 JWT auth 和指数退避重连
 */
function connectSocket(serverURL, token) {
    if (socket?.connected)
        return socket;
    socket = (0, socket_io_client_1.io)(serverURL, {
        auth: { token },
        transports: ['websocket', 'polling'],
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 30000,
        reconnectionAttempts: MAX_RECONNECT,
    });
    socket.on('connect', () => {
        reconnectAttempts = 0;
        logger_1.log.success(`Socket connected (id: ${socket.id})`);
    });
    socket.on('disconnect', (reason) => {
        logger_1.log.warn(`Socket disconnected: ${reason}`);
    });
    socket.on('connect_error', (err) => {
        reconnectAttempts++;
        const delay = Math.min(Math.pow(2, reconnectAttempts - 1) * 1000, 30000);
        logger_1.log.error(`Connection error: ${err.message} (retry in ${delay / 1000}s)`);
    });
    // ==================== 收到决策 ====================
    socket.on('decision', (data) => {
        logger_1.log.info(`Decision received: ${data.requestId} → ${data.action}`);
        pending_1.pending.resolve(data.requestId, data.action);
    });
    socket.on('heartbeat', () => {
        socket?.emit('heartbeat');
    });
    socket.on('heartbeat_ack', () => {
        logger_1.log.debug('Heartbeat ack');
    });
    return socket;
}
/**
 * 发送审批请求到 server，返回 requestId
 */
async function emitApprovalRequest(data) {
    return new Promise((resolve, reject) => {
        if (!socket?.connected) {
            return reject(new Error('Socket not connected'));
        }
        socket.emit('approval_request', data, (res) => {
            if (res.success && res.requestId) {
                resolve(res.requestId);
            }
            else {
                reject(new Error(res.error ?? 'Failed to send approval request'));
            }
        });
    });
}
function getSocket() {
    return socket;
}
function disconnectSocket() {
    socket?.disconnect();
    socket = null;
}
function isConnected() {
    return socket?.connected ?? false;
}
//# sourceMappingURL=client.js.map