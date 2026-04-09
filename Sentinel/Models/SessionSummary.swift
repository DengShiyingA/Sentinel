import Foundation

struct SessionSummary: Identifiable {
    let id: String
    let filesModified: [String]
    let commandsRun: Int
    let approvalsAllowed: Int
    let approvalsBlocked: Int
    let isError: Bool
    let duration: TimeInterval
    let timestamp: Date

    var displayTitle: String {
        isError
            ? String(localized: "任务失败")
            : String(localized: "任务完成")
    }

    var displaySubtitle: String {
        var parts: [String] = []
        if !filesModified.isEmpty {
            parts.append(String(localized: "修改 \(filesModified.count) 个文件"))
        }
        if commandsRun > 0 {
            parts.append(String(localized: "\(commandsRun) 个命令"))
        }
        return parts.isEmpty ? String(localized: "无操作") : parts.joined(separator: "，")
    }

    var durationText: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
}
