# Sentinel Remote

**AI 编码代理的安全审批引擎**  
让 Claude Code 的每一次危险操作，都必须经过你的确认。

**The security approval engine for Claude Code.**  
Every dangerous tool call requires your explicit approval.

---

## 与 Happy 的核心对比

| 特性               | Happy Coder               | **Sentinel Remote**                  |
|--------------------|---------------------------|--------------------------------------|
| 核心定位           | 远程控制终端              | **安全审批引擎**                     |
| 规则引擎           | 无                        | **强大规则系统**（路径/工具/风险）   |
| Diff 预览          | 无                        | **审批时直接查看文件变更**           |
| 批量审批           | 无                        | **长按多选，一键操作**               |
| 临时信任           | 无                        | **信任 Write 15 分钟**               |
| Face ID / 生物识别 | 无                        | **高风险强制验证**                   |
| 零云依赖           | 必须走云                  | **默认 LAN 直连**                    |
| 跨平台             | React Native              | **Flutter**（iOS + Web + Android）   |
| CLI 命令数量       | ~10                       | **17+**                              |
| 一键封锁           | 无                        | **支持**                             |

**Sentinel Remote 在安全与效率上全面领先。**

---

## 主要特性

- **智能审批** — 自动放行安全操作，高风险推送审批 + Face ID
- **Diff 预览** — 审批时直接看到 Claude 要修改的具体代码
- **批量审批** — 长按多选，一键全部允许或拒绝
- **临时信任** — “信任 Write 15 分钟”，大幅减少重复审批
- **规则管理** — 手机端轻松增删改规则，实时同步
- **三种连接** — 局域网直连 / iCloud / 自建服务器
- **实时终端 + 消息** — 手机查看输出并继续与 Claude 对话
- **预算控制** — 设置每日花费上限

---

## 快速开始（三步）

```bash
# 1. 克隆并安装
git clone https://github.com/DengShiyingA/Sentinel.git
cd Sentinel && ./install.sh

# 2. 注入 Hook 并启动
sentinel install
sentinel start
运行 App：

iOS / Android：cd packages/sentinel-app && flutter run
Web：cd packages/sentinel-app && flutter run -d chrome

连接方式：

iOS：设置 → 局域网模式 → 连接 localhost:7750
Web：设置 → 自建服务器模式 → 输入服务器地址


截图
审批列表 + Diff 预览
<img src="https://via.placeholder.com/800x500?text=Approval+List+with+Diff" alt="审批界面">
批量审批模式
<img src="https://via.placeholder.com/800x500?text=Batch+Approval" alt="批量审批">
规则管理页
<img src="https://via.placeholder.com/800x500?text=Rules+Management" alt="规则管理">
Web Dashboard
<img src="https://via.placeholder.com/800x500?text=Web+Dashboard" alt="Web 界面">

平台支持


















































功能iOSWebLAN 直连支持不支持Server 模式支持支持Face ID支持跳过本地通知支持不支持Diff 预览支持支持批量审批支持支持临时信任支持支持规则管理支持支持

CLI 常用命令
Bashsentinel start                  # 启动服务
sentinel doctor                 # 环境检查
sentinel watch                  # 实时监控
sentinel budget set 5           # 设置每日预算 $5
sentinel block on               # 一键冻结所有操作
sentinel rules                  # 查看规则
sentinel test hook              # 发送测试请求

技术栈

移动端：Flutter 3.x + Riverpod 3.x + GoRouter
CLI：Node.js + TypeScript
传输：Socket.IO + TCP + Bonjour/mDNS
安全：E2EE + JWT + Face ID


License
MIT
欢迎 Star、Issue 和 PR！
