import SwiftUI

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskStore: TaskStore
    
    @State private var title = ""
    @State private var notes = ""
    @State private var estimatedTime = 30 // 分単位
    @State private var priority: TaskPriority = .normal
    @State private var selectedCategoryId: UUID?
    @State private var dueDate: Date?
    @State private var notificationEnabled = true
    @State private var notificationTime: Date?
    @State private var showingDueDatePicker = false
    @State private var showingNotificationTimePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                dueDateAndNotificationSection
                detailSettingsSection
                categorySection
            }
            .navigationTitle("新しいタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addTask()
                    }
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("基本情報") {
            TextField("タスク名", text: $title)
                .textFieldStyle(CustomTextFieldStyle())
            
            TextField("メモ", text: $notes, axis: .vertical)
                .textFieldStyle(CustomTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var dueDateAndNotificationSection: some View {
        Section("期限と通知") {
            dueDateRow
            notificationToggle
            if notificationEnabled {
                notificationTimeRow
            }
        }
    }
    
    private var dueDateRow: some View {
        VStack {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                Text("期限")
                Spacer()
                if let dueDate = dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                } else {
                    Text("未設定")
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
            }
            .onTapGesture {
                showingDueDatePicker.toggle()
            }
            
            if showingDueDatePicker {
                DatePicker("期限", selection: Binding(
                    get: { dueDate ?? Date() },
                    set: { dueDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .colorScheme(.dark)
            }
        }
    }
    
    private var notificationToggle: some View {
        Toggle("通知を有効にする", isOn: $notificationEnabled)
            .tint(TaskPlusTheme.colors.neonPrimary)
    }
    
    private var notificationTimeRow: some View {
        VStack {
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(TaskPlusTheme.colors.neonAccent)
                Text("通知時刻")
                Spacer()
                if let notificationTime = notificationTime {
                    Text(notificationTime.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                } else {
                    Text("期限と同じ")
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
            }
            .onTapGesture {
                // 通知時刻を個別に設定
                if notificationTime == nil {
                    notificationTime = dueDate ?? Date()
                }
                showingNotificationTimePicker.toggle()
            }
            
            if showingNotificationTimePicker && notificationTime != nil {
                DatePicker("通知時刻", selection: Binding(
                    get: { notificationTime ?? Date() },
                    set: { notificationTime = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .colorScheme(.dark)
            }
        }
    }
    
    private var detailSettingsSection: some View {
        Section("詳細設定") {
            priorityRow
            estimatedTimeRow
            CustomTimeSlider(value: $estimatedTime)
        }
    }
    
    private var priorityRow: some View {
        HStack {
            Image(systemName: "flag")
                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
            Text("優先度")
            Spacer()
                                Picker("", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priorityOption in
                            PriorityButton(priority: priorityOption, isSelected: self.priority == priorityOption) {
                                self.priority = priorityOption
                            }
                        }
                    }
            .pickerStyle(.segmented)
        }
    }
    
    private var estimatedTimeRow: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(TaskPlusTheme.colors.neonAccent)
            Text("推定時間")
            Spacer()
            Text("\(estimatedTime)分")
                .foregroundColor(TaskPlusTheme.colors.textSecondary)
        }
    }
    
    private var categorySection: some View {
        Section("カテゴリ") {
            ForEach(taskStore.categories) { category in
                CategorySelectionButton(
                    category: category,
                    isSelected: selectedCategoryId == category.id
                ) {
                    selectedCategoryId = selectedCategoryId == category.id ? nil : category.id
                }
            }
        }
    }
    
    private func addTask() {
        let task = TaskItem(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            due: dueDate,
            priority: priority,
            context: .none,
            categoryId: selectedCategoryId,
            sortOrder: taskStore.inboxTasks.count,
            notificationEnabled: notificationEnabled,
            notificationTime: notificationTime
        )
        
        taskStore.addTask(task)
        dismiss()
    }
}

#Preview {
    AddTaskSheet(taskStore: TaskStore())
}
