import Foundation
import UIKit

enum ApprovalHelper {
    /// Extract display path from approval request tool input.
    static func extractPath(from request: ApprovalRequest) -> String? {
        request.toolInput["file_path"]?.description
            ?? request.toolInput["path"]?.description
            ?? request.toolInput["command"]?.description
    }

    /// Human-readable tool name for display.
    static func humanReadableToolName(for toolName: String) -> String {
        let name = toolName.lowercased()
        if name.contains("write") || name.contains("edit") {
            return String(localized: "文件写入")
        } else if name.contains("bash") || name.contains("exec") {
            return String(localized: "命令执行")
        } else if name.contains("read") {
            return String(localized: "文件读取")
        } else if name.contains("grep") || name.contains("search") || name.contains("glob") {
            return String(localized: "文件搜索")
        } else if name.contains("delete") || name.contains("rm") {
            return String(localized: "文件删除")
        } else {
            return String(localized: "工具调用")
        }
    }

    /// Handle allow with optional biometric auth. Calls `onSuccess` on main thread if approved.
    static func handleAllow(
        request: ApprovalRequest,
        onSuccess: @escaping () -> Void,
        onAuthStart: @escaping () -> Void,
        onAuthEnd: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) {
        if request.riskLevel == .requireFaceID {
            onAuthStart()
            Task {
                do {
                    try await BiometricService.authenticate(
                        reason: String(localized: "验证身份以允许高风险操作")
                    )
                    await MainActor.run {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        onSuccess()
                        onAuthEnd()
                    }
                } catch {
                    await MainActor.run {
                        onError(error.localizedDescription)
                        onAuthEnd()
                    }
                }
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSuccess()
        }
    }
}
