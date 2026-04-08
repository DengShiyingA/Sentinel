import { readFileSync, existsSync, writeFileSync, watch } from 'fs';
import { join } from 'path';
import { getSentinelDir } from '../crypto/keys';
import { log } from '../lib/logger';

// ==================== Types ====================

export type RiskAction = 'auto_allow' | 'require_confirm' | 'require_faceid';

export interface Rule {
  id: string;
  toolPattern: string | null;   // glob: 'Bash', 'Edit*', '*'
  pathPattern: string | null;   // glob: '/tmp/**', 'src/**/*.ts'
  risk: RiskAction;
  priority: number;             // 越小越优先
  description: string;
}

export interface RuleMatchResult {
  matched: boolean;
  rule: Rule | null;
  action: RiskAction;
}

// ==================== Default Rules ====================

const DEFAULT_RULES: Rule[] = [
  {
    id: 'builtin-bash-high',
    toolPattern: 'Bash',
    pathPattern: null,
    risk: 'require_faceid',
    priority: 10,
    description: 'Bash commands require Face ID',
  },
  {
    id: 'builtin-write-confirm',
    toolPattern: 'Write',
    pathPattern: null,
    risk: 'require_confirm',
    priority: 20,
    description: 'File writes require confirmation',
  },
  {
    id: 'builtin-edit-confirm',
    toolPattern: 'Edit',
    pathPattern: null,
    risk: 'require_confirm',
    priority: 20,
    description: 'File edits require confirmation',
  },
  {
    id: 'builtin-tmp-allow',
    toolPattern: '*',
    pathPattern: '/tmp/**',
    risk: 'auto_allow',
    priority: 5,
    description: 'Auto-allow /tmp operations',
  },
  {
    id: 'builtin-env-faceid',
    toolPattern: '*',
    pathPattern: '**/.env*',
    risk: 'require_faceid',
    priority: 1,
    description: '.env files require Face ID',
  },
  {
    id: 'builtin-read-allow',
    toolPattern: 'Read',
    pathPattern: null,
    risk: 'auto_allow',
    priority: 50,
    description: 'Auto-allow file reads',
  },
  {
    id: 'builtin-glob-allow',
    toolPattern: 'Glob',
    pathPattern: null,
    risk: 'auto_allow',
    priority: 50,
    description: 'Auto-allow glob searches',
  },
  {
    id: 'builtin-grep-allow',
    toolPattern: 'Grep',
    pathPattern: null,
    risk: 'auto_allow',
    priority: 50,
    description: 'Auto-allow grep searches',
  },
];

// ==================== Rules File ====================

const RULES_PATH = join(getSentinelDir(), 'rules.json');

let cachedRules: Rule[] | null = null;

function loadRules(): Rule[] {
  if (cachedRules) return cachedRules;

  if (!existsSync(RULES_PATH)) {
    writeFileSync(RULES_PATH, JSON.stringify(DEFAULT_RULES, null, 2));
    cachedRules = DEFAULT_RULES;
    return DEFAULT_RULES;
  }
  try {
    cachedRules = JSON.parse(readFileSync(RULES_PATH, 'utf-8')) as Rule[];
    return cachedRules;
  } catch {
    cachedRules = DEFAULT_RULES;
    return DEFAULT_RULES;
  }
}

export function getRules(): Rule[] {
  return loadRules();
}

/** Watch rules.json for changes and auto-reload */
export function watchRules(): void {
  // Ensure file exists first
  loadRules();
  try {
    let debounce: NodeJS.Timeout | null = null;
    watch(RULES_PATH, () => {
      if (debounce) clearTimeout(debounce);
      debounce = setTimeout(() => {
        cachedRules = null; // invalidate cache
        const rules = loadRules();
        log.info(`Rules reloaded (${rules.length} rules)`);
      }, 300);
    });
    log.debug(`Watching ${RULES_PATH} for changes`);
  } catch {
    log.debug('Could not watch rules file');
  }
}

// ==================== Glob Matching ====================

/**
 * 简单 glob 匹配，支持 * 和 **
 */
function globMatch(pattern: string, value: string): boolean {
  // Escape regex special chars, then convert glob patterns
  const regex = pattern
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*\*/g, '{{DOUBLESTAR}}')
    .replace(/\*/g, '[^/]*')
    .replace(/{{DOUBLESTAR}}/g, '.*');

  return new RegExp(`^${regex}$`).test(value);
}

// ==================== Engine ====================

/**
 * 匹配工具调用 against 规则列表
 *
 * @param toolName   - 工具名，e.g. "Bash", "Write", "Edit"
 * @param filePath   - 文件路径（可选），e.g. "/tmp/foo.txt"
 * @returns          - 匹配结果：{ matched, rule, action }
 */
export function matchRules(
  toolName: string,
  filePath: string | null,
): RuleMatchResult {
  const rules = loadRules().sort((a, b) => a.priority - b.priority);

  for (const rule of rules) {
    let toolMatch = true;
    let pathMatch = true;

    // Tool pattern
    if (rule.toolPattern) {
      toolMatch = globMatch(rule.toolPattern, toolName);
    }

    // Path pattern — 只有当规则有 pathPattern 且调用有 filePath 时才匹配
    if (rule.pathPattern) {
      if (!filePath) {
        pathMatch = false; // 规则要求路径但调用没有路径
      } else {
        pathMatch = globMatch(rule.pathPattern, filePath);
      }
    }

    if (toolMatch && pathMatch) {
      log.debug(`Rule matched: [${rule.id}] ${rule.description} → ${rule.risk}`);
      return { matched: true, rule, action: rule.risk };
    }
  }

  // 无匹配 → 默认需要确认
  return { matched: false, rule: null, action: 'require_confirm' };
}

/**
 * 将工具调用的风险等级映射为 server riskLevel
 */
export function riskToLevel(action: RiskAction): string {
  switch (action) {
    case 'auto_allow': return 'low';
    case 'require_confirm': return 'medium';
    case 'require_faceid': return 'high';
  }
}
