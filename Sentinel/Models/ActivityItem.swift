import Foundation

enum ActivityType: String, Codable {
    case toolCompleted  = "tool_completed"
    case notification   = "notification"
    case stop           = "stop"
    case taskCompleted  = "task_completed"
    case sessionEnded   = "session_ended"
    case userMessage    = "user_message"
    case claudeResponse = "claude_response"
    case claudeStatus   = "claude_status"

    var systemImage: String {
        switch self {
        case .toolCompleted:  "checkmark.circle"
        case .notification:   "bell"
        case .stop:           "flag.checkered"
        case .taskCompleted:  "checkmark.seal"
        case .sessionEnded:   "clock"
        case .userMessage:    "text.bubble"
        case .claudeResponse: "bubble.left.fill"
        case .claudeStatus:   "ellipsis.bubble"
        }
    }

    var label: String {
        switch self {
        case .toolCompleted:  String(localized: "工具完成")
        case .notification:   String(localized: "通知")
        case .stop:           String(localized: "任务结束")
        case .taskCompleted:  String(localized: "子任务完成")
        case .sessionEnded:   String(localized: "会话结束")
        case .userMessage:    String(localized: "用户消息")
        case .claudeResponse: String(localized: "Claude 回复")
        case .claudeStatus:   String(localized: "思考中...")
        }
    }
}

struct ActivityItem: Identifiable, Codable {
    let id: String
    let type: ActivityType
    let summary: String
    let toolName: String?
    let timestamp: Date
    let stopReason: String?
    let message: String?

    var isError: Bool {
        stopReason == "error"
    }
}
