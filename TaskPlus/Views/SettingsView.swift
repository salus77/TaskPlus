import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var guideManager: GuideModeManager
    @ObservedObject var taskStore: TaskStore
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportData: Data?
    @State private var showingResetAlert = false
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // ガイドモード設定
                Section("ガイドモード") {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        Text("ガイドモード")
                        Spacer()
                        Toggle("", isOn: $guideManager.isEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: TaskPlusTheme.colors.neonPrimary))
                    }
                    
                    if guideManager.isEnabled {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("ガイドをリセット")
                            Spacer()
                            Button("リセット") {
                                guideManager.tutorialCompleted = false
                                guideManager.isFirstLaunch = true
                                guideManager.currentStep = 0
                            }
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        }
                    }
                }
                
                // 通知設定
                Section("通知設定") {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            Text("通知設定")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                .font(.caption)
                        }
                    }
                }
                
                // FocusPlus連携設定
                Section("FocusPlus連携") {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        Text("ポモドーロ連携")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle(tint: TaskPlusTheme.colors.neonAccent))
                            .disabled(true)
                    }
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        Text("生産性分析")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle(tint: TaskPlusTheme.colors.neonAccent))
                            .disabled(true)
                    }
                    
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        Text("集中セッション記録")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle(tint: TaskPlusTheme.colors.neonAccent))
                            .disabled(true)
                    }
                }
                
                // カテゴリ管理
                Section("カテゴリ管理") {
                    ForEach(taskStore.categories) { category in
                        HStack {
                            Image(systemName: category.icon.systemName)
                                .foregroundColor(category.color.color)
                                .font(.title3)
                            
                            Text(category.name)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            
                            Spacer()
                            
                            Button("編集") {
                                editingCategory = category
                            }
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            .font(.caption)
                        }
                    }
                    
                    Button(action: { showingAddCategory = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            Text("カテゴリを追加")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                    }
                }
                
                // データ管理
                Section("データ管理") {
                    Button(action: exportDataAction) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            Text("データをエクスポート")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                    }
                    
                    Button(action: { showingImportPicker = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            Text("データをインポート")
                                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        }
                    }
                    
                    Button(action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(TaskPlusTheme.colors.danger)
                            Text("すべてのデータをリセット")
                                .foregroundColor(TaskPlusTheme.colors.danger)
                        }
                    }
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Text("最終更新")
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                }
            }
            .navigationTitle("設定")
            .background(TaskPlusTheme.colors.bg)
            .sheet(isPresented: $showingAddCategory) {
                EditCategorySheet(category: nil, taskStore: taskStore)
            }
            .sheet(item: $editingCategory) { category in
                EditCategorySheet(category: category, taskStore: taskStore)
            }
            .sheet(isPresented: $showingExportSheet) {
                if let exportData = exportData {
                    ShareSheet(activityItems: [exportData])
                }
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView(notificationManager: NotificationManager.shared)
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("データリセット", isPresented: $showingResetAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("すべてのタスクとカテゴリが削除されます。この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Actions
    private func exportDataAction() {
        if let data = taskStore.exportData() {
            exportData = data
            showingExportSheet = true
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let success = taskStore.importData(data)
                
                if success {
                    // 成功時のフィードバック
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } else {
                    // エラー時のフィードバック
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }
            } catch {
                print("Import error: \(error)")
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
            
        case .failure(let error):
            print("File selection error: \(error)")
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
    
    private func resetAllData() {
        // タスクをクリア
        taskStore.inboxTasks.removeAll()
        taskStore.todayTasks.removeAll()
        taskStore.doneTasks.removeAll()
        
        // カテゴリをクリア
        taskStore.categories.removeAll()
        
        // デフォルトカテゴリを再追加
        let defaultCategories = [
            Category(name: "仕事", icon: .briefcase, color: .blue),
            Category(name: "プライベート", icon: .heart, color: .pink),
            Category(name: "学習", icon: .book, color: .green),
            Category(name: "家事", icon: .house, color: .orange)
        ]
        
        for category in defaultCategories {
            taskStore.categories.append(category)
        }
        
        // サンプルデータを再読み込み
        let sampleTasks = [
            TaskItem(title: "提案資料をまとめる", priority: .high, context: .work, categoryId: taskStore.categories.first?.id, sortOrder: 0, notificationEnabled: true, notificationTime: nil),
            TaskItem(title: "牛乳を買う", context: .errand, categoryId: taskStore.categories[2].id, sortOrder: 1, notificationEnabled: true, notificationTime: nil),
            TaskItem(title: "田中さんに電話", context: .call, categoryId: taskStore.categories.first?.id, sortOrder: 2, notificationEnabled: false, notificationTime: nil)
        ]
        
        taskStore.inboxTasks.append(contentsOf: sampleTasks)
        
        // フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(
        guideManager: GuideModeManager(),
        taskStore: TaskStore()
    )
}
