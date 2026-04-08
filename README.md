# Sentinel

**Claude Code 移动端规则引擎** - 为 Claude Code 提供 iOS 手机端的工具调用审批和规则管理。

## 🎯 项目定位

Sentinel 不是简单的终端镜像，而是一个**智能规则引擎**，为 Claude Code 的工具调用提供：

- ✅ **自动化规则** - 按规则自动放行/推送审批/要求 Face ID
- 📱 **移动端优先** - 原生 iOS 应用，随时随地审批
- 🔒 **端到端加密** - X25519 + NaCl 加密通信
- 💰 **成本追踪** - 实时追踪 API 调用成本，预算告警
- 🎨 **丰富上下文** - 审批界面展示完整 diff、路径、风险评估

## 📦 架构

```
┌─────────────┐      Hook HTTP      ┌──────────────┐
│ Claude Code │ ───────────────────> │ sentinel-cli │
└─────────────┘                      └──────┬───────┘
                                            │ Socket.IO
                                            │ (Encrypted)
                                            ▼
                                     ┌──────────────┐
                                     │sentinel-server│
                                     │  + PostgreSQL │
                                     │  + Redis      │
                                     └──────┬───────┘
                                            │ Socket.IO + APNs
                                            ▼
                                     ┌──────────────┐
                                     │ sentinel-ios │
                                     │ (Swift/SwiftUI)│
                                     └──────────────┘
```

### 组件说明

- **sentinel-cli**: Node.js CLI 工具，接收 Claude Code 的 PreToolUse hook，转发到 server
- **sentinel-server**: Fastify + Socket.IO 服务器，规则引擎核心，管理审批流程
- **sentinel-ios**: 原生 iOS 应用，审批界面 + 规则配置 + 成本追踪

## 🚀 快速开始

### 1. 服务器部署（VPS）

```bash
# 克隆仓库
git clone https://github.com/yourusername/sentinel.git
cd sentinel

# 配置环境变量
cp .env.example .env
vim .env  # 修改密码和密钥

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f sentinel-server
```

### 2. CLI 安装（开发机）

```bash
# 全局安装
npm install -g sentinel-cli

# 或者本地开发
cd packages/sentinel-cli
npm install
npm run dev

# 配对设备
sentinel pair --server https://your-vps-domain.com

# 启动 hook 服务
sentinel start --port 8765
```

### 3. Claude Code 配置

在 Claude Code 配置文件中添加 hook：

```json
{
  "hooks": {
    "preToolUse": "http://localhost:8765/hook"
  }
}
```

### 4. iOS 应用安装

1. 从 App Store 下载 Sentinel（或使用 Xcode 构建）
2. 打开应用，扫描 CLI 生成的配对二维码
3. 完成 Face ID 授权
4. 开始使用！

## 📋 MVP 功能边界

### ✅ MVP 包含功能

#### 核心功能
- [x] **基础审批流程**
  - CLI 接收 PreToolUse hook，转发到 server
  - Server 推送到 iOS，等待用户决策
  - iOS 返回 allow/block，CLI 回复 Claude Code
  - 超时自动拒绝（30 秒）

- [x] **基础规则引擎**
  - 路径白名单（如 `tmp/**` 自动放行）
  - 工具黑名单（如 `rm -rf` 拒绝）
  - 简单成本阈值（单次超过 $0.10 需审批）

- [x] **iOS 审批界面**
  - 工具名称 + 参数展示
  - 文件 diff 高亮显示（如果是文件操作）
  - 快速操作：放行 / 拒绝 / 本次允许 / 添加规则
  - Face ID 验证（高风险操作）

- [x] **端到端加密**
  - X25519 密钥交换
  - NaCl 对称加密
  - 配对二维码验证

- [x] **成本追踪**
  - 记录每次工具调用
  - 简单统计（日/周/月）
  - 基础图表展示

#### 基础设施
- [x] Docker Compose 一键部署
- [x] PostgreSQL 持久化
- [x] Redis 会话缓存
- [x] APNs 离线推送（可选）

### ❌ MVP 不包含（后续版本）

- [ ] 复杂规则 DSL（如时间条件、上下文变量）
- [ ] 多用户/团队管理
- [ ] 审批历史搜索
- [ ] 规则模板市场
- [ ] macOS/iPadOS 应用
- [ ] Web 管理后台
- [ ] 审计日志导出
- [ ] 多语言支持（MVP 仅英文）
- [ ] 规则冲突检测
- [ ] 机器学习风险评分

## 🛠️ 技术栈

| 组件 | 技术 |
|------|------|
| sentinel-cli | Node.js 20, TypeScript, Express, Socket.IO Client |
| sentinel-server | Node.js 20, Fastify, Socket.IO, Prisma, Redis, APNs |
| sentinel-ios | Swift 5.9, SwiftUI, iOS 17+ |
| 加密 | X25519 (密钥交换), NaCl (对称加密) |
| 数据库 | PostgreSQL 16, Redis 7 |
| 部署 | Docker, Docker Compose |

## 📖 文档

- [架构设计](docs/architecture.md)
- [API 文档](docs/api.md)
- [规则语法](docs/rules.md)
- [部署指南](docs/deployment.md)
- [开发指南](docs/development.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

Made with ❤️ by Sentinel Team
