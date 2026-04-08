import express from 'express';
import { z } from 'zod';
import { randomBytes } from 'crypto';
import { matchRules, riskToLevel } from '../rules/engine';
import { getTransport } from '../transport/interface';
import { pending } from '../relay/pending';
import { appendLog } from '../lib/history';
import { getOverrideState } from '../lib/overrides';
import { isOverBudget } from '../lib/budget';
import { log } from '../lib/logger';

const HookPayloadSchema = z.object({
  tool_name: z.string(),
  tool_input: z.record(z.unknown()),
});

// SSE clients
const sseClients = new Set<express.Response>();

export function pushEvent(data: Record<string, unknown>): void {
  const msg = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of sseClients) {
    client.write(msg);
  }
}

export function createHttpServer(port: number = 7749): express.Application {
  const app = express();
  app.use(express.json());

  app.post('/hook', async (req, res) => {
    const parsed = HookPayloadSchema.safeParse(req.body);
    if (!parsed.success) {
      log.warn(`Invalid hook payload: ${parsed.error.message}`);
      return res.status(400).json({ error: 'Invalid payload' });
    }

    const { tool_name, tool_input } = parsed.data;
    const filePath = (tool_input.file_path ?? tool_input.path ?? null) as string | null;
    const requestId = randomBytes(8).toString('hex');
    const ts = new Date().toISOString();

    log.info(`Hook: ${tool_name}${filePath ? ` → ${filePath}` : ''}`);

    // 0. Check overrides (highest priority)
    const overrides = getOverrideState();
    if (overrides.blockAll) {
      log.warn(`BLOCKED (override): ${tool_name}`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: 'override', decision: 'blocked', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'blocked', reason: 'override' });
      return res.json({ decision: 'block', reason: 'blocked by sentinel block' });
    }
    if (overrides.allowAll) {
      log.success(`ALLOWED (override): ${tool_name}`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: 'override', decision: 'allowed', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'allowed', reason: 'override' });
      return res.json({ decision: 'allow' });
    }

    // 0.5 Budget warning (non-blocking, just logs)
    if (isOverBudget()) {
      log.warn(`⚠ Over daily budget!`);
    }

    // 1. Local rules
    const match = matchRules(tool_name, filePath);
    if (match.action === 'auto_allow') {
      log.success(`Auto-allow: ${tool_name} (rule: ${match.rule?.id ?? 'default'})`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: 'auto_allow', decision: 'auto_allow', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'allowed', reason: `auto:${match.rule?.id ?? ''}` });
      return res.json({ decision: 'allow' });
    }

    // 2. Check transport
    const transport = getTransport();
    if (!transport || !transport.isConnected) {
      log.error(`${transport?.mode ?? 'no'} transport not connected — blocking`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: riskToLevel(match.action), decision: 'offline', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'blocked', reason: 'offline' });
      return res.json({ decision: 'block', reason: 'Sentinel offline' });
    }

    try {
      // 3. Send via transport
      const remoteId = await transport.sendApprovalRequest({
        toolName: tool_name,
        toolInput: tool_input as Record<string, unknown>,
        riskLevel: riskToLevel(match.action),
      });

      log.info(`[${transport.mode}] Waiting: ${remoteId}`);

      // 4. Wait for decision
      const action = await pending.waitForDecision(remoteId, tool_name);

      appendLog({ id: remoteId, toolName: tool_name, filePath, riskLevel: riskToLevel(match.action), decision: action, timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: action === 'allowed' ? 'allowed' : 'blocked', reason: action === 'allowed' ? 'manual' : action });

      if (action === 'allowed') {
        log.success(`Allowed: ${tool_name} (${remoteId})`);
        return res.json({ decision: 'allow' });
      } else {
        log.warn(`Blocked: ${tool_name} (${remoteId}) — ${action}`);
        return res.json({ decision: 'block', reason: action });
      }
    } catch (err) {
      log.error(`Hook error: ${(err as Error).message}`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: riskToLevel(match.action), decision: 'blocked', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'blocked', reason: 'error' });
      return res.json({ decision: 'block', reason: 'Internal error' });
    }
  });

  // SSE endpoint for sentinel watch
  app.get('/events', (_req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    sseClients.add(res);
    res.on('close', () => sseClients.delete(res));
  });

  app.get('/status', (_req, res) => {
    const transport = getTransport();
    res.json({
      mode: transport?.mode ?? 'none',
      connected: transport?.isConnected ?? false,
      pendingRequests: pending.size,
      uptime: process.uptime(),
      version: '0.1.0',
    });
  });

  return app;
}

export function startHttpServer(port: number = 7749): Promise<void> {
  return new Promise((resolve) => {
    const app = createHttpServer(port);
    app.listen(port, () => {
      log.success(`Hook server listening on http://localhost:${port}`);
      log.dim(`  POST /hook    — Claude Code PreToolUse endpoint`);
      log.dim(`  GET  /status  — Sentinel status`);
      log.dim(`  GET  /events  — SSE stream (sentinel watch)`);
      resolve();
    });
  });
}
