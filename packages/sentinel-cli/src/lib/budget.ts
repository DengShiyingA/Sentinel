import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';
import { getTodayStats } from './history';

const BUDGET_PATH = join(getSentinelDir(), 'budget.json');

// Claude Sonnet pricing
const INPUT_COST_PER_M = 3.0;   // $3 / 1M input tokens
const OUTPUT_COST_PER_M = 15.0;  // $15 / 1M output tokens
// Rough estimate: each tool call ~500 input + 200 output tokens
const EST_INPUT_TOKENS = 500;
const EST_OUTPUT_TOKENS = 200;
const EST_COST_PER_CALL =
  (EST_INPUT_TOKENS / 1_000_000) * INPUT_COST_PER_M +
  (EST_OUTPUT_TOKENS / 1_000_000) * OUTPUT_COST_PER_M;

interface BudgetConfig {
  dailyLimit: number;  // USD
  currency: string;
}

function loadBudget(): BudgetConfig {
  if (!existsSync(BUDGET_PATH)) return { dailyLimit: 5.0, currency: 'USD' };
  try {
    return JSON.parse(readFileSync(BUDGET_PATH, 'utf-8'));
  } catch {
    return { dailyLimit: 5.0, currency: 'USD' };
  }
}

function saveBudget(config: BudgetConfig): void {
  writeFileSync(BUDGET_PATH, JSON.stringify(config, null, 2));
}

export function setBudgetLimit(amount: number): void {
  const config = loadBudget();
  config.dailyLimit = amount;
  saveBudget(config);
}

export function getBudgetLimit(): number {
  return loadBudget().dailyLimit;
}

export function getTodaySpend(): number {
  const stats = getTodayStats();
  // Count all calls that went through (allowed + auto_allow)
  const calls = stats.allowed + stats.autoAllow;
  return calls * EST_COST_PER_CALL;
}

export function isOverBudget(): boolean {
  return getTodaySpend() >= getBudgetLimit();
}

export function getBudgetStatus(): { limit: number; spent: number; remaining: number; overBudget: boolean; calls: number } {
  const limit = getBudgetLimit();
  const spent = getTodaySpend();
  const stats = getTodayStats();
  return {
    limit,
    spent,
    remaining: Math.max(0, limit - spent),
    overBudget: spent >= limit,
    calls: stats.allowed + stats.autoAllow,
  };
}

export function resetTodayBudget(): void {
  // Budget reset = just info, actual history stays
  // The stats are derived from history which filters by today's date
  // So "reset" means clearing today's history entries
  // For simplicity, we just note the reset — actual cost tracking continues
}
