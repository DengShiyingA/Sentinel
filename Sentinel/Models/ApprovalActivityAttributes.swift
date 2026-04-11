import ActivityKit
import Foundation

/// Shared ActivityAttributes for Sentinel approval Live Activities.
/// Included in BOTH the main app target AND the SentinelWidget extension target.
public struct ApprovalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var secondsRemaining: Int
        public var phase: Phase

        public init(secondsRemaining: Int, phase: Phase) {
            self.secondsRemaining = secondsRemaining
            self.phase = phase
        }

        public enum Phase: String, Codable, Hashable {
            case pending
            case approved
            case denied
            case timeout
        }
    }

    public let requestId: String
    public let toolName: String
    public let summary: String
    public let riskLevelRaw: String
    public let startedAt: Date
    public let timeoutAt: Date

    public init(
        requestId: String,
        toolName: String,
        summary: String,
        riskLevelRaw: String,
        startedAt: Date,
        timeoutAt: Date
    ) {
        self.requestId = requestId
        self.toolName = toolName
        self.summary = summary
        self.riskLevelRaw = riskLevelRaw
        self.startedAt = startedAt
        self.timeoutAt = timeoutAt
    }

    /// Parse `riskLevelRaw` into a display string the widget can show without importing app models.
    public var riskLabel: String {
        switch riskLevelRaw {
        case "require_faceid": return "高风险"
        case "require_confirm": return "需确认"
        default: return "审批"
        }
    }

    public var isHighRisk: Bool {
        riskLevelRaw == "require_faceid"
    }
}
