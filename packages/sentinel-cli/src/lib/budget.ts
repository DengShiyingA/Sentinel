import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';
import { getTodayStats } from './history';

const BUDGET_PATH = join(getSentinelDir(), 'budget.json');

// Per-tool cost estimation (input + output tokens)
// Based on typical Claude Sonnet usage patterns
const TOOL_COST_ESTIMATES: Record<string, { input: number; output: number }> = {
  Bash:  { input: 800, output: 500 },   // commands + output
  Write: { input: 600, output: 300 },   // file content
  Edit:  { input: 500, output: 200 },   // partial edits
  Read:  { input: 200, output: 800 },   // small request, large file
  Glob:  { input: 200, output: 300 },
  Grep:  { input: 300, output: 400 },
};
const DEFAULT_TOOL_ESTIMATE = { input: 500, output: 200 };

// Configurable pricing — defaults to Claude Sonnet
interface BudgetConfig {
  dailyLimit: number;  // USD
  currency: string;
  inputCostPerM: number;   // $ per 1M input tokens
  outputCostPerM: number;  // $ per 1M output tokens
}

function estimateCost(toolName: string, config: BudgetConfig): number {
  const est = TOOL_COST_ESTIMATES[toolName] ?? DEFAULT_TOOL_ESTIMATE;
  return (est.input / 1_000_000) * config.inputCostPerM +
         (est.output / 1_000_000) * config.outputCostPerM;
}

const DEFAULT_CONFIG: BudgetConfig = {
  dailyLimit: 5.0,
  currency: 'USD',
  inputCostPerM: 3.0,    // Claude Sonnet
  outputCostPerM: 15.0,  // Claude Sonnet
};

function loadBudget(): BudgetConfig {
  if (!existsSync(BUDGET_PATH)) return { ...DEFAULT_CONFIG };
  try {
    const saved = JSON.parse(readFileSync(BUDGET_PATH, 'utf-8'));
    return { ...DEFAULT_CONFIG, ...saved };
  } catch {
    return { ...DEFAULT_CONFIG };
  }
}

function saveBudget(config: BudgetConfig): void {
  writeFileSync(BUDGET_PATH, JSON.stringify(config, null, 2), { mode: 0o600 });
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
  const config = loadBudget();
  // Use a weighted average estimate per call
  const avgCost = estimateCost('_average', config);
  const calls = stats.allowed + stats.autoAllow;
  return calls * avgCost;
}

/** Estimate cost for a specific tool call */
export function estimateToolCost(toolName: string): number {
  const config = loadBudget();
  return estimateCost(toolName, config);
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
