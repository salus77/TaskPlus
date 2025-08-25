import Foundation
import SwiftUI
import UserNotifications

@MainActor
class TaskStore: ObservableObject {
    static let shared = TaskStore()
    @Published var inboxTasks: [TaskItem] = []
    @Published var todayTasks: [TaskItem] = []
    @Published var doneTasks: [TaskItem] = []
    @Published var categories: [Category] = []
    
    // Generic data structure for external integration
    private var taskPlusData: TaskPlusData
    
    // Notification manager
    private let notificationManager = NotificationManager.shared
    
    init() {
        // デフォルトカテゴリを追加
        categories = [
            Category(name: "仕事", icon: .briefcase, color: .blue),
            Category(name: "プライベート", icon: .heart, color: .pink),
            Category(name: "学習", icon: .book, color: .green),
            Category(name: "家事", icon: .house, color: .orange)
        ]
        
        // Initialize generic data structure with empty data first
        taskPlusData = TaskPlusData()
        
        loadSampleData()
        updateGenericData()
        
        // 通知カテゴリを設定
        notificationManager.setupNotificationCategories()
    }
    
    // MARK: - Generic Data Management
    private func updateGenericData() {
        let allTasks = inboxTasks + todayTasks + doneTasks
        taskPlusData.tasks = allTasks.map { $0.toTaskData() }
        taskPlusData.categories = categories.map { $0.toCategoryData() }
        taskPlusData.lastModified = Date()
    }
    
    // Export data as JSON
    func exportData() -> Data? {
        updateGenericData()
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(taskPlusData)
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    // Import data from JSON
    func importData(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedData = try decoder.decode(TaskPlusData.self, from: data)
            
            // Convert back to legacy models for backward compatibility
            categories = importedData.categories.compactMap { categoryData in
                guard let icon = CategoryIcon(rawValue: categoryData.icon),
                      let color = CategoryColor(rawValue: categoryData.color) else { return nil }
                
                return Category(
                    name: categoryData.name,
                    icon: icon,
                    color: color
                )
            }
            
            // Convert tasks back to legacy models
            inboxTasks = importedData.tasks
                .filter { $0.status == "inbox" }
                .compactMap { taskData in
                    guard let priority = TaskPriority(rawValue: taskData.priority),
                          let context = TaskContext(rawValue: taskData.context) else { return nil }
                    
                    return TaskItem(
                        title: taskData.title,
                        notes: taskData.notes,
                        due: taskData.due,
                        priority: priority,
                        context: context,
                        categoryId: UUID(uuidString: taskData.categoryId ?? "")
                    )
                }
            
            todayTasks = importedData.tasks
                .filter { $0.status == "today" }
                .compactMap { taskData in
                    guard let priority = TaskPriority(rawValue: taskData.priority),
                          let context = TaskContext(rawValue: taskData.context) else { return nil }
                    
                    return TaskItem(
                        title: taskData.title,
                        notes: taskData.notes,
                        due: taskData.due,
                        priority: priority,
                        context: context,
                        categoryId: UUID(uuidString: taskData.categoryId ?? "")
                    )
                }
            
            doneTasks = importedData.tasks
                .filter { $0.status == "done" }
                .compactMap { taskData in
                    guard let priority = TaskPriority(rawValue: taskData.priority),
                          let context = TaskContext(rawValue: taskData.context) else { return nil }
                    
                    return TaskItem(
                        title: taskData.title,
                        notes: taskData.notes,
                        due: taskData.due,
                        priority: priority,
                        context: context,
                        categoryId: UUID(uuidString: taskData.categoryId ?? "")
                    )
                }
            
            updateGenericData()
            return true
        } catch {
            print("Import error: \(error)")
            return false
        }
    }
    
    // MARK: - FocusPlus Integration Methods
    func addFocusSession(to taskId: UUID, session: FocusSession) {
        if let index = inboxTasks.firstIndex(where: { $0.id == taskId }) {
            // Convert to generic data, add session, then convert back
            var taskData = inboxTasks[index].toTaskData()
            taskData.focusSessions.append(session)
            taskData.updatedAt = Date()
            
            // Update the generic data
            if let taskIndex = taskPlusData.tasks.firstIndex(where: { $0.id == taskId.uuidString }) {
                taskPlusData.tasks[taskIndex] = taskData
            }
        } else if let index = todayTasks.firstIndex(where: { $0.id == taskId }) {
            var taskData = todayTasks[index].toTaskData()
            taskData.focusSessions.append(session)
            taskData.updatedAt = Date()
            
            if let taskIndex = taskPlusData.tasks.firstIndex(where: { $0.id == taskId.uuidString }) {
                taskPlusData.tasks[taskIndex] = taskData
            }
        }
        
        updateGenericData()
    }
    
    func getTaskAnalytics(for taskId: UUID) -> [String: Any] {
        guard let taskData = taskPlusData.tasks.first(where: { $0.id == taskId.uuidString }) else {
            return [:]
        }
        
        let totalFocusTime = taskData.focusSessions.reduce(0) { $0 + ($1.duration ?? 0) }
        let averageProductivity = taskData.focusSessions.compactMap { $0.productivity }.reduce(0, +) / max(taskData.focusSessions.count, 1)
        let totalInterruptions = taskData.focusSessions.reduce(0) { $0 + $1.interruptions }
        
        return [
            "totalFocusTime": totalFocusTime,
            "averageProductivity": averageProductivity,
            "totalInterruptions": totalInterruptions,
            "focusSessionsCount": taskData.focusSessions.count,
            "estimatedTime": taskData.estimatedTime ?? 0,
            "actualTime": taskData.actualTime ?? 0
        ]
    }
    
    // MARK: - Task Management
    func addTask(_ task: TaskItem) {
        var newTask = task
        newTask.sortOrder = inboxTasks.count // 最後の順序を設定
        inboxTasks.append(newTask)
        updateGenericData()
        
        // 通知をスケジュール
        if newTask.notificationEnabled {
            scheduleNotificationForTask(newTask)
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Management
    private func scheduleNotificationForTask(_ task: TaskItem) {
        // 期限がある場合は期限前リマインダー
        if let dueDate = task.due {
            notificationManager.scheduleTaskNotification(for: task)
        }
        
        // 個別の通知時刻が設定されている場合
        if let notificationTime = task.notificationTime {
            scheduleCustomNotification(for: task, at: notificationTime)
        }
    }
    
    private func scheduleCustomNotification(for task: TaskItem, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "タスクのリマインダー"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TASK_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "custom_task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule custom notification: \(error)")
            }
        }
    }
    
    func updateTaskNotification(_ task: TaskItem, notificationEnabled: Bool, notificationTime: Date?) {
        var updatedTask = task
        updatedTask.notificationEnabled = notificationEnabled
        updatedTask.notificationTime = notificationTime
        updatedTask.updatedAt = Date()
        
        // 既存の通知を削除
        notificationManager.removeTaskNotification(for: task)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["custom_task_\(task.id.uuidString)"]
        )
        
        // 新しい通知をスケジュール
        if notificationEnabled {
            scheduleNotificationForTask(updatedTask)
        }
        
        // タスクを更新
        updateTask(updatedTask)
    }
    
    func updateTask(_ task: TaskItem) {
        // Inboxタスクを更新
        if let index = inboxTasks.firstIndex(where: { $0.id == task.id }) {
            inboxTasks[index] = task
        }
        
        // Todayタスクを更新
        if let index = todayTasks.firstIndex(where: { $0.id == task.id }) {
            todayTasks[index] = task
        }
        
        // Doneタスクを更新
        if let index = doneTasks.firstIndex(where: { $0.id == task.id }) {
            doneTasks[index] = task
        }
        
        updateGenericData()
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    func moveToToday(_ task: TaskItem) {
        guard let index = inboxTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = task
        updatedTask.status = .today
        updatedTask.updatedAt = Date()
        
        inboxTasks.remove(at: index)
        todayTasks.append(updatedTask)
        updateGenericData()
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func completeTask(_ task: TaskItem) {
        var updatedTask = task
        updatedTask.status = .done
        updatedTask.updatedAt = Date()
        
        if let index = inboxTasks.firstIndex(where: { $0.id == task.id }) {
            inboxTasks.remove(at: index)
        } else if let index = todayTasks.firstIndex(where: { $0.id == task.id }) {
            todayTasks.remove(at: index)
        }
        
        doneTasks.append(updatedTask)
        updateGenericData()
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func deleteTask(_ task: TaskItem) {
        if let index = inboxTasks.firstIndex(where: { $0.id == task.id }) {
            inboxTasks.remove(at: index)
        } else if let index = todayTasks.firstIndex(where: { $0.id == task.id }) {
            todayTasks.remove(at: index)
        }
        
        // 関連する通知を削除
        notificationManager.removeTaskNotification(for: task)
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["custom_task_\(task.id.uuidString)"]
        )
        
        updateGenericData()
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func snoozeOneDay(_ task: TaskItem) {
        guard let index = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = task
        updatedTask.due = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        updatedTask.updatedAt = Date()
        
        todayTasks[index] = updatedTask
        updateGenericData()
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func reorderTasks(in section: TaskStatus, from source: IndexSet, to destination: Int) {
        switch section {
        case .inbox:
            inboxTasks.move(fromOffsets: source, toOffset: destination)
            // 並び替え後にsortOrderを更新
            for (index, task) in inboxTasks.enumerated() {
                var updatedTask = task
                updatedTask.sortOrder = index
                inboxTasks[index] = updatedTask
            }
        case .today:
            todayTasks.move(fromOffsets: source, toOffset: destination)
            // 並び替え後にsortOrderを更新
            for (index, task) in todayTasks.enumerated() {
                var updatedTask = task
                updatedTask.sortOrder = index
                todayTasks[index] = updatedTask
            }
        case .done:
            doneTasks.move(fromOffsets: source, toOffset: destination)
            // 並び替え後にsortOrderを更新
            for (index, task) in doneTasks.enumerated() {
                var updatedTask = task
                updatedTask.sortOrder = index
                doneTasks[index] = updatedTask
            }
        case .deleted:
            break
        }
        // 並び替え後はupdateGenericData()を呼び出さない（順序が保持される）
    }
    
    // MARK: - Category Management
    func addCategory(_ category: Category) {
        categories.append(category)
        updateGenericData()
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            updateGenericData()
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
        }
    }
    
    func deleteCategory(_ category: Category) {
        categories.removeAll { $0.id == category.id }
        // そのカテゴリを使用しているタスクのカテゴリIDをクリア
        inboxTasks = inboxTasks.map { task in
            var updatedTask = task
            if updatedTask.categoryId == category.id { updatedTask.categoryId = nil }
            return updatedTask
        }
        todayTasks = todayTasks.map { task in
            var updatedTask = task
            if updatedTask.categoryId == category.id { updatedTask.categoryId = nil }
            return updatedTask
        }
        updateGenericData()
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Sample Data
    private func loadSampleData() {
        let sampleTasks = [
            TaskItem(title: "提案資料をまとめる", priority: .high, context: .work, categoryId: categories.first?.id, sortOrder: 0, notificationEnabled: true, notificationTime: nil),
            TaskItem(title: "牛乳を買う", context: .errand, categoryId: categories[2].id, sortOrder: 1, notificationEnabled: true, notificationTime: nil),
            TaskItem(title: "田中さんに電話", context: .call, categoryId: categories.first?.id, sortOrder: 2, notificationEnabled: false, notificationTime: nil)
        ]
        
        inboxTasks = sampleTasks
    }
    
    // MARK: - Computed Properties
    var todayProgress: Double {
        guard !todayTasks.isEmpty else { return 0.0 }
        let completed = doneTasks.filter { $0.status == .done }.count
        return Double(completed) / Double(todayTasks.count + completed)
    }
    
    var todayCompletedCount: Int {
        doneTasks.filter { $0.status == .done }.count
    }
    
    var todayTotalCount: Int {
        todayTasks.count + todayCompletedCount
    }
}
