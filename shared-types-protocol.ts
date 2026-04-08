/**
 * Sentinel Protocol - 跨组件共享类型定义
 * CLI <-> Server <-> iOS 通信协议
 */

// ==================== 工具调用相关 ====================

export interface ToolCall {
  id: string;
  toolName: string;
  parameters: Record<string, any>;
  timestamp: number;
  sessionId?: string;
  conversationId?: string;
}

export interface ToolCallContext {
  projectPath?: string;
  filePath?: string;
  diff?: string;
  estimatedCost?: number;
  riskLevel?: 'low' | 'medium' | 'high';
}

export interface HookRequest {
  toolCall: ToolCall;
  context?: ToolCallContext;
}

export interface HookResponse {
  action: 'allow' | 'block';
  reason?: string;
  appliedRule?: string;
}

// ==================== 审批相关 ====================

export interface ApprovalRequest {
  id: string;
  toolCall: ToolCall;
  context?: ToolCallContext;
  createdAt: number;
  expiresAt: number; // 30 秒超时
  deviceId: string;
}

export interface ApprovalResponse {
  requestId: string;
  action: 'allow' | 'block';
  reason?: string;
  createRule?: boolean; // 是否同时创建规则
  ruleConfig?: Partial<Rule>;
}

// ==================== 规则引擎 ====================

export type RuleType = 'path_whitelist' | 'tool_blacklist' | 'cost_threshold' | 'custom';

export interface Rule {
  id: string;
  name: string;
  type: RuleType;
  enabled: boolean;
  priority: number; // 数字越小优先级越高
  conditions: RuleCondition[];
  action: 'allow' | 'block' | 'require_approval' | 'require_biometric';
  createdAt: number;
  updatedAt: number;
}

export interface RuleCondition {
  field: string; // 如 'toolName', 'filePath', 'estimatedCost'
  operator: 'equals' | 'contains' | 'startsWith' | 'endsWith' | 'regex' | 'gt' | 'lt' | 'gte' | 'lte';
  value: string | number | boolean;
}

export interface RuleMatchResult {
  matched: boolean;
  rule?: Rule;
  action: 'allow' | 'block' | 'require_approval' | 'require_biometric';
}

// ==================== 成本追踪 ====================

export interface CostRecord {
  id: string;
  toolCall: ToolCall;
  cost: number; // 美元
  modelUsed?: string;
  tokensUsed?: number;
  timestamp: number;
  approved: boolean;
}

export interface CostSummary {
  total: number;
  daily: number;
  weekly: number;
  monthly: number;
  byTool: Record<string, number>;
  byDate: Record<string, number>; // YYYY-MM-DD -> cost
}

// ==================== Socket.IO 事件 ====================

export interface ServerToClientEvents {
  // 服务器推送审批请求到 iOS
  'approval:request': (data: ApprovalRequest) => void;
  
  // 规则更新通知（iOS 修改规则后通知 CLI）
  'rules:updated': (rules: Rule[]) => void;
  
  // 连接状态
  'connection:status': (status: 'connected' | 'disconnected') => void;
  
  // 错误通知
  'error': (error: { code: string; message: string }) => void;
}

export interface ClientToServerEvents {
  // CLI 发送工具调用，请求审批决策
  'tool:request': (
    data: HookRequest,
    callback: (response: HookResponse) => void
  ) => void;
  
  // iOS 返回审批结果
  'approval:response': (data: ApprovalResponse) => void;
  
  // iOS 请求规则列表
  'rules:fetch': (callback: (rules: Rule[]) => void) => void;
  
  // iOS 创建/更新规则
  'rules:upsert': (rule: Partial<Rule>, callback: (rule: Rule) => void) => void;
  
  // iOS 删除规则
  'rules:delete': (ruleId: string, callback: (success: boolean) => void) => void;
  
  // 请求成本统计
  'cost:fetch': (
    params: { from?: number; to?: number },
    callback: (summary: CostSummary) => void
  ) => void;
  
  // 设备认证
  'auth:authenticate': (
    data: { deviceId: string; publicKey: string; signature: string },
    callback: (result: { success: boolean; token?: string }) => void
  ) => void;
}

// ==================== 加密相关 ====================

export interface KeyPair {
  publicKey: Uint8Array;
  secretKey: Uint8Array;
}

export interface EncryptedMessage {
  nonce: string; // base64
  ciphertext: string; // base64
}

export interface PairingData {
  deviceId: string;
  serverUrl: string;
  publicKey: string; // base64
  timestamp: number;
}

// ==================== 设备管理 ====================

export interface Device {
  id: string;
  name: string;
  platform: 'ios' | 'android' | 'cli';
  publicKey: string;
  apnsToken?: string;
  lastSeen: number;
  createdAt: number;
}

// ==================== API 请求/响应 ====================

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}
