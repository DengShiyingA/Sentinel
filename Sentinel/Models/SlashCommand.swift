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
        SlashCommand(id: "init", label: "/init", icon: "doc.badge.plus", description: "初始化 CLAUDE.md", category: .claude),
        SlashCommand(id: "review-pr", label: "/review-pr", icon: "eye", description: "审查 Pull Request", category: .claude),
        SlashCommand(id: "commit", label: "/commit", icon: "arrow.triangle.branch", description: "提交代码", category: .claude),
        SlashCommand(id: "add-dir", label: "/add-dir", icon: "folder.badge.plus", description: "添加工作目录", category: .claude),
    ]

    static func matching(_ query: String) -> [SlashCommand] {
        let q = query.lowercased().dropFirst()
        if q.isEmpty { return all }
        return all.filter { $0.id.hasPrefix(q) || $0.label.dropFirst().hasPrefix(q) }
    }
}
