import express from 'express';
import { z } from 'zod';
import { randomBytes } from 'crypto';
import { spawn } from 'child_process';
import { existsSync, readFileSync, unlinkSync, writeFileSync } from 'fs';
import { join } from 'path';
import { matchRules, riskToLevel } from '../rules/engine';
import { getTransport } from '../transport/interface';
import { pending } from '../relay/pending';
import { appendLog } from '../lib/history';
import { getOverrideState } from '../lib/overrides';
import { isOverBudget } from '../lib/budget';
import { summarize, summarizeStop } from '../lib/summarizer';
import { shouldAutoAllow, getMode } from '../lib/modes';
import { addSessionEvent, getCurrentSession, startSession } from '../lib/session';
import { generateDiff } from '../lib/diff';
import { getSentinelDir } from '../crypto/keys';
import { log } from '../lib/logger';

const HookPayloadSchema = z.object({
  tool_name: z.string(),
  tool_input: z.record(z.unknown()),
});

const PENDING_MSG_PATH = join(getSentinelDir(), 'pending_message.txt');

// SSE access token — generated at startup, required for /events and /terminal
const SSE_TOKEN = randomBytes(16).toString('hex');

// SSE clients
const sseClients = new Set<express.Response>();

export function pushEvent(data: Record<string, unknown>): void {
  const msg = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of sseClients) {
    client.write(msg);
  }
}

/** Send a terminal line to iOS via transport */
function sendTerminalLine(text: string): void {
  const transport = getTransport();
  if (transport?.isConnected) {
    transport.sendEvent?.({ type: 'terminal', text });
  }
  const msg = `data: ${JSON.stringify({ text, time: Date.now() })}\n\n`;
  for (const client of terminalClients) { client.write(msg); }
}

const terminalClients = new Set<express.Response>();

function sendActivity(type: string, data: Record<string, unknown>): void {
  const transport = getTransport();
  log.debug(`sendActivity: transport=${transport?.mode ?? 'null'} connected=${transport?.isConnected} hasSendEvent=${!!transport?.sendEvent}`);
  if (transport?.isConnected) {
    transport.sendEvent?.({ type, ...data, timestamp: new Date().toISOString() });
  }
}

export function createHttpServer(port: number = 7749): express.Application {
  const app = express();
  app.use(express.json({ limit: '512kb' }));

  // ==================== PreToolUse hook ====================
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

    // Auto-start session on first hook
    if (!getCurrentSession()) startSession();

    // 0. Check overrides
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

    if (isOverBudget()) log.warn('⚠ Over daily budget!');

    // 0.6 Permission mode check
    const modeResult = shouldAutoAllow(tool_name);
    if (modeResult === 'block') {
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: 'lockdown', decision: 'blocked', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'blocked', reason: 'lockdown' });
      return res.json({ decision: 'block', reason: 'lockdown mode' });
    }
    if (modeResult === 'auto_allow') {
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: 'mode', decision: 'auto_allow', timestamp: ts, summary: `${getMode()} mode` });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'allowed', reason: `mode:${getMode()}` });
      return res.json({ decision: 'allow' });
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
      log.error(`${transport?.mode ?? 'no'} transport offline — blocking`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: riskToLevel(match.action), decision: 'offline', timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: 'blocked', reason: 'offline' });
      return res.json({ decision: 'block', reason: 'Sentinel offline' });
    }

    try {
      // 为 Write/Edit 生成 diff
      const diff = generateDiff(tool_name, tool_input as Record<string, unknown>);

      const contextSummary = (req.body as Record<string, unknown>).context_summary as string | undefined
        ?? (req.body as Record<string, unknown>).contextSummary as string | undefined;

      const remoteId = await transport.sendApprovalRequest({
        toolName: tool_name,
        toolInput: tool_input as Record<string, unknown>,
        riskLevel: riskToLevel(match.action),
        diff,
        contextSummary,
      });

      log.info(`[${transport.mode}] Waiting: ${remoteId}`);
      const action = await pending.waitForDecision(remoteId, tool_name);

      appendLog({ id: remoteId, toolName: tool_name, filePath, riskLevel: riskToLevel(match.action), decision: action, timestamp: ts });
      pushEvent({ time: ts, tool: tool_name, path: filePath, decision: action === 'allowed' ? 'allowed' : 'blocked', reason: action === 'allowed' ? 'manual' : action });

      if (action === 'allowed') {
        log.success(`Allowed: ${tool_name} (${remoteId})`);
        sendTerminalLine(`✅ ${tool_name}${filePath ? ` → ${filePath}` : ''} — allowed`);
        return res.json({ decision: 'allow' });
      } else {
        log.warn(`Blocked: ${tool_name} (${remoteId}) — ${action}`);
        sendTerminalLine(`❌ ${tool_name}${filePath ? ` → ${filePath}` : ''} — ${action}`);
        return res.json({ decision: 'block', reason: action });
      }
    } catch (err) {
      log.error(`Hook error: ${(err as Error).message}`);
      appendLog({ id: requestId, toolName: tool_name, filePath, riskLevel: riskToLevel(match.action), decision: 'blocked', timestamp: ts });
      return res.json({ decision: 'block', reason: 'Internal error' });
    }
  });

  // ==================== PostToolUse / Notification / Stop events ====================
  app.post('/event', (req, res) => {
    const body = req.body ?? {};
    const hookEvent = body.hook_event_name ?? body.event ?? '';
    const ts = new Date().toISOString();

    if (hookEvent === 'PostToolUse' || hookEvent === 'post_tool_use') {
      const toolName = body.tool_name ?? body.toolName ?? 'unknown';
      const toolInput = body.tool_input ?? body.toolInput ?? {};
      const toolResponse = typeof body.tool_response === 'string' ? body.tool_response : JSON.stringify(body.tool_response ?? '').slice(0, 200);
      const summary = summarize(toolName, toolInput, toolResponse);

      log.dim(`[event] ${toolName}: ${summary}`);
      appendLog({ id: randomBytes(4).toString('hex'), toolName, filePath: (toolInput.file_path ?? toolInput.path ?? null) as string | null, riskLevel: 'completed', decision: 'completed', timestamp: ts, result: 'success', summary });
      sendActivity('tool_completed', { toolName, summary });
      pushEvent({ time: ts, type: 'tool_completed', tool: toolName, summary });

      // Terminal output: send tool response to iOS terminal view
      const responseText = typeof body.tool_response === 'string'
        ? body.tool_response
        : JSON.stringify(body.tool_response ?? '', null, 2);
      sendTerminalLine(`[${toolName}] ${summary}`);
      if (responseText && responseText.length > 2) {
        const lines = responseText.slice(0, 2000).split('\n');
        for (const line of lines) { sendTerminalLine(line); }
      }

    } else if (hookEvent === 'Notification' || hookEvent === 'notification') {
      const message = body.message ?? body.text ?? '';
      log.info(`[event] Notification: ${message}`);
      sendActivity('notification', { message });
      sendTerminalLine(`📢 ${message}`);

      // Also send system notification
      const transport = getTransport();
      if (transport?.isConnected && transport.sendNotification) {
        (transport as any).sendNotification('Claude Code', message);
      }
      pushEvent({ time: ts, type: 'notification', message });

    } else if (hookEvent === 'Stop' || hookEvent === 'stop') {
      const stopReason = body.stop_reason ?? body.reason ?? 'completed';
      const summary = summarizeStop(stopReason);
      log.info(`[event] Stop: ${summary}`);
      sendActivity('stop', { stopReason, summary });
      addSessionEvent({ type: 'stop', stopReason, summary, timestamp: ts });

      // Send system notification (important — user may not be looking)
      const transport = getTransport();
      if (transport?.isConnected && transport.sendNotification) {
        const isError = stopReason === 'error';
        (transport as any).sendNotification(
          isError ? '❌ Claude Code' : '✅ Claude Code',
          summary,
        );
      }
      pushEvent({ time: ts, type: 'stop', stopReason, summary });

      // Check for pending user message → auto-resume
      if (existsSync(PENDING_MSG_PATH)) {
        try {
          const msg = readFileSync(PENDING_MSG_PATH, 'utf-8').trim();
          unlinkSync(PENDING_MSG_PATH);
          if (msg) {
            log.info(`[event] Resuming Claude with message: ${msg.slice(0, 50)}...`);
            const child = spawn('claude', ['--continue', '--print', msg], {
              detached: true, stdio: 'ignore',
            });
            child.unref();
          }
        } catch {}
      }

    } else if (hookEvent === 'TaskCompleted' || hookEvent === 'task_completed') {
      log.info('[event] Task completed');
      sendActivity('task_completed', { summary: 'Sub-task completed' });
      pushEvent({ time: ts, type: 'task_completed' });

    } else if (hookEvent === 'SessionEnd' || hookEvent === 'session_end') {
      log.info('[event] Session ended');
      sendActivity('session_ended', { summary: 'Session ended' });
      pushEvent({ time: ts, type: 'session_ended' });
    }

    res.json({ ok: true });
  });

  // ==================== Notify endpoint ====================
  app.post('/notify', (req, res) => {
    const { title, message } = req.body ?? {};
    if (!message) return res.status(400).json({ error: 'message required' });
    const transport = getTransport();
    if (!transport?.isConnected) return res.status(503).json({ error: 'iOS not connected' });
    if (transport.sendNotification) {
      transport.sendNotification(title ?? 'Sentinel', message);
    } else {
      return res.status(501).json({ error: 'Not supported' });
    }
    log.info(`Notification: ${title ?? 'Sentinel'} — ${message}`);
    res.json({ success: true });
  });

  // ==================== User message from iOS ====================
  app.post('/user-message', (req, res) => {
    const text = req.body?.text;
    if (!text) return res.status(400).json({ error: 'text required' });
    writeFileSync(PENDING_MSG_PATH, text);
    log.info(`Pending message saved: ${text.slice(0, 50)}`);
    res.json({ success: true });
  });

  // ==================== SSE Auth Middleware ====================
  function requireSseToken(req: express.Request, res: express.Response): boolean {
    const token = req.query.token as string | undefined;
    if (token !== SSE_TOKEN) {
      res.status(401).json({ error: 'Invalid or missing SSE token' });
      return false;
    }
    return true;
  }

  // ==================== Terminal SSE ====================
  app.get('/terminal', (req, res) => {
    if (!requireSseToken(req, res)) return;
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();
    terminalClients.add(res);
    res.on('close', () => terminalClients.delete(res));
  });

  // ==================== SSE ====================
  app.get('/events', (req, res) => {
    if (!requireSseToken(req, res)) return;
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();
    sseClients.add(res);
    res.on('close', () => sseClients.delete(res));
  });

  // ==================== SSE Token (for CLI watch command) ====================
  app.get('/sse-token', (_req, res) => {
    // Only accessible from localhost
    res.json({ token: SSE_TOKEN });
  });

  // ==================== Status ====================
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
      log.dim(`  POST /hook    — PreToolUse (approval)`);
      log.dim(`  POST /event   — PostToolUse / Notification / Stop`);
      log.dim(`  GET  /events  — SSE stream`);
      resolve();
    });
  });
}

/** Setup user message handler from LocalTransport */
export function setupUserMessageHandler(): void {
  const transport = getTransport();
  if (transport && 'onUserMessage' in transport) {
    (transport as any).onUserMessage((text: string) => {
      writeFileSync(PENDING_MSG_PATH, text);
      log.info(`Message from iOS saved: ${text.slice(0, 50)}`);
    });
  }
}
