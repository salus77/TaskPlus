import SwiftUI

struct TodayView: View {
    @ObservedObject var taskStore: TaskStore
    @State private var selectedSortOption: SortOption = .manual
    @State private var selectedSortDirection: SortDirection = .descending
    @State private var hideCompletedTasks: Bool = false
    @State private var quickTaskText: String = ""
    @State private var selectedFilterTags: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                
                if taskStore.todayTasks.isEmpty && taskStore.todayCompletedCount == 0 {
                    emptyStateView
                } else {
                    taskListView
                }
                
                // クイックタスク追加バー（画面下部）
                VStack(spacing: 0) {
                    Divider()
                        .background(TaskPlusTheme.colors.surface)
                    
                    InlineAddBar(text: $quickTaskText) { text in
                        addQuickTask()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(TaskPlusTheme.colors.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Today")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        
                        Spacer()
                        
                        Menu {
                            // 表示順序の選択
                            Menu("表示順序") {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        selectedSortOption = option
                                        sortTasks()
                                    }) {
                                        HStack {
                                            if selectedSortOption == option {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                            }
                                            Label(option.rawValue, systemImage: option.icon)
                                        }
                                    }
                                }
                            }
                            
                            // 並び替え方向の選択（優先度順の場合のみ表示）
                            if selectedSortOption == .priority {
                                Menu("並び替え方向") {
                                    Button(action: {
                                        selectedSortDirection = .descending
                                        sortTasks()
                                    }) {
                                        HStack {
                                            if selectedSortDirection == .descending {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                            }
                                            Label("高優先順位が先", systemImage: "arrow.up")
                                        }
                                    }
                                    
                                    Button(action: {
                                        selectedSortDirection = .ascending
                                        sortTasks()
                                    }) {
                                        HStack {
                                            if selectedSortDirection == .ascending {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                            }
                                            Label("低優先順位が先", systemImage: "arrow.down")
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // タグフィルタリング
                            Menu("タグで抽出") {
                                if taskStore.tags.isEmpty {
                                    Text("利用可能なタグがありません")
                                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                        .font(.caption)
                                } else {
                                    ForEach(taskStore.tags, id: \.self) { tag in
                                        Button(action: {
                                            if selectedFilterTags.contains(tag) {
                                                selectedFilterTags.remove(tag)
                                            } else {
                                                selectedFilterTags.insert(tag)
                                            }
                                        }) {
                                            HStack {
                                                if selectedFilterTags.contains(tag) {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                                } else {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                                }
                                                Label(tag, systemImage: "tag")
                                            }
                                        }
                                    }
                                    
                                    if !selectedFilterTags.isEmpty {
                                        Divider()
                                        
                                        Button(action: {
                                            selectedFilterTags.removeAll()
                                        }) {
                                            Label("フィルターをクリア", systemImage: "xmark.circle")
                                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                        }
                                    }
                                }
                            }
                            
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
                            

                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                .font(.body)
                        }
                    }
                }
            }

        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                .shadow(color: TaskPlusTheme.colors.neonPrimary.opacity(0.6), radius: 16)
            
            VStack(spacing: 8) {
                Text("今日のタスクはありません")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                Text("Inboxからタスクを整理して今日やることを決めよう")
                    .font(.subheadline)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // フィルタリングされたタスクリスト（TodayViewでは今日のタスクのみを表示）
    private var filteredTasks: [TaskItem] {
        let todayTasks = taskStore.todayTasks
        
        if selectedFilterTags.isEmpty {
            return todayTasks
        } else {
            return todayTasks.filter { task in
                !Set(task.tags).isDisjoint(with: selectedFilterTags)
            }
        }
    }
    
    // 並び替え済みのタスクリスト
    private var sortedTasks: [TaskItem] {
        let todayTasks = filteredTasks
        switch selectedSortOption {
        case .manual:
            return todayTasks.sorted { (task1: TaskItem, task2: TaskItem) in
                task1.sortOrder < task2.sortOrder
            }
        case .priority:
            return todayTasks.sorted { (task1: TaskItem, task2: TaskItem) in
                let priority1 = task1.priority.priorityValue
                let priority2 = task2.priority.priorityValue
                if priority1 == priority2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return priority1 > priority2
            }
        case .dueDate:
            return todayTasks.sorted { (task1: TaskItem, task2: TaskItem) in
                let date1 = task1.due ?? Date.distantFuture
                let date2 = task2.due ?? Date.distantFuture
                if date1 == date2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return date1 < date2
            }
        case .category:
            return todayTasks.sorted { (task1: TaskItem, task2: TaskItem) in
                let category1 = task1.categoryId?.uuidString ?? ""
                let category2 = task2.categoryId?.uuidString ?? ""
                if category1 == category2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return category1 < category2
            }
        case .createdAt:
            return todayTasks.sorted { (task1: TaskItem, task2: TaskItem) in
                task1.createdAt < task2.createdAt
            }
        case .title:
            return todayTasks.sorted { (task1: TaskItem, task2: TaskItem) in
                task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        }
    }
    
    private var taskListView: some View {
        List {
            // Progress header
            Section {
                ProgressHeader(
                    completedCount: taskStore.todayCompletedCount,
                    totalCount: taskStore.todayTasks.count + taskStore.todayCompletedCount
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            
            // Today tasks
            if !sortedTasks.isEmpty {
                Section {
                    ForEach(sortedTasks) { task in
                        TaskRow(
                            task: task,
                            isInbox: true, // InboxViewと同じデザインにする
                            isTodayView: true, // TodayViewでのスワイプアクション制御
                            onComplete: { taskStore.completeTask(task) },
                            onDelete: { taskStore.deleteTask(task) },
                            onMoveToToday: { },
                            taskStore: taskStore
                        )

                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))

                    }
                    .onMove(perform: selectedSortOption == .manual ? { source, destination in
                        taskStore.reorderTasks(in: .today, from: source, to: destination)
                    } : nil)
                } header: {
                    HStack {
                        Text("今日のタスク")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(taskStore.todayTasks.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            
            // Completed tasks (Todayで完了したタスクのみ)
            if !hideCompletedTasks && !taskStore.todayDoneTasks.isEmpty {
                Section {
                    ForEach(taskStore.todayDoneTasks, id: \.id) { task in
                        TaskRow(
                            task: task,
                            isInbox: true, // InboxViewと同じデザインにする
                            isTodayView: true, // TodayViewでのスワイプアクション制御
                            onComplete: { taskStore.restoreTask(task) }, // 完了済みタスクを再開
                            onDelete: { taskStore.deleteTask(task) },
                            onMoveToToday: { },
                            taskStore: taskStore
                        )
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button(action: {
                                taskStore.restoreTask(task)
                            }) {
                                Label("再開", systemImage: "arrow.clockwise")
                            }
                            .tint(TaskPlusTheme.colors.neonPrimary)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        // Apple公式の方法でアニメーションを制御するため、transitionは削除
                    }
                } header: {
                    HStack {
                        Text("完了済み")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        
                        Spacer()
                        
                                                        Text("\(taskStore.todayDoneTasks.count)")
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: taskStore.todayTasks.count)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: taskStore.todayDoneTasks.count)
    }
    
    // クイックタスク追加処理
    private func addQuickTask() {
        let trimmedText = quickTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // 新しいタスクを作成
        let task = TaskItem(
            title: trimmedText,
            sortOrder: taskStore.todayTasks.count,
            notificationEnabled: true,
            notificationTime: nil
        )
        
        // タスクをTodayに追加
        taskStore.addTask(task)
        
        // タスクをTodayに移動
        if let addedTask = taskStore.inboxTasks.last {
            var updatedTask = addedTask
            updatedTask.status = .today
            updatedTask.updatedAt = Date()
            
            // inboxTasksから削除してtodayTasksに追加
            if let index = taskStore.inboxTasks.firstIndex(where: { $0.id == addedTask.id }) {
                taskStore.inboxTasks.remove(at: index)
            }
            taskStore.todayTasks.append(updatedTask)
        }
        
        // 入力フィールドをクリア
        quickTaskText = ""
    }
    
    // タスクの並び替え処理
    private func sortTasks() {
        switch selectedSortOption {
        case .manual:
            // 手動並び替えは既存のsortOrderを使用
            break
        case .priority:
            taskStore.todayTasks.sort { (task1: TaskItem, task2: TaskItem) in
                let priority1 = task1.priority.priorityValue
                let priority2 = task2.priority.priorityValue
                if priority1 == priority2 {
                    return task1.sortOrder < task2.sortOrder
                }
                if selectedSortDirection == .descending {
                    return priority1 > priority2 // 高優先度を上に
                } else {
                    return priority1 < priority2 // 低優先度を上に
                }
            }
        case .dueDate:
            taskStore.todayTasks.sort { (task1: TaskItem, task2: TaskItem) in
                let date1 = task1.due ?? Date.distantFuture
                let date2 = task2.due ?? Date.distantFuture
                if date1 == date2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return date1 < date2 // 早い期限を上に
            }
        case .category:
            taskStore.todayTasks.sort { (task1: TaskItem, task2: TaskItem) in
                let category1 = getCategoryName(for: task1.categoryId) ?? ""
                let category2 = getCategoryName(for: task2.categoryId) ?? ""
                if category1 == category2 {
                    return task1.sortOrder < task2.sortOrder
                }
                return category1 < category2 // アルファベット順
            }
        case .createdAt:
            taskStore.todayTasks.sort { (task1: TaskItem, task2: TaskItem) in
                return task1.createdAt > task2.createdAt // 新しいものを上に
            }
        case .title:
            taskStore.todayTasks.sort { (task1: TaskItem, task2: TaskItem) in
                return task1.title < task2.title // アルファベット順
            }
        }
    }
    
    // カテゴリ名を取得するヘルパー関数
    private func getCategoryName(for categoryId: UUID?) -> String? {
        guard let categoryId = categoryId else { return nil }
        return taskStore.categories.first { $0.id == categoryId }?.name
    }
}

#Preview {
    TodayView(taskStore: TaskStore())
        .preferredColorScheme(.dark)
}
