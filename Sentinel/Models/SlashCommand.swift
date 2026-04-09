import Foundation

struct SlashCommand: Identifiable {
    let id: String
    let label: String
    let icon: String
    let description: String

    static let all: [SlashCommand] = [
        SlashCommand(id: "block", label: "/block", icon: "hand.raised.fill", description: "封锁所有请求"),
        SlashCommand(id: "allow", label: "/allow", icon: "checkmark.shield", description: "放行所有请求"),
        SlashCommand(id: "status", label: "/status", icon: "info.circle", description: "查看连接状态"),
        SlashCommand(id: "rules", label: "/rules", icon: "slider.horizontal.3", description: "查看当前规则"),
        SlashCommand(id: "trust", label: "/trust", icon: "clock.badge.checkmark", description: "查看临时信任"),
        SlashCommand(id: "clear", label: "/clear", icon: "trash", description: "清空终端"),
        SlashCommand(id: "stats", label: "/stats", icon: "chart.bar", description: "查看今日统计"),
        SlashCommand(id: "reconnect", label: "/reconnect", icon: "arrow.clockwise", description: "重新连接"),
    ]

    static func matching(_ query: String) -> [SlashCommand] {
        let q = query.lowercased().dropFirst()
        if q.isEmpty { return all }
        return all.filter { $0.id.hasPrefix(q) }
    }
}
