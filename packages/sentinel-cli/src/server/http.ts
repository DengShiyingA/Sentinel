import express from 'express';
import { z } from 'zod';
import { matchRules, riskToLevel } from '../rules/engine';
import { getTransport } from '../transport/interface';
import { pending } from '../relay/pending';
import { log } from '../lib/logger';

const HookPayloadSchema = z.object({
  tool_name: z.string(),
  tool_input: z.record(z.unknown()),
});

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

    log.info(`Hook: ${tool_name}${filePath ? ` → ${filePath}` : ''}`);

    // 1. Local rules
    const match = matchRules(tool_name, filePath);
    if (match.action === 'auto_allow') {
      log.success(`Auto-allow: ${tool_name} (rule: ${match.rule?.id ?? 'default'})`);
      return res.json({ decision: 'allow' });
    }

    // 2. Check transport
    const transport = getTransport();
    if (!transport || !transport.isConnected) {
      log.error(`${transport?.mode ?? 'no'} transport not connected — blocking`);
      return res.json({ decision: 'block', reason: 'Sentinel offline' });
    }

    try {
      // 3. Send via current transport (local or remote)
      const requestId = await transport.sendApprovalRequest({
        toolName: tool_name,
        toolInput: tool_input as Record<string, unknown>,
        riskLevel: riskToLevel(match.action),
      });

      log.info(`[${transport.mode}] Waiting: ${requestId}`);

      // 4. Wait for decision
      const action = await pending.waitForDecision(requestId, tool_name);

      if (action === 'allowed') {
        log.success(`Allowed: ${tool_name} (${requestId})`);
        return res.json({ decision: 'allow' });
      } else {
        log.warn(`Blocked: ${tool_name} (${requestId}) — ${action}`);
        return res.json({ decision: 'block', reason: action });
      }
    } catch (err) {
      log.error(`Hook error: ${(err as Error).message}`);
      return res.json({ decision: 'block', reason: 'Internal error' });
    }
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
      resolve();
    });
  });
}
