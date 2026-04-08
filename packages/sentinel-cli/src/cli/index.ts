#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import qrcode from 'qrcode-terminal';
import { ensureToken, loadToken, getStoredServerURL } from '../api/client';
import { startHttpServer } from '../server/http';
import { installHook, uninstallHook } from '../install/setup';
import { getRules, watchRules, setCustomRules } from '../rules/engine';
import { getPublicKeyBase64 } from '../crypto/keys';
import { pending } from '../relay/pending';
import { setTransport, getTransport, type TransportMode } from '../transport/interface';
import { createTransport } from '../transport/factory';
import { LocalTransport } from '../transport/local';
import { getHistory, getTodayStats } from '../lib/history';
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

// ==================== sentinel start ====================

program
  .command('start')
  .description('启动 Sentinel（HTTP hook 服务 + iOS 连接）')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .option('-m, --mode <mode>', '连接模式: local | cloudkit | server', 'local')
  .option('-s, --server <url>', '服务器地址（server 模式必须）')
  .action(async (opts) => {
    const port = parseInt(opts.port, 10);
    const mode = parseMode(opts.mode);

    const modeLabels: Record<TransportMode, string> = {
      local: '局域网直连',
      cloudkit: 'CloudKit 同步',
      server: '自建服务器',
    };

    console.log(chalk.bold('\n  🛡️  Sentinel CLI\n'));
    log.info(`Mode: ${modeLabels[mode]}`);

    if (mode === 'server') {
      const serverURL = opts.server ?? getStoredServerURL();
      if (!serverURL) {
        log.error('Server mode requires -s URL.');
        process.exit(1);
      }
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

    // Start rules hot-reload
    watchRules();

    await startHttpServer(port);

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

program
  .command('install')
  .description('注入 PreToolUse hook 到 Claude Code 配置')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .action((opts) => { installHook(parseInt(opts.port, 10)); });

program
  .command('uninstall')
  .description('从 Claude Code 配置移除 Sentinel hook')
  .option('-p, --port <port>', 'HTTP hook 端口', '7749')
  .action((opts) => { uninstallHook(parseInt(opts.port, 10)); });

// ==================== sentinel pair ====================

program
  .command('pair')
  .description('配对 iOS 设备')
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
      log.info('CloudKit 模式无需配对。');
      log.info('确保 Mac 和 iPhone 登录同一 Apple ID。');
      log.dim('在 iOS 端选择 "CloudKit" 模式即可。\n');

    } else {
      const serverURL = opts.server ?? getStoredServerURL();
      if (!serverURL) { log.error('Server mode requires -s URL.'); process.exit(1); }
      const tokenData = await ensureToken(serverURL);

      log.info('Generating pair link...');
      const res = await fetch(`${serverURL}/v1/pair/link`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: tokenData.token }),
      });
      if (!res.ok) { log.error(`Failed: ${await res.text()}`); process.exit(1); }
      const json = (await res.json()) as { success: boolean; data: { link: string; expiresIn: number } };
      if (!json.success) { log.error('Server error'); process.exit(1); }

      const { link, expiresIn } = json.data;
      console.log(chalk.bold('\n  📱 Scan this QR code with Sentinel iOS:\n'));
      qrcode.generate(link, { small: true }, (qr: string) => { console.log(qr); });
      console.log(`  ${chalk.dim('Link:')} ${chalk.cyan(link)}`);
      console.log(`  ${chalk.dim('Expires:')} ${expiresIn}s\n`);

      log.info('Waiting for iOS...');
      const poll = setInterval(async () => {
        try {
          const sr = await fetch(`${serverURL}/v1/pair/status?token=${encodeURIComponent(tokenData.token)}`);
          const sj = (await sr.json()) as { data: { paired: boolean; pairedDevice?: { name: string } } };
          if (sj.data?.paired) {
            clearInterval(poll);
            log.success(`Paired: ${sj.data.pairedDevice?.name ?? 'unknown'}`);
            process.exit(0);
          }
        } catch { /* retry */ }
      }, 2000);
      setTimeout(() => { clearInterval(poll); log.warn('Expired.'); process.exit(1); }, expiresIn * 1000);
    }
  });

// ==================== sentinel status ====================

program
  .command('status')
  .description('查看 Sentinel 状态')
  .action(async () => {
    const token = loadToken();
    console.log(chalk.bold('\n  🛡️  Sentinel Status\n'));

    // Auth
    if (token) {
      log.success(`Server: ${token.serverURL}`);
      log.success(`Device: ${token.deviceId}`);
    } else {
      log.warn('Not authenticated (server mode)');
    }
    log.info(`Public key: ${getPublicKeyBase64().slice(0, 16)}...`);

    // Hook server
    try {
      const res = await fetch('http://localhost:7749/status');
      const data = (await res.json()) as Record<string, unknown>;
      log.success(`Hook server: running (mode=${data.mode}, ${data.pendingRequests} pending)`);
      log.info(`Connected: ${data.connected}`);
    } catch {
      log.warn('Hook server: not running');
    }

    // Rules
    const rules = getRules();
    log.info(`Rules: ${rules.length} loaded`);

    // Today stats
    const stats = getTodayStats();
    if (stats.total > 0) {
      console.log('');
      log.info(chalk.bold('Today:'));
      console.log(`  ${chalk.green(`✓ ${stats.allowed} allowed`)}  ${chalk.red(`✗ ${stats.blocked} blocked`)}  ${chalk.yellow(`⏱ ${stats.timeout} timeout`)}  ${chalk.dim(`⚡ ${stats.autoAllow} auto`)}  ${chalk.dim(`⬚ ${stats.offline} offline`)}`);
      if (stats.lastRequestTime) {
        const t = new Date(stats.lastRequestTime);
        log.dim(`  Last request: ${t.toLocaleTimeString()}`);
      }
    } else {
      log.dim('No requests today');
    }

    console.log('');
  });

// ==================== sentinel rules ====================

program
  .command('rules')
  .description('列出当前规则')
  .action(() => {
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

program
  .command('logs')
  .description('查看审批历史（最近 100 条）')
  .option('-n, --count <n>', '显示条数', '20')
  .action((opts) => {
    const count = parseInt(opts.count, 10) || 20;
    const history = getHistory().slice(0, count);

    console.log(chalk.bold('\n  📜 Approval History\n'));

    if (history.length === 0) {
      log.dim('No history yet. Run `sentinel start` and process some requests.');
      console.log('');
      return;
    }

    // Header
    console.log(
      `  ${chalk.dim('Time'.padEnd(10))} ${chalk.dim('Tool'.padEnd(12))} ${chalk.dim('Path'.padEnd(30))} ${chalk.dim('Risk'.padEnd(10))} ${chalk.dim('Decision')}`,
    );
    console.log(chalk.dim('  ' + '─'.repeat(80)));

    for (const entry of history) {
      const time = new Date(entry.timestamp).toLocaleTimeString('en', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const tool = entry.toolName.padEnd(12).slice(0, 12);
      const path = (entry.filePath ?? '—').padEnd(30).slice(0, 30);

      let risk: string;
      switch (entry.riskLevel) {
        case 'auto_allow': risk = chalk.dim('auto'.padEnd(10)); break;
        case 'high': risk = chalk.red('high'.padEnd(10)); break;
        case 'medium': risk = chalk.yellow('medium'.padEnd(10)); break;
        default: risk = chalk.dim(entry.riskLevel.padEnd(10)); break;
      }

      let decision: string;
      switch (entry.decision) {
        case 'allowed': case 'auto_allow': decision = chalk.green(entry.decision); break;
        case 'blocked': decision = chalk.red('blocked'); break;
        case 'timeout': decision = chalk.yellow('timeout'); break;
        case 'offline': decision = chalk.gray('offline'); break;
        default: decision = entry.decision; break;
      }

      console.log(`  ${chalk.dim(time)} ${chalk.cyan(tool)} ${path} ${risk} ${decision}`);
    }

    console.log(chalk.dim(`\n  Showing ${history.length} of ${getHistory().length} entries\n`));
  });

program.parse();
