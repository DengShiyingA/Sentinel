import UserNotifications
import UIKit
import OSLog

private let log = Logger(subsystem: "com.sentinel.ios", category: "Notifications")

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Callback: (requestId, decision) — set by ApprovalStore to handle lock-screen actions
    var onNotificationAction: ((String, Decision) -> Void)?

    /// Whether notifications are enabled. UI can observe this to show warnings.
    private(set) var isPermissionGranted = false
    private(set) var permissionChecked = false

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setup() {
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
        requestPermission()
    }

    /// Re-check current permission status (call when app becomes active)
    func refreshPermissionStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.isPermissionGranted = settings.authorizationStatus == .authorized
                self.permissionChecked = true
            }
        }
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
                await MainActor.run {
                    self.isPermissionGranted = granted
                    self.permissionChecked = true
                }
                if granted {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    log.info("Notification permission granted")
                } else {
                    log.warning("Notification permission denied — approvals will only appear in-app")
                }
            } catch {
                log.error("Notification permission error: \(error.localizedDescription)")
                await MainActor.run {
                    self.permissionChecked = true
                }
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

    /// Post a simple notification (from sentinel notify command)
    func postSimpleNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
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
