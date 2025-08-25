import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var settings: NotificationSettings
    @State private var showingPermissionAlert = false
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    
    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
        self._settings = State(initialValue: notificationManager.notificationSettings)
    }
    
    var body: some View {
        NavigationView {
            List {
                // 通知の許可状態
                Section {
                    HStack {
                        Image(systemName: notificationManager.isNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(notificationManager.isNotificationsEnabled ? TaskPlusTheme.colors.success : TaskPlusTheme.colors.danger)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notificationManager.isNotificationsEnabled ? "通知が有効" : "通知が無効")
                                .font(.headline)
                            Text(notificationManager.isNotificationsEnabled ? "タスクのリマインダーを受け取れます" : "設定で通知を有効にしてください")
                                .font(.caption)
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if !notificationManager.isNotificationsEnabled {
                            Button("許可") {
                                requestPermission()
                            }
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                    }
                }
                
                // タスクリマインダー
                Section("タスクリマインダー") {
                    Toggle("期限前リマインダー", isOn: $settings.taskRemindersEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    if settings.taskRemindersEnabled {
                        HStack {
                            Text("リマインダー時間")
                            Spacer()
                            Picker("", selection: $settings.reminderTime) {
                                Text("15分前").tag(15)
                                Text("30分前").tag(30)
                                Text("1時間前").tag(60)
                                Text("2時間前").tag(120)
                                Text("1日前").tag(1440)
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                    }
                }
                
                // デイリーサマリー
                Section("デイリーサマリー") {
                    Toggle("毎朝のタスク確認", isOn: $settings.dailySummaryEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    if settings.dailySummaryEnabled {
                        HStack {
                            Image(systemName: "sunrise")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("毎朝9時に通知")
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                    }
                }
                
                // フォーカスセッション
                Section("フォーカスセッション") {
                    Toggle("セッション完了通知", isOn: $settings.focusSessionEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    if settings.focusSessionEnabled {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("集中時間終了時に通知")
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                    }
                }
                
                // 静寂時間
                Section("静寂時間") {
                    Toggle("静寂時間を設定", isOn: $settings.quietHoursEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    if settings.quietHoursEnabled {
                        HStack {
                            Text("開始時間")
                            Spacer()
                            DatePicker("", selection: $settings.quietHoursStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        
                        HStack {
                            Text("終了時間")
                            Spacer()
                            DatePicker("", selection: $settings.quietHoursEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        
                        HStack {
                            Image(systemName: "moon.stars")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("この時間帯は通知音を無効にします")
                                .font(.caption)
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                    }
                }
                
                // 通知の詳細設定
                Section("詳細設定") {
                    Toggle("通知音", isOn: $settings.soundEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    Toggle("バイブレーション", isOn: $settings.vibrationEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                }
                
                // 通知のテスト
                Section("通知のテスト") {
                    Button(action: testNotification) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            Text("テスト通知を送信")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                    }
                    .disabled(!notificationManager.isNotificationsEnabled)
                }
            }
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                    }
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("通知の許可が必要です", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                openSettings()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("通知を受け取るには、設定で通知を許可してください。")
        }
        .alert("テスト通知の結果", isPresented: $showingTestResult) {
            Button("OK") { }
        } message: {
            Text(testResultMessage)
        }
    }
    
    // MARK: - Actions
    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            if !granted {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func saveSettings() {
        notificationManager.updateNotificationSettings(settings)
        dismiss()
    }
    
    private func testNotification() {
        // 通知の許可状態を再確認
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("=== Notification Settings ===")
                print("Authorization status: \(settings.authorizationStatus.rawValue) - \(self.getAuthorizationStatusText(settings.authorizationStatus))")
                print("Alert setting: \(settings.alertSetting.rawValue) - \(self.getSettingText(settings.alertSetting))")
                print("Sound setting: \(settings.soundSetting.rawValue) - \(self.getSettingText(settings.soundSetting))")
                print("Badge setting: \(settings.badgeSetting.rawValue) - \(self.getSettingText(settings.badgeSetting))")
                print("Lock screen setting: \(settings.lockScreenSetting.rawValue) - \(self.getSettingText(settings.lockScreenSetting))")
                print("Notification center setting: \(settings.notificationCenterSetting.rawValue) - \(self.getSettingText(settings.notificationCenterSetting))")
                print("================================")
                
                // 通知が表示されるための条件を厳密にチェック
                let canShowNotification = settings.authorizationStatus == .authorized &&
                                        settings.alertSetting == .enabled &&
                                        (settings.notificationCenterSetting == .enabled || settings.lockScreenSetting == .enabled)
                
                print("Can show notification: \(canShowNotification)")
                
                if canShowNotification {
                    // アプリの状態を確認
                    let appState = UIApplication.shared.applicationState
                    print("App state: \(appState.rawValue) - \(self.getAppStateText(appState))")
                    
                    // 通知が許可されている場合のみテスト通知を送信
                    let content = UNMutableNotificationContent()
                    content.title = "テスト通知"
                    content.body = "通知機能が正常に動作しています"
                    content.sound = .default
                    content.categoryIdentifier = "TEST_NOTIFICATION"
                    
                    // フォアグラウンドでも通知を表示するための設定
                    if #available(iOS 14.0, *) {
                        content.interruptionLevel = .timeSensitive
                    }
                    
                    // バッジを表示
                    content.badge = 1
                    
                    print("Test notification badge set to: 1")
                    
                    // Apple公式推奨：より確実な通知表示のため、カレンダーベースのトリガーを使用
                    let calendar = Calendar.current
                    let now = Date()
                    let triggerDate = calendar.date(byAdding: .second, value: 30, to: now) ?? now
                    
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
                        repeats: false
                    )
                    let request = UNNotificationRequest(identifier: "test_notification_\(UUID().uuidString)", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("Test notification failed: \(error)")
                                self.testResultMessage = "テスト通知の送信に失敗しました: \(error.localizedDescription)"
                            } else {
                                print("Test notification scheduled successfully")
                                self.testResultMessage = "テスト通知を送信しました。30秒後に通知が届きます。\n\n※通知が表示されない場合は、以下を確認してください：\n• 通知センターを下にスワイプ\n• ロック画面の確認\n• 設定での通知許可状態\n\nコンソールログで通知の状態を確認できます。"
                            }
                            self.showingTestResult = true
                        }
                    }
                    
                    // デバッグ用：通知センターの状態を確認
                    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                        print("Pending notifications: \(requests.count)")
                        for request in requests {
                            print("Notification ID: \(request.identifier)")
                            if request.identifier.contains("test_notification") {
                                print("✅ Found test notification: \(request.identifier)")
                            }
                        }
                    }
                    
                    // 通知の表示確認（複数回チェック）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 35) {
                        print("=== Checking notification delivery ===")
                        
                        // アプリの状態を詳細に確認
                        let appState = UIApplication.shared.applicationState
                        print("App state at 35s: \(appState.rawValue) - \(self.getAppStateText(appState))")
                        
                        // 通知センターの状態を詳細確認
                        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                            print("Delivered notifications: \(notifications.count)")
                            for notification in notifications {
                                print("Delivered: \(notification.request.identifier)")
                                print("  - Title: \(notification.request.content.title)")
                                print("  - Badge: \(notification.request.content.badge ?? 0)")
                                print("  - Category: \(notification.request.content.categoryIdentifier)")
                            }
                        }
                        
                        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                            print("Pending notifications: \(requests.count)")
                            for request in requests {
                                print("Still pending: \(request.identifier)")
                                if request.identifier.contains("test_notification") {
                                    print("⚠️ Test notification still pending - this should not happen")
                                    print("  - Content: \(request.content.title)")
                                    print("  - Badge: \(request.content.badge ?? 0)")
                                    print("  - Trigger: \(request.trigger?.description ?? "No trigger")")
                                }
                            }
                        }
                        
                        // バッジの現在の状態を確認
                        let currentBadgeCount = UIApplication.shared.applicationIconBadgeNumber
                        print("Current badge count: \(currentBadgeCount)")
                        
                        print("Test notification check completed - badge will be cleared when app becomes active")
                    }
                    
                    // 追加の確認：15秒後と25秒後にもチェック
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        print("15秒後 - Pending notifications:")
                        let appState = UIApplication.shared.applicationState
                        print("App state at 15s: \(appState.rawValue) - \(self.getAppStateText(appState))")
                        
                        // 保留中通知の確認
                        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                            print("Count: \(requests.count)")
                            for request in requests {
                                print("  - \(request.identifier)")
                                if request.identifier.contains("test_notification") {
                                    print("    ✅ Test notification found at 15s")
                                }
                            }
                        }
                        
                        // 配信済み通知の確認
                        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                            print("Delivered at 15s: \(notifications.count)")
                            for notification in notifications {
                                print("  - \(notification.request.identifier)")
                                if notification.request.identifier.contains("test_notification") {
                                    print("    🎯 Test notification DELIVERED at 15s!")
                                    print("      Title: \(notification.request.content.title)")
                                    print("      Badge: \(notification.request.content.badge ?? 0)")
                                }
                            }
                        }
                        
                        // 15秒後のバッジ状態も確認
                        let badgeCount15s = UIApplication.shared.applicationIconBadgeNumber
                        print("Badge count at 15s: \(badgeCount15s)")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
                        print("25秒後 - Pending notifications:")
                        let appState = UIApplication.shared.applicationState
                        print("App state at 25s: \(appState.rawValue) - \(self.getAppStateText(appState))")
                        
                        // 保留中通知の確認
                        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                            print("Count: \(requests.count)")
                            for request in requests {
                                print("  - \(request.identifier)")
                                if request.identifier.contains("test_notification") {
                                    print("    ✅ Test notification found at 25s")
                                }
                            }
                        }
                        
                        // 配信済み通知の確認
                        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                            print("Delivered at 25s: \(notifications.count)")
                            for notification in notifications {
                                print("  - \(notification.request.identifier)")
                                if notification.request.identifier.contains("test_notification") {
                                    print("    🎯 Test notification DELIVERED at 25s!")
                                    print("      Title: \(notification.request.content.title)")
                                    print("      Badge: \(notification.request.content.badge ?? 0)")
                                }
                            }
                        }
                        
                        // 25秒後のバッジ状態も確認
                        let badgeCount25s = UIApplication.shared.applicationIconBadgeNumber
                        print("Badge count at 25s: \(badgeCount25s)")
                    }
                } else {
                    print("Notifications not authorized or properly configured")
                    DispatchQueue.main.async {
                        self.testResultMessage = "通知が正しく設定されていません。\n\n設定で以下を確認してください：\n• 通知が許可されている\n• アラートが有効\n• 通知センターまたはロック画面が有効"
                        self.showingTestResult = true
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Helper Methods
    private func getAuthorizationStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func getSettingText(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }
    
    private func getAppStateText(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "Active (Foreground)"
        case .inactive: return "Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    NotificationSettingsView(notificationManager: NotificationManager.shared)
}
