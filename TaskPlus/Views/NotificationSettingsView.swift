import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var settings: NotificationSettings
    @State private var showingPermissionAlert = false
    
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
                
                // デイリーレビュー
                Section("デイリーレビュー") {
                    Toggle("毎日のタスク振り返り", isOn: $settings.dailySummaryEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    if settings.dailySummaryEnabled {
                        HStack {
                            Image(systemName: "sunrise")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("通知時間")
                            Spacer()
                            DatePicker("", selection: $settings.dailySummaryTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("選択した時間に毎日デイリーレビューが表示されます")
                                .font(.caption)
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                    }
                }
                
                // ウィークリーレビュー
                Section("ウィークリーレビュー") {
                    Toggle("毎週のタスク振り返り", isOn: $settings.weeklyReviewEnabled)
                        .tint(TaskPlusTheme.colors.neonPrimary)
                    
                    if settings.weeklyReviewEnabled {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("曜日")
                            Spacer()
                            Picker("", selection: $settings.weeklyReviewDay) {
                                Text("日曜日").tag(0)
                                Text("月曜日").tag(1)
                                Text("火曜日").tag(2)
                                Text("水曜日").tag(3)
                                Text("木曜日").tag(4)
                                Text("金曜日").tag(5)
                                Text("土曜日").tag(6)
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("通知時間")
                            Spacer()
                            DatePicker("", selection: $settings.weeklyReviewTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("選択した曜日・時間に毎週ウィークリーレビューが表示されます")
                                .font(.caption)
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
            }
            .onChange(of: settings) { _ in
                // 設定が変更されたら自動保存
                notificationManager.updateNotificationSettings(settings)
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
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    NotificationSettingsView(notificationManager: NotificationManager.shared)
}
