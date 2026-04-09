import Foundation

struct SlashCommand: Identifiable {
    let id: String
    let label: String
    let icon: String
    let description: String
    let category: Category

    enum Category: String {
        case local
        case claude
    }

    static let all: [SlashCommand] = localCommands + claudeCommands

    static let localCommands: [SlashCommand] = [
        SlashCommand(id: "help", label: "/help", icon: "questionmark.circle", description: "显示所有命令", category: .local),
        SlashCommand(id: "block", label: "/block", icon: "hand.raised.fill", description: "封锁所有请求", category: .local),
        SlashCommand(id: "allow", label: "/allow", icon: "checkmark.shield", description: "放行所有请求", category: .local),
        SlashCommand(id: "status", label: "/status", icon: "info.circle", description: "查看连接状态", category: .local),
        SlashCommand(id: "rules", label: "/rules", icon: "slider.horizontal.3", description: "查看当前规则", category: .local),
        SlashCommand(id: "trust", label: "/trust", icon: "clock.badge.checkmark", description: "查看临时信任", category: .local),
        SlashCommand(id: "untrust", label: "/untrust", icon: "xmark.shield", description: "清除所有临时信任", category: .local),
        SlashCommand(id: "clear", label: "/clear", icon: "trash", description: "清空终端", category: .local),
        SlashCommand(id: "stats", label: "/stats", icon: "chart.bar", description: "查看今日统计", category: .local),
        SlashCommand(id: "history", label: "/history", icon: "clock.arrow.circlepath", description: "最近决策记录", category: .local),
        SlashCommand(id: "budget", label: "/budget", icon: "dollarsign.circle", description: "今日 API 用量", category: .local),
        SlashCommand(id: "mode", label: "/mode", icon: "network", description: "查看/切换连接模式", category: .local),
        SlashCommand(id: "reconnect", label: "/reconnect", icon: "arrow.clockwise", description: "重新连接", category: .local),
        SlashCommand(id: "doctor", label: "/doctor", icon: "stethoscope", description: "诊断连接和配置", category: .local),
    ]

    static let claudeCommands: [SlashCommand] = [
        SlashCommand(id: "cc-init", label: "/init", icon: "doc.badge.plus", description: "初始化 CLAUDE.md", category: .claude),
        SlashCommand(id: "cc-compact", label: "/compact", icon: "arrow.down.right.and.arrow.up.left", description: "压缩对话上下文", category: .claude),
        SlashCommand(id: "cc-clear", label: "/clear", icon: "trash.circle", description: "清空对话历史", category: .claude),
        SlashCommand(id: "cc-cost", label: "/cost", icon: "dollarsign.circle", description: "查看 token 用量", category: .claude),
        SlashCommand(id: "cc-diff", label: "/diff", icon: "doc.badge.gearshape", description: "查看未提交变更", category: .claude),
        SlashCommand(id: "cc-commit", label: "/commit", icon: "arrow.triangle.branch", description: "提交代码", category: .claude),
        SlashCommand(id: "cc-review-pr", label: "/review-pr", icon: "eye", description: "审查 Pull Request", category: .claude),
        SlashCommand(id: "cc-plan", label: "/plan", icon: "list.clipboard", description: "进入计划模式", category: .claude),
        SlashCommand(id: "cc-resume", label: "/resume", icon: "play.circle", description: "恢复之前的对话", category: .claude),
        SlashCommand(id: "cc-model", label: "/model", icon: "cpu", description: "切换模型", category: .claude),
        SlashCommand(id: "cc-effort", label: "/effort", icon: "gauge.medium", description: "设置推理深度", category: .claude),
        SlashCommand(id: "cc-fast", label: "/fast", icon: "hare", description: "切换快速模式", category: .claude),
        SlashCommand(id: "cc-memory", label: "/memory", icon: "brain", description: "编辑记忆文件", category: .claude),
        SlashCommand(id: "cc-permissions", label: "/permissions", icon: "lock.shield", description: "管理工具权限", category: .claude),
        SlashCommand(id: "cc-add-dir", label: "/add-dir", icon: "folder.badge.plus", description: "添加工作目录", category: .claude),
        SlashCommand(id: "cc-mcp", label: "/mcp", icon: "server.rack", description: "管理 MCP 服务器", category: .claude),
        SlashCommand(id: "cc-security-review", label: "/security-review", icon: "shield.lefthalf.filled", description: "安全审查变更", category: .claude),
        SlashCommand(id: "cc-rewind", label: "/rewind", icon: "arrow.counterclockwise", description: "回退对话/代码", category: .claude),
        SlashCommand(id: "cc-export", label: "/export", icon: "square.and.arrow.up", description: "导出对话记录", category: .claude),
        SlashCommand(id: "cc-tasks", label: "/tasks", icon: "checklist", description: "查看后台任务", category: .claude),
        SlashCommand(id: "cc-usage", label: "/usage", icon: "chart.pie", description: "查看用量限制", category: .claude),
        SlashCommand(id: "cc-skills", label: "/skills", icon: "sparkles", description: "查看可用技能", category: .claude),
        SlashCommand(id: "cc-hooks", label: "/hooks", icon: "link", description: "查看 hook 配置", category: .claude),
        SlashCommand(id: "cc-doctor", label: "/doctor", icon: "stethoscope", description: "诊断安装环境", category: .claude),
    ]

    static func matching(_ query: String) -> [SlashCommand] {
        let q = query.lowercased().dropFirst()
        if q.isEmpty { return all }
        return all.filter { $0.id.contains(q) || $0.label.dropFirst().hasPrefix(q) }
    }
}
