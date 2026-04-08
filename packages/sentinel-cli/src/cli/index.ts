#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import qrcode from 'qrcode-terminal';
import { ensureToken, loadToken, getStoredServerURL } from '../api/client';
import { startHttpServer, setupUserMessageHandler } from '../server/http';
import { installHook, uninstallHook } from '../install/setup';
import { getRules, watchRules, setCustomRules, matchRules } from '../rules/engine';
import { getPublicKeyBase64 } from '../crypto/keys';
import { pending } from '../relay/pending';
import { setTransport, getTransport, type TransportMode } from '../transport/interface';
import { createTransport } from '../transport/factory';
import { LocalTransport } from '../transport/local';
import { getHistory, getTodayStats } from '../lib/history';
import { setBudgetLimit, getBudgetStatus, isOverBudget } from '../lib/budget';
import { setBlockAll, setAllowAll, getOverrideInfo, getOverrideState } from '../lib/overrides';
import { runDoctor } from '../lib/doctor';
import { daemonStart, daemonStop, daemonStatus, daemonRestart } from '../lib/daemon';
import { log } from '../lib/logger';

const program = new Command();

program
  .name('sentinel')
  .description('Sentinel — Claude Code 移动端审批规则引擎')
  .version('0.1.0');

function parseMode(value: string): TransportMode {
  if (['local', 'cloudkit', 'server'].includes(value)) return value as TransportMode;
  log.error(`Invalid mode: ${value}. Use: local, cloudkit, server`);
  process.exit(1);
}

function parseDuration(val: string): number {
  const match = val.match(/^(\d+)(m|h)?$/);
  if (!match) return parseInt(val, 10) || 30;
  const num = parseInt(match[1], 10);
  if (match[2] === 'h') return num * 60;
  return num; // default minutes
}

// ==================== sentinel start ====================

program
  .command('start')
  .description('启动 Sentinel（HTTP hook 服务 + iOS 连接）')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .option('-m, --mode <mode>', '连接模式: local | cloudkit | server', 'local')
  .option('-s, --server <url>', '服务器地址（server 模式必须）')
  .option('-d, --daemon', '后台运行')
  .action(async (opts) => {
    const port = parseInt(opts.port, 10);
    const mode = parseMode(opts.mode);

    // Daemon mode: fork and exit
    if (opts.daemon) {
      daemonStart(mode, port, opts.server);
      return;
    }

    const modeLabels: Record<TransportMode, string> = {
      local: '局域网直连', cloudkit: 'CloudKit 同步', server: '自建服务器',
    };

    console.log(chalk.bold('\n  🛡️  Sentinel CLI\n'));
    log.info(`Mode: ${modeLabels[mode]}`);

    // Show active overrides
    const ov = getOverrideState();
    if (ov.blockAll) console.log(chalk.bgRed.white.bold('  ⛔ BLOCK ALL active — all requests will be blocked  '));
    if (ov.allowAll) console.log(chalk.bgGreen.white.bold('  ✅ ALLOW ALL active — all requests will be allowed  '));
    if (isOverBudget()) log.warn('⚠ Over daily budget!');

    if (mode === 'server') {
      const serverURL = opts.server ?? getStoredServerURL();
      if (!serverURL) { log.error('Server mode requires -s URL.'); process.exit(1); }
      log.info('Authenticating...');
      const tokenData = await ensureToken(serverURL);
      const transport = createTransport('server', { serverUrl: serverURL, token: tokenData.token });
      setTransport(transport);
      log.info(`Connecting to ${serverURL}...`);
      await transport.start();
    } else if (mode === 'cloudkit') {
      const transport = createTransport('cloudkit');
      setTransport(transport);
      await transport.start();
    } else {
      const transport = createTransport('local');
      setTransport(transport);
      await transport.start();
      if (transport instanceof LocalTransport) {
        const info = transport.getConnectionInfo();
        log.info(`iOS can connect to: ${info.ip}:${info.port}`);
        transport.onRulesUpdate((rules) => setCustomRules(rules));
      }
    }

    watchRules();
    await startHttpServer(port);
    setupUserMessageHandler();

    console.log('');
    log.success('Sentinel is running. Press Ctrl+C to stop.\n');

    const shutdown = () => {
      console.log('');
      log.info('Shutting down...');
      pending.clear();
      getTransport()?.stop();
      process.exit(0);
    };
    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
  });

// ==================== sentinel install / uninstall ====================

program.command('install').description('注入 PreToolUse hook 到 Claude Code 配置')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .action((opts) => { installHook(parseInt(opts.port, 10)); });

program.command('uninstall').description('从 Claude Code 配置移除 Sentinel hook')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .action((opts) => { uninstallHook(parseInt(opts.port, 10)); });

// ==================== sentinel pair ====================

program.command('pair').description('配对 iOS 设备')
  .option('-m, --mode <mode>', '连接模式: local | cloudkit | server', 'local')
  .option('-s, --server <url>', '服务器地址（server 模式必须）')
  .action(async (opts) => {
    const mode = parseMode(opts.mode);
    if (mode === 'local') {
      const transport = new LocalTransport();
      await transport.start();
      const info = transport.getConnectionInfo();
      console.log(chalk.bold('\n  📡 局域网模式\n'));
      log.success(`TCP server: ${info.ip}:${info.port}`);
      log.info('iOS 端选择"局域网"模式，会自动发现\n');
      log.dim('等待 iOS 连接... (Ctrl+C 退出)');
      const check = setInterval(() => {
        if (transport.isConnected) {
          clearInterval(check);
          log.success('iOS 已连接！');
          setTimeout(() => { transport.stop(); process.exit(0); }, 2000);
        }
      }, 1000);
      process.on('SIGINT', () => { transport.stop(); process.exit(0); });
    } else if (mode === 'cloudkit') {
      console.log(chalk.bold('\n  ☁️  CloudKit 模式\n'));
      log.info('CloudKit 模式无需配对。确保同一 Apple ID。\n');
    } else {
      const serverURL = opts.server ?? getStoredServerURL();
      if (!serverURL) { log.error('Server mode requires -s URL.'); process.exit(1); }
      const tokenData = await ensureToken(serverURL);
      log.info('Generating pair link...');
      const res = await fetch(`${serverURL}/v1/pair/link`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: tokenData.token }),
      });
      if (!res.ok) { log.error(`Failed: ${await res.text()}`); process.exit(1); }
      const json = (await res.json()) as { success: boolean; data: { link: string; expiresIn: number } };
      if (!json.success) { log.error('Server error'); process.exit(1); }
      const { link, expiresIn } = json.data;
      console.log(chalk.bold('\n  📱 Scan QR code:\n'));
      qrcode.generate(link, { small: true }, (qr: string) => { console.log(qr); });
      console.log(`  ${chalk.dim('Link:')} ${chalk.cyan(link)}\n`);
      const poll = setInterval(async () => {
        try {
          const sr = await fetch(`${serverURL}/v1/pair/status?token=${encodeURIComponent(tokenData.token)}`);
          const sj = (await sr.json()) as { data: { paired: boolean; pairedDevice?: { name: string } } };
          if (sj.data?.paired) { clearInterval(poll); log.success(`Paired: ${sj.data.pairedDevice?.name ?? '?'}`); process.exit(0); }
        } catch {}
      }, 2000);
      setTimeout(() => { clearInterval(poll); log.warn('Expired.'); process.exit(1); }, expiresIn * 1000);
    }
  });

// ==================== sentinel status ====================

program.command('status').description('查看 Sentinel 状态').action(async () => {
  const token = loadToken();
  console.log(chalk.bold('\n  🛡️  Sentinel Status\n'));
  if (token) { log.success(`Server: ${token.serverURL}`); log.success(`Device: ${token.deviceId}`); }
  else { log.warn('Not authenticated (server mode)'); }
  log.info(`Public key: ${getPublicKeyBase64().slice(0, 16)}...`);
  try {
    const res = await fetch('http://localhost:7749/status');
    const data = (await res.json()) as Record<string, unknown>;
    log.success(`Hook server: running (mode=${data.mode}, ${data.pendingRequests} pending)`);
    log.info(`Connected: ${data.connected}`);
  } catch { log.warn('Hook server: not running'); }

  log.info(`Rules: ${getRules().length} loaded`);

  // Overrides
  const ov = getOverrideInfo();
  if (ov.blockAll) log.warn(`BLOCK ALL active${ov.blockUntil ? ` (until ${new Date(ov.blockUntil).toLocaleTimeString()})` : ''}`);
  if (ov.allowAll) log.warn(`ALLOW ALL active${ov.allowUntil ? ` (until ${new Date(ov.allowUntil).toLocaleTimeString()})` : ''}`);

  // Budget
  const b = getBudgetStatus();
  log.info(`Budget: $${b.spent.toFixed(4)} / $${b.limit.toFixed(2)} (${b.calls} calls)${b.overBudget ? chalk.red(' ⚠ OVER') : ''}`);

  // Today stats
  const stats = getTodayStats();
  if (stats.total > 0) {
    console.log(`\n  ${chalk.green(`✓ ${stats.allowed} allowed`)}  ${chalk.red(`✗ ${stats.blocked} blocked`)}  ${chalk.yellow(`⏱ ${stats.timeout} timeout`)}  ${chalk.dim(`⚡ ${stats.autoAllow} auto`)}`);
    if (stats.lastRequestTime) log.dim(`  Last: ${new Date(stats.lastRequestTime).toLocaleTimeString()}`);
  }
  console.log('');
});

// ==================== sentinel rules ====================

program.command('rules').description('列出当前规则').action(() => {
  const rules = getRules();
  console.log(chalk.bold('\n  📋 Rules\n'));
  for (const rule of rules.sort((a, b) => a.priority - b.priority)) {
    const risk = rule.risk === 'auto_allow' ? chalk.green('allow') : rule.risk === 'require_confirm' ? chalk.yellow('confirm') : chalk.red('faceid');
    const tool = rule.toolPattern ? chalk.cyan(rule.toolPattern) : chalk.dim('*');
    const path = rule.pathPattern ? chalk.magenta(rule.pathPattern) : chalk.dim('*');
    console.log(`  ${chalk.dim(`[${rule.priority}]`)} ${risk}  ${tool}  ${path}  ${chalk.dim(rule.description)}`);
  }
  console.log('');
});

// ==================== sentinel logs ====================

program.command('logs').description('查看审批历史')
  .option('-n, --count <n>', '显示条数', '20')
  .action((opts) => {
    const count = parseInt(opts.count, 10) || 20;
    const history = getHistory().slice(0, count);
    console.log(chalk.bold('\n  📜 Approval History\n'));
    if (history.length === 0) { log.dim('No history yet.'); console.log(''); return; }
    console.log(`  ${chalk.dim('Time'.padEnd(10))} ${chalk.dim('Tool'.padEnd(12))} ${chalk.dim('Path'.padEnd(30))} ${chalk.dim('Risk'.padEnd(10))} ${chalk.dim('Decision')}`);
    console.log(chalk.dim('  ' + '─'.repeat(80)));
    for (const e of history) {
      const time = new Date(e.timestamp).toLocaleTimeString('en', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const tool = e.toolName.padEnd(12).slice(0, 12);
      const path = (e.filePath ?? '—').padEnd(30).slice(0, 30);
      const risk = e.riskLevel === 'auto_allow' ? chalk.dim('auto'.padEnd(10)) : e.riskLevel === 'high' ? chalk.red('high'.padEnd(10)) : chalk.yellow(e.riskLevel.padEnd(10));
      const dec = e.decision === 'allowed' || e.decision === 'auto_allow' ? chalk.green(e.decision) : e.decision === 'blocked' ? chalk.red('blocked') : e.decision === 'timeout' ? chalk.yellow('timeout') : chalk.gray(e.decision);
      console.log(`  ${chalk.dim(time)} ${chalk.cyan(tool)} ${path} ${risk} ${dec}`);
    }
    console.log(chalk.dim(`\n  ${history.length} of ${getHistory().length} entries\n`));
  });

// ==================== sentinel budget ====================

const budget = program.command('budget').description('预算管理');

budget.command('set <amount>').description('设置每日上限（美元）').action((amount: string) => {
  const val = parseFloat(amount);
  if (isNaN(val) || val <= 0) { log.error('Invalid amount'); process.exit(1); }
  setBudgetLimit(val);
  log.success(`Daily budget set to $${val.toFixed(2)}`);
});

budget.command('status').description('查看今日花费').action(() => {
  const b = getBudgetStatus();
  console.log(chalk.bold('\n  💰 Budget\n'));
  console.log(`  Limit:     $${b.limit.toFixed(2)}`);
  console.log(`  Spent:     $${b.spent.toFixed(4)} (${b.calls} calls)`);
  console.log(`  Remaining: ${b.overBudget ? chalk.red('$0.00 ⚠ OVER BUDGET') : chalk.green(`$${b.remaining.toFixed(4)}`)}`);
  console.log('');
});

budget.command('reset').description('重置今日统计').action(() => {
  setBudgetLimit(getBudgetStatus().limit); // re-save to touch file
  log.success('Budget tracking noted. History preserved.');
});

// ==================== sentinel block ====================

const block = program.command('block').description('快速封锁所有请求');

block.command('on').description('开启全局封锁')
  .option('-u, --until <duration>', '封锁时长（如 30m, 2h）')
  .action((opts) => {
    const minutes = opts.until ? parseDuration(opts.until) : undefined;
    setBlockAll(true, minutes);
    if (minutes) {
      log.success(`Block ALL enabled for ${minutes} minutes (until ${new Date(Date.now() + minutes * 60000).toLocaleTimeString()})`);
    } else {
      log.success('Block ALL enabled (indefinite). Run `sentinel block off` to disable.');
    }
  });

block.command('off').description('关闭封锁').action(() => {
  setBlockAll(false);
  log.success('Block ALL disabled. Normal rules restored.');
});

// ==================== sentinel allow ====================

const allow = program.command('allow').description('临时放行所有请求');

allow.command('on').description('开启全局放行')
  .option('-u, --until <duration>', '放行时长（如 30m, 2h）')
  .action((opts) => {
    const minutes = opts.until ? parseDuration(opts.until) : undefined;
    setAllowAll(true, minutes);
    if (minutes) {
      log.success(`Allow ALL enabled for ${minutes} minutes`);
    } else {
      log.success('Allow ALL enabled (indefinite). Run `sentinel allow off` to disable.');
    }
  });

allow.command('off').description('关闭放行').action(() => {
  setAllowAll(false);
  log.success('Allow ALL disabled. Normal rules restored.');
});

// ==================== sentinel watch ====================

program.command('watch').description('实时监控工具调用').action(async () => {
  console.log(chalk.bold('\n  👁  Sentinel Watch\n'));
  log.dim('Streaming events from http://localhost:7749/events ...\n');
  console.log(`  ${chalk.dim('Time'.padEnd(10))} ${chalk.dim('Tool'.padEnd(12))} ${chalk.dim('Path'.padEnd(28))} ${chalk.dim('Decision'.padEnd(10))} ${chalk.dim('Reason')}`);
  console.log(chalk.dim('  ' + '─'.repeat(75)));

  try {
    const res = await fetch('http://localhost:7749/events');
    if (!res.ok || !res.body) { log.error('Failed to connect to SSE endpoint'); process.exit(1); }

    const decoder = new TextDecoder();
    const reader = res.body.getReader();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() ?? '';

      for (const line of lines) {
        if (!line.startsWith('data: ')) continue;
        try {
          const data = JSON.parse(line.slice(6));
          const time = new Date(data.time).toLocaleTimeString('en', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
          const tool = (data.tool ?? '?').padEnd(12).slice(0, 12);
          const path = (data.path ?? '—').padEnd(28).slice(0, 28);
          const dec = data.decision === 'allowed' ? chalk.green('allowed'.padEnd(10)) : chalk.red('blocked'.padEnd(10));
          const reason = chalk.dim(data.reason ?? '');
          console.log(`  ${chalk.dim(time)} ${chalk.cyan(tool)} ${path} ${dec} ${reason}`);
        } catch {}
      }
    }
  } catch (err) {
    log.error(`Watch failed: ${(err as Error).message}`);
    log.dim('Is sentinel start running?');
  }
});

// ==================== sentinel test ====================

const test = program.command('test').description('测试验证');

test.command('hook').description('发送测试 hook 请求').action(async () => {
  log.info('Sending test Write request to localhost:7749/hook ...');
  try {
    const res = await fetch('http://localhost:7749/hook', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tool_name: 'Write', tool_input: { file_path: '/test/sentinel-test.ts', content: '// test' } }),
    });
    const data = await res.json();
    log.success(`Response: ${JSON.stringify(data)}`);
  } catch (err) {
    log.error(`Failed: ${(err as Error).message}. Is \`sentinel start\` running?`);
  }
});

test.command('notify').description('发送测试通知到 iOS').action(async () => {
  const transport = getTransport();
  if (!transport) {
    // Try via HTTP
    try {
      const status = await (await fetch('http://localhost:7749/status')).json() as Record<string, unknown>;
      if (status.connected) {
        log.info('Sending test via hook server...');
        const res = await fetch('http://localhost:7749/hook', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ tool_name: 'Bash', tool_input: { command: 'echo sentinel-test' } }),
        });
        log.success(`Sent! Response: ${JSON.stringify(await res.json())}`);
      } else {
        log.warn('No iOS connected. Connect first.');
      }
    } catch {
      log.error('Hook server not running.');
    }
    return;
  }
  if (!transport.isConnected) { log.warn('Transport not connected. Connect iOS first.'); return; }
  log.info('Sending test approval request to iOS...');
  try {
    const id = await transport.sendApprovalRequest({ toolName: 'Bash', toolInput: { command: 'echo sentinel-test' }, riskLevel: 'medium' });
    log.success(`Sent! Request ID: ${id}. Check iOS.`);
  } catch (err) {
    log.error(`Failed: ${(err as Error).message}`);
  }
});

test.command('rules').description('测试规则匹配').action(() => {
  console.log(chalk.bold('\n  🧪 Rules Test\n'));
  const cases = [
    { tool: 'Read', path: '/src/main.ts' },
    { tool: 'Write', path: '/src/main.ts' },
    { tool: 'Edit', path: '/src/main.ts' },
    { tool: 'Bash', path: null },
    { tool: 'Glob', path: null },
    { tool: 'Grep', path: null },
    { tool: 'Write', path: '/tmp/test.txt' },
    { tool: 'Write', path: '.env.local' },
    { tool: 'Read', path: '/secrets/key.pem' },
    { tool: 'Unknown', path: '/foo/bar' },
  ];
  for (const c of cases) {
    const result = matchRules(c.tool, c.path);
    const action = result.action === 'auto_allow' ? chalk.green('allow') : result.action === 'require_confirm' ? chalk.yellow('confirm') : chalk.red('faceid');
    const rule = result.rule ? chalk.dim(`(${result.rule.id})`) : chalk.dim('(default)');
    console.log(`  ${chalk.cyan(c.tool.padEnd(8))} ${(c.path ?? '—').padEnd(25)} → ${action}  ${rule}`);
  }
  console.log('');
});

// ==================== sentinel doctor ====================

program.command('doctor').description('系统诊断').action(async () => {
  await runDoctor();
});

// ==================== sentinel notify ====================

program.command('notify <message>').description('发送通知到 iOS')
  .option('-t, --title <title>', '通知标题', 'Sentinel')
  .action(async (message: string, opts) => {
    const title = opts.title;

    // Try via running server first
    try {
      const statusRes = await fetch('http://localhost:7749/status');
      const status = (await statusRes.json()) as Record<string, unknown>;
      if (!status.connected) {
        log.error('iOS not connected');
        process.exit(1);
      }

      // Send via a special hook that the server relays
      const res = await fetch('http://localhost:7749/notify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, message }),
      });

      if (res.ok) {
        log.success(`Notification sent: "${message}"`);
      } else {
        log.error('Failed to send notification');
      }
    } catch {
      log.error('Hook server not running. Start sentinel first.');
    }
  });

// ==================== sentinel daemon ====================

const daemon = program.command('daemon').description('后台服务管理');

daemon.command('start').description('后台启动 Sentinel')
  .option('-m, --mode <mode>', '连接模式', 'local')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .option('-s, --server <url>', '服务器地址')
  .action((opts) => {
    daemonStart(opts.mode, parseInt(opts.port, 10), opts.server);
  });

daemon.command('stop').description('停止后台服务').action(() => {
  daemonStop();
});

daemon.command('status').description('查看后台服务状态').action(async () => {
  await daemonStatus();
});

daemon.command('restart').description('重启后台服务')
  .option('-m, --mode <mode>', '连接模式', 'local')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .option('-s, --server <url>', '服务器地址')
  .action((opts) => {
    daemonRestart(opts.mode, parseInt(opts.port, 10), opts.server);
  });

program.parse();
