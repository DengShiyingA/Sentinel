import SwiftUI

enum ClaudeModel: String, CaseIterable {
    case haiku = "claude-haiku-4-5-20251001"
    case sonnet = "claude-sonnet-4-6"
    case opus = "claude-opus-4-6"

    var displayName: String {
        switch self {
        case .haiku: return "Haiku"
        case .sonnet: return "Sonnet"
        case .opus: return "Opus"
        }
    }

    var description: String {
        switch self {
        case .haiku: return "快速 · 适合简单任务"
        case .sonnet: return "均衡 · 推荐"
        case .opus: return "最强 · 适合复杂任务"
        }
    }

    var color: Color {
        switch self {
        case .haiku: return .green
        case .sonnet: return .blue
        case .opus: return .purple
        }
    }
}
