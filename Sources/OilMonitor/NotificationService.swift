import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject {

    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await refreshStatus()
            return granted
        } catch {
            return false
        }
    }

    func send(_ firing: AlertFiring) {
        guard authorizationStatus == .authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = firing.notificationTitle
        content.body  = firing.notificationBody
        content.sound = .default
        let id = "oilpulse-\(firing.symbol.rawValue)-\(firing.direction == .above ? "up" : "dn")-\(Int(firing.marketTime.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func sendTest(for symbol: OilSymbol) {
        let content = UNMutableNotificationContent()
        content.title = "\(symbol.displayName) 价格提醒测试"
        content.body  = "通知权限正常，OilPulse 可以发送价格提醒。"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "oilpulse-test-\(symbol.rawValue)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    // Show notifications even when the app is active (menu bar panel open).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
