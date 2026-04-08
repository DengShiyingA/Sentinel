# Sentinel Remote

**AI agent 的安全审批引擎 — 让 Claude Code 每一步危险操作都经过你的确认。**

The security approval engine for Claude Code.
Every dangerous tool call needs your confirmation before execution.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2-0175C2)](https://dart.dev)
[![iOS 15+](https://img.shields.io/badge/iOS-15%2B-blue)](https://developer.apple.com/ios/)
[![Android](https://img.shields.io/badge/Android-API_26%2B-34A853)](https://developer.android.com)
[![Web](https://img.shields.io/badge/Web-Chrome_90%2B-4285F4)](https://www.google.com/chrome/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## vs Happy Coder

| | Happy Coder | Sentinel Remote |
|---|---|---|
| 定位 | 终端镜像 | **审批引擎** |
| 规则引擎 | ❌ | ✅ glob 匹配 + 5 种权限模式 |
| Face ID | ❌ | ✅ 高风险操作强制验证 |
| Diff 预览 | ❌ | ✅ 审批时直接看文件变更 |
| 批量审批 | ❌ | ✅ 长按多选一键操作 |
| 临时信任 | ❌ | ✅ "信任 Write 15 分钟" |
| 预算管理 | ❌ | ✅ 每日限额 + 花费追踪 |
| 锁屏操作 | ❌ | ✅ 通知栏直接 allow/block |
| 一键封锁 | ❌ | ✅ `sentinel block on` |
| 零云依赖 | ❌ 必须走云 | ✅ LAN 直连默认 |
| 跨平台 | React Native | **Flutter** (iOS + Android + Web) |
| CLI 命令 | ~10 | **17+** |

---

## 主要特性

- 🛡️ **智能审批** — 按风险自动放行 / 推送审批 / Face ID
- 📄 **Diff 预览** — 审批时直接看 Claude 要改什么
- ✅ **批量操作** — 长按多选，一键全部允许或拒绝
- ⏱️ **临时信任** — "信任 Write 15 分钟" 减少打扰
- 📱 **三平台** — iOS / Android / Web 一套代码
- 🔌 **三种连接** — 局域网直连 / CloudKit / 自建服务器
- 💰 **预算控制** — 每日花费追踪和限额
- 🔒 **一键封锁** — 立即冻结所有操作
- 📟 **实时终端** — 手机看 Claude Code 输出
- 💬 **消息互动** — 手机发消息给 Claude Code
- 📋 **规则管理** — 手机端增删改规则

---

## 快速开始

### 1. 安装 CLI

```bash
git clone https://github.com/DengShiyingA/Sentinel.git
cd Sentinel && ./install.sh
```

### 2. 注入 Hook 并启动

```bash
sentinel install
sentinel start
```

### 3. 运行 App

**iOS / Android:**
```bash
cd packages/sentinel-app
flutter run
```

**Web:**
```bash
cd packages/sentinel-app
flutter run -d chrome
```

### 4. 连接

- **iOS:** 设置 → 局域网模式 → 手动连接 `localhost:7750`
- **Web:** 设置 → 自建服务器模式 → 输入 `http://localhost:3005`

---

## 截图

| 审批列表 | Diff 预览 | 批量审批 |
|---------|----------|---------|
| ![审批](docs/screenshots/approval.png) | ![Diff](docs/screenshots/diff.png) | ![批量](docs/screenshots/batch.png) |

| 终端输出 | 消息互动 | 规则管理 |
|---------|---------|---------|
| ![终端](docs/screenshots/terminal.png) | ![消息](docs/screenshots/messages.png) | ![规则](docs/screenshots/rules.png) |

---

## 平台支持

| 功能 | iOS | Android | Web |
|------|-----|---------|-----|
| LAN 直连 | ✅ | ✅ | ❌ |
| Server 模式 | ✅ | ✅ | ✅ |
| Face ID / 指纹 | ✅ | ✅ | ❌ |
| 本地通知 | ✅ | ✅ | ❌ |
| Diff 预览 | ✅ | ✅ | ✅ |
| 批量审批 | ✅ | ✅ | ✅ |
| 临时信任 | ✅ | ✅ | ✅ |
| 规则管理 | ✅ | ✅ | ✅ |
| 终端输出 | ✅ | ✅ | ✅ |
| 深色模式 | ✅ | ✅ | ✅ |

---

## 测试

```bash
# 确保 sentinel 正在运行
sentinel doctor

# 发送测试请求
curl -X POST http://localhost:7749/hook \
  -H 'Content-Type: application/json' \
  -d '{"tool_name":"Write","tool_input":{"file_path":"/src/app.ts","content":"test"}}'

# 或使用内置测试命令
sentinel test hook
sentinel test rules
```

App 设置页也有"调试工具"按钮可以一键发送不同风险等级的测试请求。

---

## CLI 命令速查

```bash
sentinel start              # 启动（默认局域网）
sentinel start --daemon     # 后台运行
sentinel doctor             # 环境诊断
sentinel status             # 查看状态
sentinel logs               # 审批历史
sentinel rules              # 规则列表
sentinel mode               # 查看/切换权限模式
sentinel watch              # 实时事件流
sentinel budget set 5       # 每日 $5 上限
sentinel block on           # 一键封锁
sentinel allow on           # 一键放行
sentinel notify "Done!"     # 推送通知到手机
sentinel test rules         # 规则测试
sentinel daemon start       # 后台服务
sentinel sessions           # 会话历史
```

---

## 技术栈

| 层 | 技术 |
|----|------|
| 移动端 | Flutter 3.x + Riverpod 3.x + GoRouter |
| CLI | Node.js 20 + TypeScript + Express |
| 服务器 | Fastify + Socket.IO + PGlite |
| 加密 | Ed25519 + tweetnacl + ChaChaPoly |
| 认证 | JWT (challenge-response) |
| LAN | TCP + Bonjour/mDNS |

---

## 项目结构

```
packages/
├── sentinel-cli/       # Mac 端 CLI (17+ 命令)
├── sentinel-server/    # 远程中继服务器 (可选)
└── sentinel-app/       # Flutter 跨平台 App
    └── lib/
        ├── core/       # 连接、加密、认证、信任
        ├── features/   # 审批、消息、规则、设置
        └── shared/     # 模型、组件、工具
```

---

## 贡献

欢迎 PR 和 Issue。

```bash
# 开发
cd packages/sentinel-cli && npm run dev
cd packages/sentinel-app && flutter run

# 测试
sentinel test rules
flutter test
```

---

## License

MIT
