import SwiftUI

// 並び替えオプションの列挙型
enum SortOption: String, CaseIterable {
    case manual = "手動"
    case priority = "優先度順"
    case dueDate = "期限順"
    case category = "カテゴリ順"
    case createdAt = "作成日順"
    case title = "タイトル順"
    
    var icon: String {
        switch self {
        case .manual: return "hand.draw"
        case .priority: return "exclamationmark.triangle"
        case .dueDate: return "calendar"
        case .category: return "folder"
        case .createdAt: return "clock"
        case .title: return "textformat"
        }
    }
}

// 表示モードの列挙型
enum DisplayMode: String, CaseIterable {
    case list = "リスト表示"
    case grouped = "カテゴリ別表示"
    
    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .grouped: return "folder.fill"
        }
    }
}

struct InboxView: View {
    @ObservedObject var taskStore: TaskStore
    @ObservedObject var guideManager: GuideModeManager
    @State private var showingAddSheet = false
    @State private var inlineAddText = ""
    @State private var showingSortMenu = false
    @State private var selectedSortOption: SortOption = .manual
    @State private var selectedDisplayMode: DisplayMode = .list
    @State private var hideCompletedTasks: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ガイドモードのプログレスバー
                if guideManager.shouldShowGuide {
                    GuideProgressBar(guideManager: guideManager)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                // コンシェルジュカード
                if guideManager.shouldShowGuide {
                    conciergeCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                
                if taskStore.inboxTasks.isEmpty && taskStore.doneTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
                
                // Inline add bar
                VStack(spacing: 0) {
                    Divider()
                        .background(TaskPlusTheme.colors.surface)
                    
                    InlineAddBar(text: $inlineAddText) { text in
                        print("DEBUG: InlineAddBar onAdd called with text: '\(text)'")
                        let task = TaskItem(title: text, notificationEnabled: true, notificationTime: nil)
                        print("DEBUG: TaskItem created with id: \(task.id)")
                        taskStore.addTask(task)
                        print("DEBUG: addTask completed")
                        // タスク追加後、ガイドの次のステップに進む
                        if guideManager.shouldShowGuide {
                            guideManager.nextStep()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(TaskPlusTheme.colors.bg)
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: taskStore.inboxTasks.count) { _ in
                // タスク数が変更された時にUIを更新
                print("DEBUG: inboxTasks count changed to \(taskStore.inboxTasks.count)")
            }
            .onChange(of: taskStore.doneTasks.count) { _ in
                // 完了タスク数が変更された時にもUIを更新
                print("DEBUG: doneTasks count changed to \(taskStore.doneTasks.count)")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Apple公式推奨のPickerを使用して並び替えオプションを表示
                        Picker("並び替え", selection: $selectedSortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Label(option.rawValue, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.menu) // メニュー形式で表示
                        .onChange(of: selectedSortOption) { _ in
                            sortTasks()
                        }
                        
                        Divider()
                        
                        // 表示モードの選択
                        Picker("表示", selection: $selectedDisplayMode) {
                            ForEach(DisplayMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Divider()
                        
                        // 実行済みタスクの表示/非表示切り替え
                        Button(action: {
                            hideCompletedTasks.toggle()
                        }) {
                            Label(
                                hideCompletedTasks ? "実行済みを表示" : "実行済みを非表示",
                                systemImage: hideCompletedTasks ? "eye" : "eye.slash"
                            )
                        }
                        
                        Divider()
                        
                        Button("新しいタスクを追加") {
                            showingAddSheet = true
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTaskSheet(taskStore: taskStore)
            }
        }
    }
    
    // タスクの並び替え処理
    private func sortTasks() {
        switch selectedSortOption {
        case .manual:
            // 手動並び替えは既存のsortOrderを使用
            break
        case .priority:
            taskStore.inboxTasks.sort { (task1: TaskItem, task2: TaskItem) in
                let priority1 = task1.priority.rawValue
                let priority2 = task2.priority.rawValue
                if priority1 == priority2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return priority1 > priority2 // 高優先度を上に
            }
        case .dueDate:
            taskStore.inboxTasks.sort { (task1: TaskItem, task2: TaskItem) in
                let date1 = task1.due ?? Date.distantFuture
                let date2 = task2.due ?? Date.distantFuture
                if date1 == date2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return date1 < date2 // 早い期限を上に
            }
        case .category:
            taskStore.inboxTasks.sort { (task1: TaskItem, task2: TaskItem) in
                let category1 = getCategoryName(for: task1.categoryId) ?? ""
                let category2 = getCategoryName(for: task2.categoryId) ?? ""
                if category1 == category2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return category1 < category2 // アルファベット順
            }
        case .createdAt:
            taskStore.inboxTasks.sort { (task1: TaskItem, task2: TaskItem) in
                return task1.createdAt > task2.createdAt // 新しいものを上に
            }
        case .title:
            taskStore.inboxTasks.sort { (task1: TaskItem, task2: TaskItem) in
                return task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        }
        
        // 並び替え後にsortOrderを更新
        for (index, task) in taskStore.inboxTasks.enumerated() {
            var updatedTask = task
            updatedTask.sortOrder = index
            // TaskStoreの更新メソッドを呼び出す必要があります
        }
    }
    
    // カテゴリ名を取得するヘルパーメソッド
    private func getCategoryName(for categoryId: UUID?) -> String? {
        guard let categoryId = categoryId else { return nil }
        return taskStore.categories.first { $0.id == categoryId }?.name
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                .shadow(color: TaskPlusTheme.colors.neonAccent.opacity(0.6), radius: 16)
            
            VStack(spacing: 8) {
                Text("全部ここに入れてOK")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                Text("まずは頭の中を空っぽにしよう")
                    .font(.subheadline)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var taskListView: some View {
        Group {
            if selectedDisplayMode == .grouped {
                groupedTaskListView
            } else {
                listTaskListView
            }
        }
    }
    
    // リスト表示のタスクリスト
    private var listTaskListView: some View {
        // Listを強制的に再構築するための条件
        let shouldRebuildList = taskStore.inboxTasks.count + taskStore.doneTasks.count
        
        return Group {
            if shouldRebuildList > 0 {
                List {
                    // アクティブなタスク（InboxとToday）
                    Section {
                        let activeTasks = sortedTasks.filter { $0.status != .done }
                        let _ = print("DEBUG: ForEach activeTasks count: \(activeTasks.count)")
                        let _ = print("DEBUG: ForEach activeTasks titles: \(activeTasks.map { $0.title })")
                        let _ = print("DEBUG: ForEach activeTasks IDs: \(activeTasks.map { $0.id })")
                        let _ = print("DEBUG: ForEach activeTasks statuses: \(activeTasks.map { $0.status })")
                        
                        ForEach(activeTasks, id: \.id) { task in
                            let _ = print("DEBUG: ForEach iteration for task: '\(task.title)' with ID: \(task.id)")
                            let _ = print("DEBUG: Rendering task: \(task.title) with status: \(task.status)")
                            TaskRow(
                                task: task,
                                isInbox: true,
                                onComplete: { taskStore.completeTask(task) },
                                onDelete: { taskStore.deleteTask(task) },
                                onMoveToToday: { taskStore.moveToToday(task) },
                                taskStore: taskStore
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .id("\(task.id)_\(task.status)")
                        }
                        .onMove(perform: selectedSortOption == .manual ? { source, destination in
                            taskStore.reorderTasks(in: .inbox, from: source, to: destination)
                        } : nil)
                    } header: {
                        HStack {
                            Text("アクティブなタスク")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(sortedTasks.filter { $0.status != .done }.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    
                    // 完了済みタスク
                    if !hideCompletedTasks && !taskStore.doneTasks.isEmpty {
                        Section {
                            ForEach(taskStore.doneTasks.filter { $0.status == .done }, id: \.id) { task in
                                TaskRow(
                                    task: task,
                                    isInbox: true,
                                    onComplete: { taskStore.restoreTask(task) }, // 完了済みタスクを再開
                                    onDelete: { taskStore.deleteTask(task) },
                                    onMoveToToday: { },
                                    taskStore: taskStore
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .id("\(task.id)_\(task.status)")
                            }
                        } header: {
                            HStack {
                                Text("完了済み")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                
                                Spacer()
                                
                                Text("\(taskStore.doneTasks.filter { $0.status == .done }.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(TaskPlusTheme.colors.bg)
                // リスト更新時のアニメーション制御
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: taskStore.inboxTasks.count)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: taskStore.doneTasks.count)
                // Listの強制更新のためのID
                .id("\(taskStore.inboxTasks.count)_\(taskStore.doneTasks.count)_\(sortedTasks.count)")
            } else {
                // 空の状態
                Text("タスクがありません")
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
            }
        }
    }
    
    // フィルタリングされたタスクリスト（InboxViewではinboxTasksと完了済みタスクを表示）
    private var filteredTasks: [TaskItem] {
        // 直接的なデータ参照で遅延を防止
        let inboxTasks = taskStore.inboxTasks
        let doneTasks = taskStore.doneTasks
        let allTasks = inboxTasks + doneTasks
        let result = hideCompletedTasks ? allTasks.filter { $0.status != .done } : allTasks
        print("DEBUG: filteredTasks calculated. inboxTasks: \(inboxTasks.count), doneTasks: \(doneTasks.count), result: \(result.count)")
        return result
    }
    
    // 並び替え済みのタスクリスト（シンプル化）
    private var sortedTasks: [TaskItem] {
        // 直接的なデータ参照で遅延を防止
        let inboxTasks = taskStore.inboxTasks
        let doneTasks = taskStore.doneTasks
        let allTasks = inboxTasks + doneTasks
        let tasks = hideCompletedTasks ? allTasks.filter { $0.status != .done } : allTasks
        
        let result: [TaskItem]
        
        switch selectedSortOption {
        case .manual:
            result = tasks.sorted { $0.sortOrder < $1.sortOrder }
        case .priority:
            result = tasks.sorted { 
                if $0.priority.rawValue == $1.priority.rawValue {
                    return $0.sortOrder < $1.sortOrder
                }
                return $0.priority.rawValue > $1.priority.rawValue
            }
        case .dueDate:
            result = tasks.sorted { 
                let date1 = $0.due ?? Date.distantFuture
                let date2 = $1.due ?? Date.distantFuture
                if date1 == date2 {
                    return $0.sortOrder < $1.sortOrder
                }
                return date1 < date2
            }
        case .category:
            result = tasks.sorted { 
                let category1 = getCategoryName(for: $0.categoryId) ?? ""
                let category2 = getCategoryName(for: $1.categoryId) ?? ""
                if category1 == category2 {
                    return $0.sortOrder < $1.sortOrder
                }
                return category1 < category2
            }
        case .createdAt:
            result = tasks.sorted { $0.createdAt > $1.createdAt }
        case .title:
            result = tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        
        print("DEBUG: sortedTasks calculated. input: \(tasks.count), output: \(result.count)")
        print("DEBUG: inboxTasks count: \(inboxTasks.count), doneTasks count: \(doneTasks.count)")
        print("DEBUG: active tasks (status != .done): \(tasks.filter { $0.status != .done }.count)")
        print("DEBUG: active task titles: \(tasks.filter { $0.status != .done }.map { $0.title })")
        print("DEBUG: all tasks with status: \(tasks.map { "\($0.title): \($0.status)" })")
        print("DEBUG: result tasks with status: \(result.map { "\($0.title): \($0.status)" })")
        return result
    }
    
    // カテゴリ別表示のタスクリスト
    private var groupedTaskListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedTasks.keys.sorted(), id: \.self) { categoryName in
                    if let tasks = groupedTasks[categoryName] {
                        VStack(alignment: .leading, spacing: 12) {
                            // カテゴリヘッダー
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(TaskPlusTheme.colors.neonAccent)
                                    .font(.title3)
                                
                                Text(categoryName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(tasks.count)件")
                                    .font(.caption)
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(TaskPlusTheme.colors.surface)
                                    )
                            }
                            .padding(.horizontal, 16)
                            
                            // カテゴリ内のタスク
                            VStack(spacing: 8) {
                                ForEach(tasks) { task in
                                    TaskRow(
                                        task: task,
                                        isInbox: true,
                                        onComplete: { 
                                            if task.status == .done {
                                                taskStore.restoreTask(task) // 完了済みタスクを再開
                                            } else {
                                                taskStore.completeTask(task) // アクティブなタスクを完了
                                            }
                                        },
                                        onDelete: { taskStore.deleteTask(task) },
                                        onMoveToToday: { 
                                            if task.status != .done {
                                                taskStore.moveToToday(task)
                                            }
                                        },
                                        taskStore: taskStore
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(TaskPlusTheme.colors.surface.opacity(0.3))
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(TaskPlusTheme.colors.bg)
    }
    
    // カテゴリ別にグループ化されたタスク
    private var groupedTasks: [String: [TaskItem]] {
        let sorted = sortedTasks
        var grouped: [String: [TaskItem]] = [:]
        
        for task in sorted {
            let categoryName = getCategoryName(for: task.categoryId) ?? "未分類"
            if grouped[categoryName] == nil {
                grouped[categoryName] = []
            }
            grouped[categoryName]?.append(task)
        }
        
        return grouped
    }
    
    // MARK: - Animation Helper Functions
    
    // Apple公式の方法でアニメーションを制御
    // TaskStoreのwithAnimationを使用して状態変更時にアニメーションを制御
    
    // コンシェルジュカード
    private var conciergeCard: some View {
        if taskStore.inboxTasks.isEmpty && taskStore.doneTasks.isEmpty {
            return ConciergeCard(
                message: "頭の中を整理してみましょう",
                icon: "plus.circle",
                actionText: "新しいタスクを追加して、まずは書き出してみてください"
            ) {
                // タスク追加シートを表示
                showingAddSheet = true
            }
        } else if taskStore.todayTasks.isEmpty {
            return ConciergeCard(
                message: "今日やることを選んでみませんか？",
                icon: "arrow.right.circle",
                actionText: "Inboxのタスクを右にスワイプして、今日やるものに移動させてください"
            ) {
                // ガイドの次のステップに進む
                guideManager.nextStep()
            }
        } else {
            return ConciergeCard(
                message: "素晴らしい！今日やることが決まりました",
                icon: "checkmark.circle.fill",
                actionText: "次のステップに進みましょう"
            ) {
                // ガイドの次のステップに進む
                guideManager.nextStep()
            }
        }
    }
}

#Preview {
    InboxView(
        taskStore: TaskStore(),
        guideManager: GuideModeManager()
    )
        .preferredColorScheme(.dark)
}
