import UserNotifications
import UIKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "Notifications")

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Callback: (requestId, decision) — set by ApprovalStore to handle lock-screen actions
    var onNotificationAction: ((String, Decision) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setup() {
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
        requestPermission()
    }

    private func registerCategories() {
        let allowAction = UNNotificationAction(
            identifier: "ALLOW",
            title: String(localized: "允许"),
            options: [.authenticationRequired]
        )
        let blockAction = UNNotificationAction(
            identifier: "BLOCK",
            title: String(localized: "拒绝"),
            options: [.destructive]
        )

        let approvalCategory = UNNotificationCategory(
            identifier: "APPROVAL_ACTIONS",
            actions: [allowAction, blockAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([approvalCategory])
    }

    private func requestPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    log.info("Notification permission granted")
                } else {
                    log.info("Notification permission denied")
                }
            } catch {
                log.error("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Post Local Notification (for foreground fallback)

    func postApprovalNotification(requestId: String, toolName: String, riskLevel: RiskLevel) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Sentinel 审批请求")
        content.body = String(localized: "工具: \(toolName)")
        content.sound = .default
        content.categoryIdentifier = "APPROVAL_ACTIONS"
        content.userInfo = ["requestId": requestId]

        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: nil // immediate
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification action (lock-screen allow/block buttons)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let requestId = response.notification.request.content.userInfo["requestId"] as? String ?? ""

        switch response.actionIdentifier {
        case "ALLOW":
            onNotificationAction?(requestId, .allowed)
        case "BLOCK":
            onNotificationAction?(requestId, .blocked)
        default:
            break // opened the app, handled by normal UI flow
        }

        completionHandler()
    }

    /// Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
