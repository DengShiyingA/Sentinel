export type RiskAction = 'auto_allow' | 'require_confirm' | 'require_faceid';
export interface Rule {
    id: string;
    toolPattern: string | null;
    pathPattern: string | null;
    risk: RiskAction;
    priority: number;
    description: string;
}
export interface RuleMatchResult {
    matched: boolean;
    rule: Rule | null;
    action: RiskAction;
}
export declare function getRules(): Rule[];
/**
 * 匹配工具调用 against 规则列表
 *
 * @param toolName   - 工具名，e.g. "Bash", "Write", "Edit"
 * @param filePath   - 文件路径（可选），e.g. "/tmp/foo.txt"
 * @returns          - 匹配结果：{ matched, rule, action }
 */
export declare function matchRules(toolName: string, filePath: string | null): RuleMatchResult;
/**
 * 将工具调用的风险等级映射为 server riskLevel
 */
export declare function riskToLevel(action: RiskAction): string;
