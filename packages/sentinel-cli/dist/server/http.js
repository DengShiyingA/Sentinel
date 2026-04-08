"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createHttpServer = createHttpServer;
exports.startHttpServer = startHttpServer;
const express_1 = __importDefault(require("express"));
const zod_1 = require("zod");
const engine_1 = require("../rules/engine");
const interface_1 = require("../transport/interface");
const pending_1 = require("../relay/pending");
const logger_1 = require("../lib/logger");
const HookPayloadSchema = zod_1.z.object({
    tool_name: zod_1.z.string(),
    tool_input: zod_1.z.record(zod_1.z.unknown()),
});
function createHttpServer(port = 7749) {
    const app = (0, express_1.default)();
    app.use(express_1.default.json());
    app.post('/hook', async (req, res) => {
        const parsed = HookPayloadSchema.safeParse(req.body);
        if (!parsed.success) {
            logger_1.log.warn(`Invalid hook payload: ${parsed.error.message}`);
            return res.status(400).json({ error: 'Invalid payload' });
        }
        const { tool_name, tool_input } = parsed.data;
        const filePath = (tool_input.file_path ?? tool_input.path ?? null);
        logger_1.log.info(`Hook: ${tool_name}${filePath ? ` → ${filePath}` : ''}`);
        // 1. Local rules
        const match = (0, engine_1.matchRules)(tool_name, filePath);
        if (match.action === 'auto_allow') {
            logger_1.log.success(`Auto-allow: ${tool_name} (rule: ${match.rule?.id ?? 'default'})`);
            return res.json({ decision: 'allow' });
        }
        // 2. Check transport
        const transport = (0, interface_1.getTransport)();
        if (!transport || !transport.isConnected) {
            logger_1.log.error(`${transport?.mode ?? 'no'} transport not connected — blocking`);
            return res.json({ decision: 'block', reason: 'Sentinel offline' });
        }
        try {
            // 3. Send via current transport (local or remote)
            const requestId = await transport.sendApprovalRequest({
                toolName: tool_name,
                toolInput: tool_input,
                riskLevel: (0, engine_1.riskToLevel)(match.action),
            });
            logger_1.log.info(`[${transport.mode}] Waiting: ${requestId}`);
            // 4. Wait for decision
            const action = await pending_1.pending.waitForDecision(requestId, tool_name);
            if (action === 'allowed') {
                logger_1.log.success(`Allowed: ${tool_name} (${requestId})`);
                return res.json({ decision: 'allow' });
            }
            else {
                logger_1.log.warn(`Blocked: ${tool_name} (${requestId}) — ${action}`);
                return res.json({ decision: 'block', reason: action });
            }
        }
        catch (err) {
            logger_1.log.error(`Hook error: ${err.message}`);
            return res.json({ decision: 'block', reason: 'Internal error' });
        }
    });
    app.get('/status', (_req, res) => {
        const transport = (0, interface_1.getTransport)();
        res.json({
            mode: transport?.mode ?? 'none',
            connected: transport?.isConnected ?? false,
            pendingRequests: pending_1.pending.size,
            uptime: process.uptime(),
            version: '0.1.0',
        });
    });
    return app;
}
function startHttpServer(port = 7749) {
    return new Promise((resolve) => {
        const app = createHttpServer(port);
        app.listen(port, () => {
            logger_1.log.success(`Hook server listening on http://localhost:${port}`);
            logger_1.log.dim(`  POST /hook    — Claude Code PreToolUse endpoint`);
            logger_1.log.dim(`  GET  /status  — Sentinel status`);
            resolve();
        });
    });
}
//# sourceMappingURL=http.js.map