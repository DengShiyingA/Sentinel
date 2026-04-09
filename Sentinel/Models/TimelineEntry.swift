import Foundation

struct TimelineEntry: Identifiable {
    let id: String
    let time: Date
    let order: Int
    let kind: Kind

    enum Kind {
        case terminal(String)
        case user(String)
        case claude(String)
        case approval(ApprovalRequest)
        case approvalGroup(ApprovalGroup)
        case suggestion(RuleSuggestion)
        case summary(SessionSummary)
    }
}

struct ApprovalGroup: Identifiable {
    let id: String
    let toolName: String
    var requests: [ApprovalRequest]
    var displayLabel: String {
        "\(requests.count) \(toolNameLabel) \(String(localized: "待审批"))"
    }

    private var toolNameLabel: String {
        let name = toolName.lowercased()
        if name.contains("write") || name.contains("edit") {
            return String(localized: "个文件编辑")
        } else if name.contains("bash") || name.contains("exec") {
            return String(localized: "个命令执行")
        } else if name.contains("read") {
            return String(localized: "个文件读取")
        } else {
            return String(localized: "个操作")
        }
    }
}

struct DecisionRecord: Identifiable {
    let id: String
    let request: ApprovalRequest
    let decision: Decision
    let decidedAt: Date
}
