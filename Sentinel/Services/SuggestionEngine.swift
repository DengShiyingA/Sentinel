import Foundation

enum SuggestionEngine {
    /// How many recent allows of the same pattern before we propose a rule.
    /// Low enough to catch the "ugh, same thing again" moment; high enough
    /// that a one-off confirmation doesn't spam the timeline.
    static let threshold = 3

    static func analyze(
        history: [DecisionRecord],
        dismissedPatterns: Set<String>
    ) -> RuleSuggestion? {
        let recentAllows = history
            .filter { $0.decision == .allowed }
            .prefix(threshold)

        guard recentAllows.count >= threshold else { return nil }

        // NEVER suggest auto-allow for high-risk requests. If the user had to
        // pass Face ID 3 times, they made 3 explicit decisions — that is the
        // security boundary, not a pattern to automate.
        let hasHighRisk = recentAllows.contains { $0.request.riskLevel == .requireFaceID }
        if hasHighRisk { return nil }

        let toolNames = Set(recentAllows.map(\.request.toolName))
        guard toolNames.count == 1, let toolName = toolNames.first else { return nil }

        let paths = recentAllows.compactMap { ApprovalHelper.extractPath(from: $0.request) }
        let pattern = inferPattern(paths: paths)

        // For tools that run arbitrary code (Bash, shell-like), we refuse to
        // suggest a rule without a path constraint. A rule of "auto-allow
        // every Bash call" is basically yolo mode, and the user should
        // opt into that explicitly via --yolo.
        if isBroadExecutionTool(toolName) && pattern == nil {
            return nil
        }

        let patternKey = "\(toolName):\(pattern ?? "*")"
        guard !dismissedPatterns.contains(patternKey) else { return nil }

        return RuleSuggestion(
            id: UUID().uuidString,
            toolName: toolName,
            pathPattern: pattern,
            matchCount: threshold,
            timestamp: Date()
        )
    }

    static func patternKey(toolName: String, pathPattern: String?) -> String {
        "\(toolName):\(pathPattern ?? "*")"
    }

    private static func isBroadExecutionTool(_ toolName: String) -> Bool {
        let lower = toolName.lowercased()
        return lower.contains("bash") || lower.contains("exec") || lower.contains("shell")
    }

    private static func inferPattern(paths: [String]) -> String? {
        guard paths.count >= 2 else { return paths.first }

        let components = paths.map { path -> (dir: String, ext: String) in
            let nsPath = path as NSString
            let dir = nsPath.deletingLastPathComponent
            let ext = nsPath.pathExtension
            return (dir, ext)
        }

        let dirs = Set(components.map(\.dir))
        let exts = Set(components.map(\.ext))

        if dirs.count == 1, let dir = dirs.first, exts.count == 1, let ext = exts.first, !ext.isEmpty {
            return "\(dir)/*.\(ext)"
        } else if dirs.count == 1, let dir = dirs.first {
            return "\(dir)/*"
        } else if exts.count == 1, let ext = exts.first, !ext.isEmpty {
            // Same extension across different dirs → match any dir with this ext
            return "**/*.\(ext)"
        } else {
            return nil
        }
    }
}
