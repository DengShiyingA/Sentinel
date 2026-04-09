import Foundation
import WidgetKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "SharedState")

enum SharedStateWriter {
    static func update(
        isConnected: Bool,
        pendingRequests: [ApprovalRequest],
        resolvedCount: Int
    ) {
        let latestRequest = pendingRequests.first
        let state = WidgetState(
            isConnected: isConnected,
            pendingCount: pendingRequests.count,
            resolvedCount: resolvedCount,
            latestToolName: latestRequest?.toolName,
            latestPath: latestRequest.flatMap { ApprovalHelper.extractPath(from: $0) },
            latestRiskLevel: latestRequest?.riskLevel.rawValue,
            updatedAt: Date()
        )
        state.write()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
