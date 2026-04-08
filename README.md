# Sentinel

**The approval engine for Claude Code on your iPhone.**
Every dangerous tool call requires your confirmation
before the AI agent can proceed.

[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Get Started in 3 Steps

```bash
# 1. Install CLI
git clone https://github.com/DengShiyingA/Sentinel.git
cd Sentinel && ./install.sh

# 2. Hook into Claude Code and start
sentinel install
sentinel start

# 3. Open Sentinel on iPhone
#    Settings → Local Mode → it finds your Mac automatically
```

That's it. Claude Code now asks your phone before
writing files, running commands, or touching secrets.

---

## Features

- **Approval Rules Engine** — auto-allow reads,
  require confirmation for writes, Face ID for secrets
- **Three Connection Modes** — LAN direct (zero config),
  CloudKit sync, or self-hosted server
- **Lock Screen Actions** — allow/block from the
  notification banner without opening the app
- **Live Monitoring** — approval history, daily stats,
  cost tracking with `sentinel watch`
- **Hot Reload Rules** — edit rules on iPhone,
  changes take effect instantly on Mac
- **Budget Control** — set daily spend limits,
  get warnings when approaching the cap
- **One-Click Override** — `sentinel block on` to freeze
  everything, `sentinel allow on` to ungate temporarily

---

## CLI Commands

```bash
sentinel start           # Start (default: LAN mode)
sentinel start --daemon  # Start in background
sentinel doctor          # Check environment
sentinel status          # View connection + stats
sentinel logs            # Approval history
sentinel rules           # List active rules
sentinel watch           # Live event stream
sentinel budget set 5    # Set daily $5 limit
sentinel block on        # Block all operations
sentinel allow on        # Allow all operations
sentinel notify "Done!"  # Push notification to iPhone
sentinel test rules      # Validate rule matching
```

---

## Default Rules

| Tool | Condition | Risk Level |
|------|-----------|------------|
| Read, Glob, Grep | any path | Auto-allow |
| Write, Edit | normal files | Requires confirmation |
| Write | `.env*`, `secrets/` | Requires Face ID |
| Bash | any command | Requires Face ID |
| * | `/tmp/**` | Auto-allow |

Rules are stored in `~/.sentinel/rules.json`.
Edit on iPhone or on disk — changes hot-reload.

---

## Architecture

```
Claude Code ──hook──→ sentinel-cli ──TCP/WS──→ iPhone
                        :7749              Sentinel App
                          ↑                    ↓
                      allow/block ←── user taps decision
```

**Three modes:**

| Mode | Transport | Setup |
|------|-----------|-------|
| `local` | TCP + Bonjour | Zero config, same WiFi |
| `cloudkit` | iCloud DB | Same Apple ID |
| `server` | Socket.IO + JWT | Self-hosted server |

---

## vs Happy Coder

| | Happy Coder | Sentinel |
|--|-------------|----------|
| Focus | Terminal mirror | Approval engine |
| iOS | Yes | Yes |
| Android | Yes | No |
| Rule engine | No | Yes |
| Face ID gating | No | Yes |
| Budget tracking | No | Yes |
| Lock screen actions | No | Yes |
| Open source | Yes | Yes |

Sentinel is not a terminal app. It does one thing:
**gate dangerous operations behind your phone.**

---

## Project Structure

```
packages/
  sentinel-cli/      # Node.js CLI (npm)
  sentinel-server/   # Fastify relay server (optional)
Sentinel/            # SwiftUI iOS app (Xcode)
install.sh           # One-line setup
```

---

## Development

```bash
# CLI
cd packages/sentinel-cli
npm install && npm run dev

# iOS
open Sentinel.xcodeproj
# Build target: iPhone 17 Pro (Simulator)
# In Settings → Manual Connect → localhost:7750

# Server (optional, for remote mode)
cd packages/sentinel-server
npm install && npm run dev
```

---

## License

MIT

---

<details>
<summary>中文说明</summary>

## Sentinel — Claude Code 的 iOS 审批引擎

让 AI agent 执行危险操作前，必须经过你的手机确认。

### 三步上手

```bash
# 1. 安装
git clone https://github.com/DengShiyingA/Sentinel.git
cd Sentinel && ./install.sh

# 2. 注入 hook 并启动
sentinel install
sentinel start

# 3. iPhone 打开 Sentinel App
#    设置 → 局域网模式 → 自动发现 Mac
```

### 核心功能

- **审批规则引擎** — 按风险自动放行/推送审批/要求 Face ID
- **三种连接模式** — 局域网直连（零配置）/ CloudKit / 自建服务器
- **锁屏快捷操作** — 通知栏直接 allow/block，无需打开 App
- **实时监控** — 审批历史、今日统计、成本追踪
- **规则热重载** — 手机端改规则实时生效，无需重启
- **预算管理** — 设置每日上限，超额警告
- **一键封锁** — `sentinel block on` 冻结一切操作

### 默认规则

| 操作 | 条件 | 风险级别 |
|------|------|---------|
| Read, Glob, Grep | 任意路径 | 自动放行 |
| Write, Edit | 普通文件 | 需确认 |
| Write | `.env*`, `secrets/` | 需 Face ID |
| Bash | 任意命令 | 需 Face ID |
| * | `/tmp/**` | 自动放行 |

### 与 Happy Coder 的区别

| | Happy Coder | Sentinel |
|--|-------------|----------|
| 定位 | 终端镜像 | 审批引擎 |
| 规则引擎 | 无 | 有 |
| Face ID | 无 | 有 |
| 预算管理 | 无 | 有 |

Sentinel 不是终端应用。它只做一件事：
**让危险操作必须经过你的手机确认。**

</details>
