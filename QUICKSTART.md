# 🚀 Sentinel 快速开始指南

## 📋 项目概览

**Sentinel** 是为 Claude Code 提供的移动端规则引擎，让你能够：
- ✅ 在 iOS 手机上审批 Claude Code 的工具调用
- 📱 通过规则自动放行/拒绝特定操作
- 💰 追踪 API 调用成本，设置预算告警
- 🔒 端到端加密（X25519 + NaCl）

---

## 🎯 已完成内容总结

### ✅ 配置文件（全部完成）

1. **Monorepo 配置**
   - ✅ `package.json` - 根配置，workspace 管理
   - ✅ `tsconfig.base.json` - 共享 TypeScript 配置
   - ✅ `.gitignore` - Git 忽略规则
   - ✅ `.env.example` - 环境变量模板

2. **sentinel-cli 配置**
   - ✅ `packages-sentinel-cli-package.json` - 依赖配置
     - express, socket.io-client, tweetnacl, better-sqlite3, commander
   - ✅ `packages-sentinel-cli-tsconfig.json` - TypeScript 配置

3. **sentinel-server 配置**
   - ✅ `packages-sentinel-server-package.json` - 依赖配置
     - fastify, socket.io, prisma, ioredis, node-apn, zod
   - ✅ `packages-sentinel-server-tsconfig.json` - TypeScript 配置
   - ✅ `packages-sentinel-server-schema.prisma` - 数据库模型
   - ✅ `packages-sentinel-server-Dockerfile` - Docker 镜像

4. **Docker 部署**
   - ✅ `docker-compose.yml` - 完整服务编排
     - PostgreSQL 16 + Redis 7 + sentinel-server
     - 健康检查、自动重启、数据持久化

### ✅ 共享代码

5. **类型定义**
   - ✅ `shared-types-protocol.ts` - 完整的跨包类型系统
     - 工具调用、审批请求/响应
     - 规则引擎、成本追踪
     - Socket.IO 事件定义
     - 加密相关类型

### ✅ iOS 应用（SwiftUI）

6. **界面文件**
   - ✅ `ContentView.swift` - 主界面
     - TabView 结构（审批/规则/成本/设置）
     - 审批列表视图
     - 连接状态指示
     - 完整的数据模型和 ViewModel
   
   - ✅ `ApprovalDetailView.swift` - 审批详情页
     - 风险等级指示器（高/中/低）
     - 工具信息和参数展示
     - 代码块格式化
     - Face ID 验证集成
     - 规则创建器（Sheet）
     - 操作按钮（放行/拒绝/添加规则）

### ✅ 文档

7. **完整文档**
   - ✅ `README.md` - 项目总览、架构图、快速开始
   - ✅ `MVP-FEATURES.md` - 功能清单详细说明
     - MVP 包含功能（P0/P1/P2）
     - MVP 不包含功能（未来版本）
     - 验收标准（3 个用户故事）
     - 开发计划（7 周时间线）
   - ✅ `PROJECT-STRUCTURE.md` - 项目结构总览
     - 完整目录树
     - 技术栈总结
     - 开发工具推荐
   - ✅ `QUICKSTART.md` - 本文件

---

## 📂 文件位置说明

### ⚠️ 需要手动移动的文件

由于 Xcode 环境的限制，部分文件使用了临时命名，请按以下方式组织：

```bash
# CLI 配置文件
mv packages-sentinel-cli-package.json packages/sentinel-cli/package.json
mv packages-sentinel-cli-tsconfig.json packages/sentinel-cli/tsconfig.json

# Server 配置文件
mv packages-sentinel-server-package.json packages/sentinel-server/package.json
mv packages-sentinel-server-tsconfig.json packages/sentinel-server/tsconfig.json
mv packages-sentinel-server-schema.prisma packages/sentinel-server/src/schema.prisma
mv packages-sentinel-server-Dockerfile packages/sentinel-server/Dockerfile

# 共享类型
mv shared-types-protocol.ts shared/types/protocol.ts
```

### iOS 文件位置

iOS 文件需要在 Xcode 中组织：
- `ContentView.swift` → `packages/sentinel-ios/Sources/Views/`
- `ApprovalDetailView.swift` → `packages/sentinel-ios/Sources/Views/`

---

## 🛠️ 下一步开发计划

### 阶段 1：核心服务（2 周）

#### sentinel-cli 核心文件
```
packages/sentinel-cli/src/
├── index.ts          # ✏️ 待实现：CLI 命令行入口
├── server.ts         # ✏️ 待实现：HTTP hook 服务器
├── socket.ts         # ✏️ 待实现：Socket.IO 客户端
├── crypto.ts         # ✏️ 待实现：X25519 + NaCl 加密
├── db.ts             # ✏️ 待实现：SQLite 本地缓存
└── config.ts         # ✏️ 待实现：配置管理
```

#### sentinel-server 核心文件
```
packages/sentinel-server/src/
├── index.ts                # ✏️ 待实现：服务入口
├── app.ts                  # ✏️ 待实现：Fastify 应用
├── socket/
│   ├── index.ts            # ✏️ 待实现：Socket.IO 服务器
│   └── handlers.ts         # ✏️ 待实现：事件处理器
├── services/
│   ├── rules.ts            # ✏️ 待实现：规则引擎
│   └── approval.ts         # ✏️ 待实现：审批逻辑
└── routes/
    └── health.ts           # ✏️ 待实现：健康检查
```

### 阶段 2：iOS 应用（2 周）

#### 核心服务
```
packages/sentinel-ios/Sources/Services/
├── SocketService.swift      # ✏️ 待实现：Socket.IO 客户端
├── CryptoService.swift      # ✏️ 待实现：X25519 + NaCl
├── BiometricService.swift   # ✏️ 待实现：Face ID / Touch ID
└── KeychainService.swift    # ✏️ 待实现：密钥存储
```

#### 数据模型
```
packages/sentinel-ios/Sources/Models/
├── ApprovalRequest.swift    # ✏️ 待实现：从 ContentView 移出
├── Rule.swift               # ✏️ 待实现：规则模型
└── CostRecord.swift         # ✏️ 待实现：成本记录
```

#### 其他视图
```
packages/sentinel-ios/Sources/Views/
├── OnboardingView.swift     # ✏️ 待实现：配对引导
├── RulesView.swift          # ✏️ 待实现：规则列表
├── RuleEditorView.swift     # ✏️ 待实现：规则编辑
├── CostDashboardView.swift  # ✏️ 待实现：成本面板
└── SettingsView.swift       # ✏️ 待实现：设置
```

### 阶段 3：集成与测试（1 周）

- [ ] 端到端测试（CLI → Server → iOS）
- [ ] 性能测试（高并发审批）
- [ ] 安全测试（加密验证）
- [ ] 文档完善

---

## 💡 关键技术点

### 1. Socket.IO 事件流

```typescript
// CLI 发送工具调用请求
socket.emit('tool:request', {
  toolCall: { toolName: 'write_file', parameters: {...} },
  context: { filePath: '/tmp/test.txt', riskLevel: 'low' }
}, (response) => {
  // 收到审批结果：allow / block
  console.log(response.action);
});

// Server 推送到 iOS
io.to(deviceId).emit('approval:request', {
  id: 'req-123',
  toolCall: {...},
  expiresAt: Date.now() + 30000
});

// iOS 返回审批结果
socket.emit('approval:response', {
  requestId: 'req-123',
  action: 'allow',
  reason: '用户批准'
});
```

### 2. 规则引擎示例

```typescript
// 规则定义
const rules: Rule[] = [
  {
    id: '1',
    name: '临时文件自动放行',
    type: 'path_whitelist',
    conditions: [
      { field: 'filePath', operator: 'startsWith', value: '/tmp/' }
    ],
    action: 'allow',
    priority: 10
  },
  {
    id: '2',
    name: '危险命令拒绝',
    type: 'tool_blacklist',
    conditions: [
      { field: 'toolName', operator: 'contains', value: 'rm -rf' }
    ],
    action: 'block',
    priority: 1
  }
];

// 匹配逻辑
function matchRule(toolCall: ToolCall, context: Context): RuleMatchResult {
  const sortedRules = rules.sort((a, b) => a.priority - b.priority);
  
  for (const rule of sortedRules) {
    if (evaluateConditions(rule.conditions, toolCall, context)) {
      return { matched: true, rule, action: rule.action };
    }
  }
  
  return { matched: false, action: 'require_approval' };
}
```

### 3. X25519 + NaCl 加密

```typescript
// CLI 端
import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';

// 生成密钥对
const keyPair = nacl.box.keyPair();

// 加密消息
const nonce = nacl.randomBytes(nacl.box.nonceLength);
const message = JSON.stringify({ toolName: 'write_file' });
const encrypted = nacl.box(
  decodeUTF8(message),
  nonce,
  serverPublicKey,
  keyPair.secretKey
);

// 发送
socket.emit('tool:request', {
  nonce: encodeBase64(nonce),
  ciphertext: encodeBase64(encrypted)
});
```

---

## 🎯 MVP 验收清单

### ✅ 配置和文档
- [x] Monorepo 配置完成
- [x] Docker Compose 配置完成
- [x] 数据库模型设计完成
- [x] TypeScript 类型定义完成
- [x] iOS 主界面和审批详情页完成
- [x] 完整文档（README + MVP 功能清单 + 项目结构）

### ⏳ 待开发
- [ ] CLI HTTP hook 服务器
- [ ] Server Socket.IO 服务
- [ ] 规则引擎实现
- [ ] iOS Socket.IO 集成
- [ ] 加密通信实现
- [ ] 成本追踪功能
- [ ] 端到端测试

---

## 📚 参考资源

### 技术文档
- [Socket.IO 文档](https://socket.io/docs/v4/)
- [Prisma 文档](https://www.prisma.io/docs)
- [Fastify 文档](https://www.fastify.io/)
- [TweetNaCl.js](https://github.com/dchest/tweetnacl-js)
- [SwiftUI 文档](https://developer.apple.com/documentation/swiftui/)
- [LocalAuthentication 文档](https://developer.apple.com/documentation/localauthentication)

### 参考项目
- [Happy Coder](https://github.com/happycoderorg/happycoder) - Socket.IO + 加密方案参考
- [Claude Code Hooks](https://docs.anthropic.com/claude/docs/hooks) - Hook 系统文档

---

## 🤝 贡献指南

1. **Fork 仓库**
2. **创建功能分支** (`git checkout -b feature/amazing-feature`)
3. **提交更改** (`git commit -m 'Add amazing feature'`)
4. **推送到分支** (`git push origin feature/amazing-feature`)
5. **开启 Pull Request**

---

## 📧 联系方式

- **项目负责人**: 邓诗颖
- **创建日期**: 2026-04-08
- **项目状态**: 🚧 开发中（配置和文档阶段已完成）

---

## 🎉 总结

你现在拥有：
- ✅ 完整的 Monorepo 配置
- ✅ Docker Compose 一键部署方案
- ✅ 完整的数据库设计（Prisma Schema）
- ✅ 跨包类型系统（TypeScript）
- ✅ iOS 主界面和审批详情页（SwiftUI）
- ✅ 详细的 MVP 功能清单
- ✅ 7 周开发计划

**下一步**：开始实现 sentinel-cli 和 sentinel-server 的核心逻辑！

祝开发顺利！🚀
