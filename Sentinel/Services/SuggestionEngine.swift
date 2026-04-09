import Foundation

enum SuggestionEngine {
    static let threshold = 5

    static func analyze(
        history: [DecisionRecord],
        dismissedPatterns: Set<String>
    ) -> RuleSuggestion? {
        let recentAllows = history
            .filter { $0.decision == .allowed }
            .prefix(threshold)

        guard recentAllows.count >= threshold else { return nil }

        let toolNames = Set(recentAllows.map(\.request.toolName))
        guard toolNames.count == 1, let toolName = toolNames.first else { return nil }

        let paths = recentAllows.compactMap { ApprovalHelper.extractPath(from: $0.request) }
        let pattern = inferPattern(paths: paths)

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
        } else {
            return nil
        }
    }
}
