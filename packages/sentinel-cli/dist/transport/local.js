"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LocalTransport = void 0;
const net_1 = __importDefault(require("net"));
const crypto_1 = require("crypto");
const bonjour_service_1 = require("bonjour-service");
const pending_1 = require("../relay/pending");
const logger_1 = require("../lib/logger");
const os_1 = require("os");
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
class LocalTransport {
    mode = 'local';
    server = null;
    bonjour = null;
    iosSocket = null;
    buffer = '';
    decisionCb = null;
    get isConnected() {
        return this.iosSocket !== null && !this.iosSocket.destroyed;
    }
    async start() {
        return new Promise((resolve, reject) => {
            this.server = net_1.default.createServer((socket) => {
                // Accept one iOS connection at a time
                if (this.iosSocket && !this.iosSocket.destroyed) {
                    logger_1.log.warn('[local] New connection replacing old one');
                    this.iosSocket.destroy();
                }
                this.iosSocket = socket;
                this.buffer = '';
                logger_1.log.success(`[local] iOS connected from ${socket.remoteAddress}`);
                socket.on('data', (chunk) => {
                    this.buffer += chunk.toString();
                    this.processBuffer();
                });
                socket.on('close', () => {
                    logger_1.log.warn('[local] iOS disconnected');
                    if (this.iosSocket === socket)
                        this.iosSocket = null;
                });
                socket.on('error', (err) => {
                    logger_1.log.error(`[local] Socket error: ${err.message}`);
                    if (this.iosSocket === socket)
                        this.iosSocket = null;
                });
            });
            this.server.listen(TCP_PORT, () => {
                logger_1.log.success(`[local] TCP server listening on port ${TCP_PORT}`);
                this.publishBonjour();
                resolve();
            });
            this.server.on('error', (err) => {
                logger_1.log.error(`[local] Server error: ${err.message}`);
                reject(err);
            });
        });
    }
    publishBonjour() {
        this.bonjour = new bonjour_service_1.Bonjour();
        this.bonjour.publish({
            name: `Sentinel-${process.env.USER ?? 'mac'}`,
            type: SERVICE_TYPE,
            protocol: PROTOCOL,
            port: TCP_PORT,
            txt: { version: '1' },
        });
        logger_1.log.success(`[local] Bonjour: publishing _${SERVICE_TYPE}._${PROTOCOL}`);
        const ip = getLocalIP();
        if (ip)
            logger_1.log.info(`[local] LAN address: ${ip}:${TCP_PORT}`);
    }
    /** Process newline-delimited JSON from buffer */
    processBuffer() {
        const lines = this.buffer.split('\n');
        this.buffer = lines.pop() ?? '';
        for (const line of lines) {
            if (!line.trim())
                continue;
            try {
                const msg = JSON.parse(line);
                this.handleMessage(msg);
            }
            catch {
                logger_1.log.debug(`[local] Invalid JSON: ${line.slice(0, 80)}`);
            }
        }
    }
    handleMessage(msg) {
        if (msg.event === 'decision') {
            const { requestId, action } = msg.data;
            logger_1.log.info(`[local] Decision: ${requestId} → ${action}`);
            pending_1.pending.resolve(requestId, action);
            this.decisionCb?.(requestId, action);
        }
        else if (msg.event === 'heartbeat_ack') {
            // iOS responded to heartbeat
        }
    }
    /** Send a JSON message to connected iOS */
    send(event, data) {
        if (!this.iosSocket || this.iosSocket.destroyed)
            return;
        const msg = JSON.stringify({ event, data }) + '\n';
        this.iosSocket.write(msg);
    }
    async sendApprovalRequest(payload) {
        if (!this.isConnected)
            throw new Error('iOS not connected');
        const requestId = (0, crypto_1.randomBytes)(12).toString('hex');
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
    onDecision(cb) {
        this.decisionCb = cb;
    }
    stop() {
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
    getConnectionInfo() {
        return { ip: getLocalIP() ?? '0.0.0.0', port: TCP_PORT };
    }
}
exports.LocalTransport = LocalTransport;
function getLocalIP() {
    const nets = (0, os_1.networkInterfaces)();
    for (const name of Object.keys(nets)) {
        for (const net of nets[name] ?? []) {
            if (net.family === 'IPv4' && !net.internal)
                return net.address;
        }
    }
    return null;
}
//# sourceMappingURL=local.js.map