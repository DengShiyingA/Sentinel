import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import chalk from 'chalk';
import { getSentinelDir, getPublicKeyBase64 } from '../crypto/keys';
import { getRules } from '../rules/engine';
import { getBudgetStatus } from './budget';

interface CheckResult {
  label: string;
  ok: boolean;
  message: string;
  fix?: string;
}

export async function runDoctor(): Promise<void> {
  const checks: CheckResult[] = [];

  // 1. Claude Code hook
  const claudeSettings = join(homedir(), '.claude', 'settings.json');
  if (existsSync(claudeSettings)) {
    try {
      const raw = readFileSync(claudeSettings, 'utf-8');
      const hookInstalled = raw.includes('localhost') && raw.includes('7749');
      checks.push({
        label: 'Claude Code hook',
        ok: hookInstalled,
        message: hookInstalled ? 'Hook installed' : 'Hook not installed',
        fix: hookInstalled ? undefined : 'sentinel install',
      });
    } catch {
      checks.push({ label: 'Claude Code hook', ok: false, message: 'Cannot read settings.json', fix: 'sentinel install' });
    }
  } else {
    checks.push({ label: 'Claude Code hook', ok: false, message: 'No ~/.claude/settings.json', fix: 'sentinel install' });
  }

  // 2. Hook server
  try {
    const res = await fetch('http://localhost:7749/status');
    const data = (await res.json()) as Record<string, unknown>;
    checks.push({ label: 'Hook server', ok: true, message: `Running on port 7749 (mode: ${data.mode})` });

    // 3. iOS connected (from server status)
    checks.push({
      label: 'iOS connection',
      ok: data.connected as boolean,
      message: data.connected ? `Connected (${data.mode} mode)` : 'Not connected',
      fix: data.connected ? undefined : 'Connect iOS via Settings → 手动连接',
    });
  } catch {
    checks.push({ label: 'Hook server', ok: false, message: 'Not running', fix: 'sentinel start' });
    checks.push({ label: 'iOS connection', ok: false, message: 'Server not running', fix: 'sentinel start' });
  }

  // 4. Rules
  try {
    const rules = getRules();
    const rulesPath = join(getSentinelDir(), 'rules.json');
    const hasCustom = existsSync(rulesPath);
    checks.push({
      label: 'Rules',
      ok: true,
      message: `${rules.length} rules loaded${hasCustom ? '' : ' (defaults only)'}`,
    });
  } catch {
    checks.push({ label: 'Rules', ok: false, message: 'Failed to load rules' });
  }

  // 5. Identity
  const identityPath = join(getSentinelDir(), 'identity.json');
  if (existsSync(identityPath)) {
    const pubKey = getPublicKeyBase64().slice(0, 12);
    checks.push({ label: 'Identity', ok: true, message: `${pubKey}...` });
  } else {
    checks.push({ label: 'Identity', ok: false, message: 'No identity file', fix: 'Created on first start' });
  }

  // 6. Budget
  const b = getBudgetStatus();
  if (b.limit > 0) {
    checks.push({
      label: 'Budget',
      ok: !b.overBudget,
      message: `$${b.spent.toFixed(4)} / $${b.limit.toFixed(2)} today${b.overBudget ? ' ⚠ OVER' : ''}`,
    });
  } else {
    checks.push({ label: 'Budget', ok: true, message: 'No limit set' });
  }

  // Output
  console.log(chalk.bold('\n  🩺 Sentinel Doctor\n'));
  let issues = 0;
  for (const c of checks) {
    const icon = c.ok ? chalk.green('✓') : chalk.red('✗');
    console.log(`  ${icon} ${chalk.bold(c.label.padEnd(18))} ${c.message}`);
    if (!c.ok && c.fix) {
      console.log(`    ${chalk.dim(`→ ${c.fix}`)}`);
      issues++;
    }
  }

  console.log('');
  if (issues === 0) {
    log(chalk.green.bold('  All checks passed. Sentinel is ready. ✨\n'));
  } else {
    log(chalk.yellow.bold(`  ${issues} issue${issues > 1 ? 's' : ''} found. Run suggested commands to fix.\n`));
  }
}

function log(msg: string) { console.log(msg); }
