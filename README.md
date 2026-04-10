# Sentinel

**Claude Code 的移动端安全审批引擎**

让 AI 执行危险操作前，必须经过你的手机确认。

---

## 功能

- **内联审批** — 终端流中直接审批，无需切换页面
- **Diff 预览** — 审批时查看代码变更，行号 + 红绿着色
- **智能分组** — 同类请求自动合并，一键批量操作
- **临时信任** — 信任工具/路径模式，减少重复审批
- **高风险保护** — .env/secrets 等文件强制 Face ID 验证
- **智能规则建议** — 从历史决策中学习，自动推荐规则
- **会话摘要** — 任务完成时推送摘要通知
- **斜杠命令** — 38 个命令，手机端操控 Claude Code
- **远程穿透** — Cloudflare Tunnel 支持跨网络访问
- **扫码连接** — 扫描终端二维码一秒连接

---

## 安装 CLI

```bash
git clone https://github.com/DengShiyingA/Sentinel.git && cd Sentinel && ./install.sh && sentinel install
```

## 使用

```bash
# 局域网模式（同一 WiFi）
sentinel start

# 远程模式（跨网络，需要 brew install cloudflared）
sentinel start --remote
```

iPhone 打开 Sentinel App → 扫描终端二维码 → 连接成功

## iOS App

从 App Store 下载（即将上架）

---

## CLI 命令

```bash
sentinel start              # 启动服务
sentinel start --remote     # 远程穿透模式
sentinel install            # 注入 hook 到 Claude Code
sentinel status             # 查看状态
sentinel rules              # 查看规则
sentinel watch              # 实时监控
sentinel test hook          # 发送测试请求
sentinel doctor             # 环境诊断
sentinel block on           # 封锁所有请求
sentinel allow on           # 放行所有请求
sentinel budget set 5       # 设置每日预算 $5
```

---

## 技术栈

| 层 | 技术 |
|---|------|
| iOS App | Swift + SwiftUI + iOS 17+ |
| CLI | Node.js + TypeScript |
| 传输 | TCP + Bonjour/mDNS + E2EE |

## License

MIT
