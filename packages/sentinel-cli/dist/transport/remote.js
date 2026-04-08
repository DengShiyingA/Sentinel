"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RemoteTransport = void 0;
const socket_io_client_1 = require("socket.io-client");
const pending_1 = require("../relay/pending");
const logger_1 = require("../lib/logger");
/**
 * Remote transport — wraps existing Socket.IO client for server-relay mode.
 */
class RemoteTransport {
    serverURL;
    token;
    mode = 'server';
    socket = null;
    decisionCb = null;
    constructor(serverURL, token) {
        this.serverURL = serverURL;
        this.token = token;
    }
    get isConnected() {
        return this.socket?.connected ?? false;
    }
    async start() {
        this.socket = (0, socket_io_client_1.io)(this.serverURL, {
            auth: { token: this.token },
            transports: ['websocket', 'polling'],
            reconnection: true,
            reconnectionDelay: 1000,
            reconnectionDelayMax: 30000,
            reconnectionAttempts: 10,
        });
        this.socket.on('connect', () => {
            logger_1.log.success(`[remote] Connected to ${this.serverURL}`);
        });
        this.socket.on('disconnect', (reason) => {
            logger_1.log.warn(`[remote] Disconnected: ${reason}`);
        });
        this.socket.on('connect_error', (err) => {
            logger_1.log.error(`[remote] Connection error: ${err.message}`);
        });
        this.socket.on('decision', (data) => {
            logger_1.log.info(`[remote] Decision: ${data.requestId} → ${data.action}`);
            pending_1.pending.resolve(data.requestId, data.action);
            this.decisionCb?.(data.requestId, data.action);
        });
        this.socket.on('heartbeat', () => {
            this.socket?.emit('heartbeat');
        });
        // Wait for initial connection
        await new Promise((resolve) => {
            const timeout = setTimeout(() => resolve(), 5000);
            this.socket.once('connect', () => { clearTimeout(timeout); resolve(); });
        });
    }
    async sendApprovalRequest(payload) {
        return new Promise((resolve, reject) => {
            if (!this.socket?.connected)
                return reject(new Error('Not connected'));
            this.socket.emit('approval_request', payload, (res) => {
                if (res.success && res.requestId)
                    resolve(res.requestId);
                else
                    reject(new Error(res.error ?? 'Failed'));
            });
        });
    }
    onDecision(cb) {
        this.decisionCb = cb;
    }
    stop() {
        this.socket?.disconnect();
        this.socket = null;
    }
}
exports.RemoteTransport = RemoteTransport;
//# sourceMappingURL=remote.js.map