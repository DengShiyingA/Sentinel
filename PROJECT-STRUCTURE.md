# Sentinel 项目结构总览

## 📂 完整目录结构

```
sentinel/
├── packages/
│   ├── sentinel-cli/                    # Node.js CLI 工具
│   │   ├── src/
│   │   │   ├── index.ts                 # 命令行入口
│   │   │   ├── server.ts                # HTTP hook 服务器
│   │   │   ├── socket.ts                # Socket.IO 客户端
│   │   │   ├── crypto.ts                # X25519 + NaCl 加密
│   │   │   ├── db.ts                    # SQLite 本地缓存
│   │   │   ├── config.ts                # 配置管理
│   │   │   └── types.ts                 # TypeScript 类型
│   │   ├── package.json                 # ⚙️ 已创建
│   │   ├── tsconfig.json                # ⚙️ 已创建
│   │   └── README.md
│   │
│   ├── sentinel-server/                 # Fastify 后端服务
│   │   ├── src/
│   │   │   ├── index.ts                 # 服务入口
│   │   │   ├── app.ts                   # Fastify 应用
│   │   │   ├── socket/
│   │   │   │   ├── index.ts             # Socket.IO 服务器
│   │   │   │   ├── handlers.ts          # 事件处理器
│   │   │   │   └── auth.ts              # 设备认证
│   │   │   ├── routes/
│   │   │   │   ├── approval.ts          # 审批接口
│   │   │   │   ├── rules.ts             # 规则 CRUD
│   │   │   │   └── health.ts            # 健康检查
│   │   │   ├── services/
│   │   │   │   ├── approval.ts          # 审批逻辑
│   │   │   │   ├── rules.ts             # 规则引擎
│   │   │   │   ├── push.ts              # APNs 推送
│   │   │   │   └── cost.ts              # 成本追踪
│   │   │   ├── crypto.ts                # 加密工具
│   │   │   ├── db/
│   │   │   │   ├── client.ts            # Prisma 客户端
│   │   │   │   └── redis.ts             # Redis 客户端
│   │   │   ├── schema.prisma            # ⚙️ 已创建
│   │   │   └── types.ts                 # TypeScript 类型
│   │   ├── migrations/                  # Prisma 迁移（自动生成）
│   │   ├── package.json                 # ⚙️ 已创建
│   │   ├── tsconfig.json                # ⚙️ 已创建
│   │   ├── Dockerfile                   # ⚙️ 已创建
│   │   └── README.md
│   │
│   └── sentinel-ios/                    # Swift/SwiftUI iOS 应用
│       ├── Sources/
│       │   ├── App/
│       │   │   ├── SentinelApp.swift           # App 入口
│       │   │   └── AppDelegate.swift           # APNs 注册
│       │   ├── Views/
│       │   │   ├── ContentView.swift           # ⚙️ 已创建（主界面）
│       │   │   ├── OnboardingView.swift        # 配对引导
│       │   │   ├── ApprovalView.swift          # 审批界面
│       │   │   ├── ApprovalDetailView.swift    # 审批详情
│       │   │   ├── RulesView.swift             # 规则列表
│       │   │   ├── RuleEditorView.swift        # 规则编辑
│       │   │   ├── CostDashboardView.swift     # 成本面板
│       │   │   └── SettingsView.swift          # 设置
│       │   ├── ViewModels/
│       │   │   ├── ApprovalViewModel.swift     # 审批逻辑
│       │   │   ├── RulesViewModel.swift        # 规则管理
│       │   │   └── CostViewModel.swift         # 成本统计
│       │   ├── Models/
│       │   │   ├── ApprovalRequest.swift       # 审批请求
│       │   │   ├── Rule.swift                  # 规则模型
│       │   │   ├── CostRecord.swift            # 成本记录
│       │   │   └── ToolCall.swift              # 工具调用
│       │   ├── Services/
│       │   │   ├── SocketService.swift         # Socket.IO 客户端
│       │   │   ├── CryptoService.swift         # X25519 + NaCl
│       │   │   ├── BiometricService.swift      # Face ID / Touch ID
│       │   │   ├── NotificationService.swift   # 通知管理
│       │   │   └── KeychainService.swift       # 密钥存储
│       │   └── Utilities/
│       │       ├── Constants.swift             # 常量
│       │       ├── Extensions.swift            # 扩展
│       │       └── DiffHighlighter.swift       # Diff 语法高亮
│       ├── Resources/
│       │   ├── Assets.xcassets/
│       │   └── Info.plist
│       └── README.md
│
├── shared/
│   └── types/
│       └── protocol.ts                  # ⚙️ 已创建（跨包共享类型）
│
├── docker-compose.yml                   # ⚙️ 已创建
├── package.json                         # ⚙️ 已创建（Monorepo 根配置）
├── tsconfig.base.json                   # ⚙️ 已创建
├── .gitignore                           # ⚙️ 已创建
├── .env.example                         # ⚙️ 已创建
├── README.md                            # ⚙️ 已创建
└── MVP-FEATURES.md                      # ⚙️ 已创建（功能清单）
```

## 📦 已创建文件清单

### ✅ 配置文件
1. `package.json` - Monorepo 根配置
2. `tsconfig.base.json` - 共享 TypeScript 配置
3. `packages-sentinel-cli-package.json` - CLI 依赖
4. `packages-sentinel-cli-tsconfig.json` - CLI TS 配置
5. `packages-sentinel-server-package.json` - Server 依赖
6. `packages-sentinel-server-tsconfig.json` - Server TS 配置
7. `.gitignore` - Git 忽略规则
8. `.env.example` - 环境变量示例

### ✅ 基础设施
9. `docker-compose.yml` - Docker 编排配置
10. `packages-sentinel-server-Dockerfile` - Server Docker 镜像
11. `packages-sentinel-server-schema.prisma` - Prisma 数据模型

### ✅ 共享代码
12. `shared-types-protocol.ts` - 跨包类型定义

### ✅ iOS 应用
13. `ContentView.swift` - iOS 主界面（已更新）

### ✅ 文档
14. `README.md` - 项目总览
15. `MVP-FEATURES.md` - MVP 功能详细说明
16. `PROJECT-STRUCTURE.md` - 本文件

## 🎯 下一步行动

### 1️⃣ 立即可做（本地开发）

```bash
# 初始化 Monorepo
npm install

# 安装各包依赖
npm install -w sentinel-cli
npm install -w sentinel-server

# 启动 Server 开发模式
npm run dev:server

# 启动 CLI 开发模式
npm run dev:cli
```

### 2️⃣ 需要手动创建的文件（按优先级）

#### 高优先级（核心功能）
- `packages/sentinel-cli/src/index.ts` - CLI 入口
- `packages/sentinel-cli/src/server.ts` - Hook 服务器
- `packages/sentinel-server/src/index.ts` - Server 入口
- `packages/sentinel-server/src/app.ts` - Fastify 应用
- `packages/sentinel-server/src/socket/index.ts` - Socket.IO 服务
- `packages/sentinel-server/src/services/rules.ts` - 规则引擎

#### 中优先级（iOS 核心）
- `packages/sentinel-ios/Sources/App/SentinelApp.swift` - App 入口
- `packages/sentinel-ios/Sources/Views/ApprovalDetailView.swift` - 审批详情
- `packages/sentinel-ios/Sources/Services/SocketService.swift` - Socket 客户端
- `packages/sentinel-ios/Sources/Services/CryptoService.swift` - 加密服务

#### 低优先级（增强功能）
- `packages/sentinel-server/src/services/push.ts` - APNs 推送
- `packages/sentinel-ios/Sources/Views/CostDashboardView.swift` - 成本面板

### 3️⃣ VPS 部署（生产环境）

```bash
# 1. SSH 到 VPS
ssh user@your-vps-ip

# 2. 克隆仓库
git clone https://github.com/yourusername/sentinel.git
cd sentinel

# 3. 配置环境变量
cp .env.example .env
vim .env  # 修改密码和密钥

# 4. 启动服务
docker-compose up -d

# 5. 查看日志
docker-compose logs -f sentinel-server

# 6. 健康检查
curl http://localhost:3000/health
```

## 🔧 开发工具推荐

### Node.js 开发
- **TypeScript**: 类型安全
- **tsx**: 快速开发模式（`npm run dev`）
- **Prisma Studio**: 数据库可视化（`npm run prisma:studio`）

### iOS 开发
- **Xcode 15+**: 原生开发环境
- **Swift 5.9+**: 最新语言特性
- **iOS 17+**: 目标平台

### 调试工具
- **Postman**: 测试 HTTP/Socket.IO 接口
- **Proxyman**: iOS 网络抓包
- **TablePlus**: PostgreSQL 客户端
- **RedisInsight**: Redis 可视化

## 📊 技术栈总结

| 组件 | 技术栈 | 关键依赖 |
|------|--------|----------|
| **sentinel-cli** | Node.js 20, TypeScript | express, socket.io-client, tweetnacl, better-sqlite3 |
| **sentinel-server** | Node.js 20, Fastify | socket.io, prisma, ioredis, node-apn |
| **sentinel-ios** | Swift 5.9, SwiftUI | iOS 17+, Combine, LocalAuthentication |
| **数据库** | PostgreSQL 16 | Prisma ORM |
| **缓存** | Redis 7 | ioredis |
| **加密** | X25519 + NaCl | tweetnacl, tweetnacl-util |
| **推送** | APNs | node-apn |
| **部署** | Docker, Docker Compose | - |

## 🚀 快速开始时间线

### 第 1 天：环境搭建
- ✅ Monorepo 初始化
- ✅ Docker Compose 配置
- ✅ 数据库迁移

### 第 2-3 天：Server 核心
- 🔨 Socket.IO 服务器
- 🔨 规则引擎基础逻辑
- 🔨 Prisma CRUD 接口

### 第 4-5 天：CLI 核心
- 🔨 HTTP hook 服务器
- 🔨 Socket.IO 客户端
- 🔨 配对流程

### 第 6-10 天：iOS 应用
- 🔨 配对界面
- 🔨 审批列表和详情
- 🔨 规则管理
- 🔨 Socket.IO 集成

### 第 11-14 天：集成测试
- 🔨 端到端测试
- 🔨 性能优化
- 🔨 文档完善

## 📝 备注

- 所有文件名带 `packages-` 前缀的需要移动到对应的 `packages/` 子目录
- iOS 项目需要在 Xcode 中创建，本文件列出的是源代码结构
- Prisma 迁移文件在首次运行 `prisma migrate dev` 时自动生成
- APNs 密钥需要从 Apple Developer 后台下载，放在 `secrets/` 目录

---

**创建日期**: 2026-04-08  
**最后更新**: 2026-04-08  
**项目状态**: 🚧 开发中
