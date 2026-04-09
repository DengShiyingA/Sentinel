import Foundation

struct RuleSuggestion: Identifiable {
    let id: String
    let toolName: String
    let pathPattern: String?
    let matchCount: Int
    let timestamp: Date

    var displayText: String {
        if let pattern = pathPattern {
            return String(localized: "连续允许了 \(matchCount) 次 \(toolName) \(pattern)，要自动允许吗？")
        } else {
            return String(localized: "连续允许了 \(matchCount) 次 \(toolName)，要自动允许吗？")
        }
    }
}
