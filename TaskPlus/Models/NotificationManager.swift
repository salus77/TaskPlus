import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    @Published var notificationSettings = NotificationSettings()
    
    init() {
        checkNotificationStatus()
        loadNotificationSettings()
        setupNotificationCategories()
        
        // 初期化後にデイリーサマリー通知とウィークリーレビュー通知をスケジュール
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.notificationSettings.dailySummaryEnabled {
                self.scheduleDailySummaryNotification()
            }
            if self.notificationSettings.weeklyReviewEnabled {
                self.scheduleWeeklyReviewNotification()
            }
        }
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission() async -> Bool {
        print("DEBUG: Requesting notification permission...")
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            print("DEBUG: Notification permission granted: \(granted)")
            
            await MainActor.run {
                self.isNotificationsEnabled = granted
                
                // 権限が許可された場合、デイリーサマリー通知とウィークリーレビュー通知をスケジュール
                if granted {
                    if self.notificationSettings.dailySummaryEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.scheduleDailySummaryNotification()
                        }
                    }
                    if self.notificationSettings.weeklyReviewEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.scheduleWeeklyReviewNotification()
                        }
                    }
                }
            }
            
            return granted
        } catch {
            print("ERROR: Notification permission error: \(error)")
            return false
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
                print("DEBUG: Notification authorization status: \(settings.authorizationStatus.rawValue)")
                print("DEBUG: Alert setting: \(settings.alertSetting.rawValue)")
                print("DEBUG: Badge setting: \(settings.badgeSetting.rawValue)")
                print("DEBUG: Sound setting: \(settings.soundSetting.rawValue)")
            }
        }
    }
    
    // MARK: - Task Notifications
    func scheduleTaskNotification(for task: TaskItem) {
        guard let dueDate = task.due,
              notificationSettings.taskRemindersEnabled else { return }
        
        // 既存の通知を削除
        removeTaskNotification(for: task)
        
        let content = UNMutableNotificationContent()
        content.title = "タスクの期限が近づいています"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TASK_REMINDER"
        // ロック画面と通知センターでの表示を確実にする
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        // 通知のタイミングを設定
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -notificationSettings.reminderTime, to: dueDate) ?? dueDate
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func removeTaskNotification(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(task.id.uuidString)"]
        )
    }
    
    // MARK: - Daily Summary Notifications
    func scheduleDailySummaryNotification() {
        guard notificationSettings.dailySummaryEnabled else { 
            print("DEBUG: Daily summary notifications are disabled")
            return 
        }
        
        print("DEBUG: Setting up daily summary notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "デイリーレビュー"
        content.body = "今日のタスク振り返りと明日の計画を確認しましょう"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REVIEW"
        // ロック画面と通知センターでの表示を確実にする
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        // ユーザーが選択した時間に通知
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: notificationSettings.dailySummaryTime)
        
        print("DEBUG: Scheduling notification for \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_review",
            content: content,
            trigger: trigger
        )
        
        // 既存の通知を削除してから新しい通知を追加
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_review"])
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ERROR: Failed to schedule daily summary: \(error)")
            } else {
                print("DEBUG: Daily summary notification scheduled successfully for \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
                
                // スケジュールされた通知を確認
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let dailySummaryRequests = requests.filter { $0.identifier == "daily_review" }
                    print("DEBUG: Found \(dailySummaryRequests.count) pending daily summary notifications")
                    
                    for request in dailySummaryRequests {
                        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                            print("DEBUG: Next fire date: \(trigger.nextTriggerDate()?.description ?? "unknown")")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Weekly Review Notifications
    func scheduleWeeklyReviewNotification() {
        guard notificationSettings.weeklyReviewEnabled else {
            print("DEBUG: Weekly review notifications are disabled")
            return
        }
        
        print("DEBUG: Setting up weekly review notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "ウィークリーレビュー"
        content.body = "今週のタスク振り返りと来週の計画を確認しましょう"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REVIEW"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationSettings.weeklyReviewTime)
        var dateComponents = DateComponents()
        dateComponents.weekday = notificationSettings.weeklyReviewDay + 1 // Calendar.weekdayは1=日曜日, 2=月曜日, ...
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        print("DEBUG: Scheduling weekly review notification for weekday \(notificationSettings.weeklyReviewDay) at \(timeComponents.hour ?? 0):\(timeComponents.minute ?? 0)")
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        // 既存の通知を削除してから新しい通知を追加
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_review"])
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ERROR: Failed to schedule weekly review: \(error)")
            } else {
                print("DEBUG: Weekly review notification scheduled successfully for weekday \(self.notificationSettings.weeklyReviewDay) at \(timeComponents.hour ?? 0):\(timeComponents.minute ?? 0)")
                
                // スケジュールされた通知を確認
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let weeklyReviewRequests = requests.filter { $0.identifier == "weekly_review" }
                    print("DEBUG: Found \(weeklyReviewRequests.count) pending weekly review notifications")
                    
                    for request in weeklyReviewRequests {
                        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                            print("DEBUG: Next fire date: \(trigger.nextTriggerDate()?.description ?? "unknown")")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Focus Session Notifications
    func scheduleFocusSessionNotification(duration: TimeInterval, taskTitle: String) {
        guard notificationSettings.focusSessionEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "フォーカスセッション完了"
        content.body = "\(taskTitle)の集中時間が終了しました"
        content.sound = .default
        content.categoryIdentifier = "FOCUS_SESSION"
        // ロック画面と通知センターでの表示を確実にする
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "focus_session_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule focus session notification: \(error)")
            }
        }
    }
    
    // MARK: - Settings Management
    func updateNotificationSettings(_ settings: NotificationSettings) {
        self.notificationSettings = settings
        saveNotificationSettings()
        
        // 既存のデイリーサマリー通知とウィークリーレビュー通知を削除
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_review", "weekly_review"])
        
        // 設定に応じて通知を更新
        if settings.dailySummaryEnabled {
            print("DEBUG: Scheduling daily summary notification for time: \(settings.dailySummaryTime)")
            scheduleDailySummaryNotification()
        } else {
            print("DEBUG: Daily summary notifications disabled")
        }
        
        if settings.weeklyReviewEnabled {
            print("DEBUG: Scheduling weekly review notification for weekday \(settings.weeklyReviewDay) at time: \(settings.weeklyReviewTime)")
            scheduleWeeklyReviewNotification()
        } else {
            print("DEBUG: Weekly review notifications disabled")
        }
    }
    
    private func loadNotificationSettings() {
        if let data = UserDefaults.standard.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationSettings = settings
        }
    }
    
    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "notificationSettings")
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() {
        let totalBadgeCount = getTotalBadgeCount()
        UNUserNotificationCenter.current().setBadgeCount(totalBadgeCount) { error in
            if let error = error {
                print("Failed to update badge count: \(error)")
            } else {
                print("Badge count updated to: \(totalBadgeCount)")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Failed to clear badge: \(error)")
            } else {
                print("Badge cleared successfully")
            }
        }
    }
    
    private func getTotalBadgeCount() -> Int {
        // 今日のタスク数 + 期限切れタスク数
        var count = 0
        
        // 今日のタスク数
        count += TaskStore.shared.todayTasks.count
        
        return max(count, 0)
    }
    
    // MARK: - Notification Categories
    func setupNotificationCategories() {
        let taskReminderCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "COMPLETE_TASK",
                    title: "完了にする",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE_TASK",
                    title: "1時間後に",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let dailyReviewCategory = UNNotificationCategory(
            identifier: "DAILY_REVIEW",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_APP",
                    title: "アプリを開く",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let weeklyReviewCategory = UNNotificationCategory(
            identifier: "WEEKLY_REVIEW",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_APP",
                    title: "アプリを開く",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let focusSessionCategory = UNNotificationCategory(
            identifier: "FOCUS_SESSION",
            actions: [
                UNNotificationAction(
                    identifier: "EXTEND_SESSION",
                    title: "延長する",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "COMPLETE_TASK",
                    title: "タスク完了",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let testNotificationCategory = UNNotificationCategory(
            identifier: "TEST_NOTIFICATION",
            actions: [
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "閉じる",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            taskReminderCategory,
            dailyReviewCategory,
            weeklyReviewCategory,
            focusSessionCategory,
            testNotificationCategory
        ])
        
        print("DEBUG: Notification categories set up successfully")
    }
    
    // MARK: - Test Notification
    func scheduleTestNotification() {
        print("DEBUG: Scheduling test notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = "通知機能が正常に動作しています"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TEST_NOTIFICATION"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        
        // 5秒後に通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ERROR: Failed to schedule test notification: \(error)")
            } else {
                print("SUCCESS: Test notification scheduled successfully")
            }
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable, Equatable {
    var taskRemindersEnabled: Bool = true
    var dailySummaryEnabled: Bool = true
    var weeklyReviewEnabled: Bool = true
    var focusSessionEnabled: Bool = true
    var reminderTime: Int = 30 // 分単位
    var dailySummaryTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var weeklyReviewDay: Int = 1 // 0=日曜日, 1=月曜日, ..., 6=土曜日
    var weeklyReviewTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
}
