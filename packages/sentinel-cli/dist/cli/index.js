#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const chalk_1 = __importDefault(require("chalk"));
const qrcode_terminal_1 = __importDefault(require("qrcode-terminal"));
const client_1 = require("../api/client");
const http_1 = require("../server/http");
const setup_1 = require("../install/setup");
const engine_1 = require("../rules/engine");
const keys_1 = require("../crypto/keys");
const pending_1 = require("../relay/pending");
const interface_1 = require("../transport/interface");
const factory_1 = require("../transport/factory");
const local_1 = require("../transport/local");
const logger_1 = require("../lib/logger");
const program = new commander_1.Command();
program
    .name('sentinel')
    .description('Sentinel — Claude Code 移动端审批规则引擎')
    .version('0.1.0');
function parseMode(value) {
    if (['local', 'cloudkit', 'server'].includes(value))
        return value;
    logger_1.log.error(`Invalid mode: ${value}. Use: local, cloudkit, server`);
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
    const modeLabels = {
        local: '局域网直连',
        cloudkit: 'CloudKit 同步',
        server: '自建服务器',
    };
    console.log(chalk_1.default.bold('\n  🛡️  Sentinel CLI\n'));
    logger_1.log.info(`Mode: ${modeLabels[mode]}`);
    // Create transport via factory
    if (mode === 'server') {
        const serverURL = opts.server ?? (0, client_1.getStoredServerURL)();
        if (!serverURL) {
            logger_1.log.error('Server mode requires -s URL. Run: sentinel start --mode server -s https://...');
            process.exit(1);
        }
        logger_1.log.info('Authenticating...');
        const tokenData = await (0, client_1.ensureToken)(serverURL);
        const transport = (0, factory_1.createTransport)('server', { serverUrl: serverURL, token: tokenData.token });
        (0, interface_1.setTransport)(transport);
        logger_1.log.info(`Connecting to ${serverURL}...`);
        await transport.start();
    }
    else if (mode === 'cloudkit') {
        const transport = (0, factory_1.createTransport)('cloudkit');
        (0, interface_1.setTransport)(transport);
        await transport.start();
    }
    else {
        const transport = (0, factory_1.createTransport)('local');
        (0, interface_1.setTransport)(transport);
        await transport.start();
        if (transport instanceof local_1.LocalTransport) {
            const info = transport.getConnectionInfo();
            logger_1.log.info(`iOS can connect to: ${info.ip}:${info.port}`);
        }
    }
    await (0, http_1.startHttpServer)(port);
    console.log('');
    logger_1.log.success('Sentinel is running. Press Ctrl+C to stop.\n');
    const shutdown = () => {
        console.log('');
        logger_1.log.info('Shutting down...');
        pending_1.pending.clear();
        (0, interface_1.getTransport)()?.stop();
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
    .action((opts) => { (0, setup_1.installHook)(parseInt(opts.port, 10)); });
program
    .command('uninstall')
    .description('从 Claude Code 配置移除 Sentinel hook')
    .option('-p, --port <port>', 'HTTP hook 端口', '7749')
    .action((opts) => { (0, setup_1.uninstallHook)(parseInt(opts.port, 10)); });
// ==================== sentinel pair ====================
program
    .command('pair')
    .description('配对 iOS 设备')
    .option('-m, --mode <mode>', '连接模式: local | cloudkit | server', 'local')
    .option('-s, --server <url>', '服务器地址（server 模式必须）')
    .action(async (opts) => {
    const mode = parseMode(opts.mode);
    if (mode === 'local') {
        const transport = new local_1.LocalTransport();
        await transport.start();
        const info = transport.getConnectionInfo();
        console.log(chalk_1.default.bold('\n  📡 局域网模式\n'));
        logger_1.log.success(`TCP server: ${info.ip}:${info.port}`);
        logger_1.log.info('iOS 端选择"局域网"模式，会自动发现\n');
        logger_1.log.dim('等待 iOS 连接... (Ctrl+C 退出)');
        const check = setInterval(() => {
            if (transport.isConnected) {
                clearInterval(check);
                logger_1.log.success('iOS 已连接！');
                setTimeout(() => { transport.stop(); process.exit(0); }, 2000);
            }
        }, 1000);
        process.on('SIGINT', () => { transport.stop(); process.exit(0); });
    }
    else if (mode === 'cloudkit') {
        console.log(chalk_1.default.bold('\n  ☁️  CloudKit 模式\n'));
        logger_1.log.info('CloudKit 模式无需配对。');
        logger_1.log.info('确保 Mac 和 iPhone 登录同一 Apple ID。');
        logger_1.log.dim('在 iOS 端选择 "CloudKit" 模式即可。\n');
    }
    else {
        const serverURL = opts.server ?? (0, client_1.getStoredServerURL)();
        if (!serverURL) {
            logger_1.log.error('Server mode requires -s URL.');
            process.exit(1);
        }
        const tokenData = await (0, client_1.ensureToken)(serverURL);
        logger_1.log.info('Generating pair link...');
        const res = await fetch(`${serverURL}/v1/pair/link`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ token: tokenData.token }),
        });
        if (!res.ok) {
            logger_1.log.error(`Failed: ${await res.text()}`);
            process.exit(1);
        }
        const json = (await res.json());
        if (!json.success) {
            logger_1.log.error('Server returned success=false');
            process.exit(1);
        }
        const { link, expiresIn } = json.data;
        console.log(chalk_1.default.bold('\n  📱 Scan this QR code with Sentinel iOS:\n'));
        qrcode_terminal_1.default.generate(link, { small: true }, (qr) => { console.log(qr); });
        console.log(`  ${chalk_1.default.dim('Link:')} ${chalk_1.default.cyan(link)}`);
        console.log(`  ${chalk_1.default.dim('Expires in:')} ${expiresIn}s\n`);
        logger_1.log.info('Waiting for iOS to confirm...');
        const pollInterval = setInterval(async () => {
            try {
                const sr = await fetch(`${serverURL}/v1/pair/status?token=${encodeURIComponent(tokenData.token)}`);
                const sj = (await sr.json());
                if (sj.data?.paired) {
                    clearInterval(pollInterval);
                    logger_1.log.success(`Paired: ${sj.data.pairedDevice?.name ?? 'unknown'}`);
                    process.exit(0);
                }
            }
            catch { /* ignore */ }
        }, 2000);
        setTimeout(() => { clearInterval(pollInterval); logger_1.log.warn('Expired.'); process.exit(1); }, expiresIn * 1000);
    }
});
// ==================== sentinel status ====================
program
    .command('status')
    .description('查看 Sentinel 状态')
    .action(async () => {
    const token = (0, client_1.loadToken)();
    console.log(chalk_1.default.bold('\n  🛡️  Sentinel Status\n'));
    if (token) {
        logger_1.log.success(`Server: ${token.serverURL}`);
        logger_1.log.success(`Device: ${token.deviceId}`);
    }
    else {
        logger_1.log.warn('Not authenticated (server mode)');
    }
    logger_1.log.info(`Public key: ${(0, keys_1.getPublicKeyBase64)().slice(0, 16)}...`);
    try {
        const res = await fetch('http://localhost:7749/status');
        const data = (await res.json());
        logger_1.log.success(`Hook server: running (mode=${data.mode}, ${data.pendingRequests} pending)`);
        logger_1.log.info(`Connected: ${data.connected}`);
    }
    catch {
        logger_1.log.warn('Hook server: not running');
    }
    console.log('');
});
// ==================== sentinel rules ====================
program
    .command('rules')
    .description('列出当前规则')
    .action(() => {
    const rules = (0, engine_1.getRules)();
    console.log(chalk_1.default.bold('\n  📋 Rules\n'));
    for (const rule of rules.sort((a, b) => a.priority - b.priority)) {
        const risk = rule.risk === 'auto_allow' ? chalk_1.default.green('allow') : rule.risk === 'require_confirm' ? chalk_1.default.yellow('confirm') : chalk_1.default.red('faceid');
        const tool = rule.toolPattern ? chalk_1.default.cyan(rule.toolPattern) : chalk_1.default.dim('*');
        const path = rule.pathPattern ? chalk_1.default.magenta(rule.pathPattern) : chalk_1.default.dim('*');
        console.log(`  ${chalk_1.default.dim(`[${rule.priority}]`)} ${risk}  ${tool}  ${path}  ${chalk_1.default.dim(rule.description)}`);
    }
    console.log('');
});
program
    .command('logs')
    .description('查看实时日志')
    .action(() => {
    logger_1.log.info('Logs print to stdout with `sentinel start`');
    logger_1.log.dim('Use: sentinel start 2>&1 | tee ~/.sentinel/sentinel.log');
});
program.parse();
//# sourceMappingURL=index.js.map