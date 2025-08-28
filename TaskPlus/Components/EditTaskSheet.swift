import SwiftUI

struct EditTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskStore: TaskStore
    let task: TaskItem
    
    @State private var title: String
    @State private var notes: String
    @State private var estimatedTime: Int // 分単位
    @State private var priority: TaskPriority
    @State private var selectedCategoryId: UUID?
    @State private var showingDeleteAlert = false
    @State private var dueDate: Date?
    @State private var notificationEnabled: Bool
    @State private var notificationTime: Date?
    @State private var showingNotificationTimePicker = false
    @State private var selectedTags: [String]
    @State private var showingEstimatedTimePicker = false
    @State private var repeatEnabled: Bool
    @State private var repeatType: RepeatType
    @State private var repeatInterval: Int
    @State private var repeatEndDate: Date?
    @State private var showingEndDatePicker = false
    
    init(task: TaskItem, taskStore: TaskStore) {
        self.task = task
        self.taskStore = taskStore
        self._title = State(initialValue: task.title)
        self._notes = State(initialValue: task.notes ?? "")
        self._estimatedTime = State(initialValue: 30) // デフォルト30分
        self._priority = State(initialValue: task.priority)

        self._selectedCategoryId = State(initialValue: task.categoryId)
        self._dueDate = State(initialValue: task.due)
        self._notificationEnabled = State(initialValue: task.notificationEnabled)
        self._notificationTime = State(initialValue: task.notificationTime)
        self._selectedTags = State(initialValue: task.tags)
        self._repeatEnabled = State(initialValue: task.repeatEnabled)
        self._repeatType = State(initialValue: task.repeatType)
        self._repeatInterval = State(initialValue: task.repeatInterval)
        self._repeatEndDate = State(initialValue: task.repeatEndDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                detailSettingsSection
                dueDateAndNotificationSection
                repeatSection
                categorySection
                tagSection
                deleteSection
            }
            .navigationTitle("タスクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
        .alert("タスクを削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("このタスクを削除しますか？この操作は取り消せません。")
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
            dueDatePicker
            notificationToggle
            notificationTimeRow
            notificationTimePicker
        }
    }
    
    private var dueDateRow: some View {
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
            showingNotificationTimePicker = true
        }
    }
    
    private var dueDatePicker: some View {
        Group {
            if showingNotificationTimePicker {
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
        Group {
            if notificationEnabled {
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
                }
            }
        }
    }
    
    private var notificationTimePicker: some View {
        Group {
            if notificationEnabled && notificationTime != nil {
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
        Section {
            VStack(spacing: 12) {
                priorityRow
                estimatedTimeRow
                estimatedTimePicker
            }
        } header: {
            Text("詳細設定")
                .font(.subheadline)
                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                .textCase(nil)
        }
    }
    
    private var priorityRow: some View {
        HStack {
            Image(systemName: "flag")
                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
            Text("優先度")
            Spacer()
            Picker("", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    PriorityButton(priority: priority, isSelected: self.priority == priority, action: {
                        self.priority = priority
                    })
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
            Button(action: {
                showingEstimatedTimePicker = true
            }) {
                HStack(spacing: 4) {
                    Text("\(estimatedTime)分")
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var estimatedTimePicker: some View {
        Group {
            if showingEstimatedTimePicker {
                HStack {
                    Spacer()
                    VStack {
                        HStack {
                            Text("推定時間を選択")
                                .font(.headline)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            Spacer()
                            Button("完了") {
                                showingEstimatedTimePicker = false
                            }
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        Picker("推定時間", selection: $estimatedTime) {
                            ForEach([15, 30, 45, 60, 90, 120, 180, 240, 300], id: \.self) { time in
                                Text("\(time)分").tag(time)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(TaskPlusTheme.colors.surface)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showingEstimatedTimePicker)
            }
        }
    }
    
    private var categorySection: some View {
        Section("カテゴリ") {
            if taskStore.categories.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(TaskPlusTheme.colors.warning)
                    Text("カテゴリがありません")
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(taskStore.categories) { category in
                        CategorySelectionButton(
                            category: category,
                            isSelected: selectedCategoryId == category.id
                        ) {
                            selectedCategoryId = selectedCategoryId == category.id ? nil : category.id
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var tagSection: some View {
        Section {
            TagSelectionView(
                taskStore: taskStore,
                selectedTags: $selectedTags
            )
        }
    }
    
    private var repeatSection: some View {
        Section("繰り返し設定") {
            Toggle("繰り返しを有効にする", isOn: $repeatEnabled)
                .tint(TaskPlusTheme.colors.neonPrimary)
            
            if repeatEnabled {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(TaskPlusTheme.colors.neonAccent)
                    Text("繰り返しの種類")
                    Spacer()
                    Picker("", selection: $repeatType) {
                        ForEach(RepeatType.allCases, id: \.self) { type in
                            if type != .none {
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                }
                
                if repeatType != .none {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        Text("間隔")
                        Spacer()
                        Picker("", selection: $repeatInterval) {
                            ForEach(1...10, id: \.self) { interval in
                                Text("\(interval)").tag(interval)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    }
                    
                    HStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        Text("終了日")
                        Spacer()
                        if let endDate = repeatEndDate {
                            Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        } else {
                            Text("なし")
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                    }
                    .onTapGesture {
                        showingEndDatePicker.toggle()
                    }
                    
                    if showingEndDatePicker {
                        VStack(spacing: 12) {
                            DatePicker("終了日", selection: Binding(
                                get: { repeatEndDate ?? Date() },
                                set: { repeatEndDate = $0 }
                            ), displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                            
                            HStack(spacing: 16) {
                                Button("設定") {
                                    showingEndDatePicker = false
                                }
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                
                                Button("クリア") {
                                    repeatEndDate = nil
                                    showingEndDatePicker = false
                                }
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(TaskPlusTheme.colors.danger)
                    Text("タスクを削除")
                        .foregroundColor(TaskPlusTheme.colors.danger)
                }
            }
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.notes = notes.isEmpty ? nil : notes
        updatedTask.due = dueDate
        updatedTask.priority = priority
        updatedTask.categoryId = selectedCategoryId
        updatedTask.tags = selectedTags
        updatedTask.updatedAt = Date()
        updatedTask.repeatEnabled = repeatEnabled
        updatedTask.repeatType = repeatType
        updatedTask.repeatInterval = repeatInterval
        updatedTask.repeatEndDate = repeatEndDate
        
        // 通知設定を更新
        taskStore.updateTaskNotification(updatedTask, notificationEnabled: notificationEnabled, notificationTime: notificationTime)
        
        // タスクを更新
        taskStore.updateTask(updatedTask)
        
        dismiss()
    }
    
    private func deleteTask() {
        taskStore.deleteTask(task)
        dismiss()
    }
}

// カスタムテキストフィールドスタイル
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(TaskPlusTheme.colors.surface)
            )
            .foregroundColor(TaskPlusTheme.colors.textPrimary)
    }
}

// カスタムトグルスイッチスタイル
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.surface)
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 27, height: 27)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.2), value: configuration.isOn)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// 優先度ボタン
struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : TaskPlusTheme.colors.textSecondary)
                
                Text(priority.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : TaskPlusTheme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// カテゴリ選択ボタン
struct CategorySelectionButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon.systemName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color.color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? category.color.color : category.color.color.opacity(0.15))
                    )
                
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : TaskPlusTheme.colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color.color : TaskPlusTheme.colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.clear : category.color.color.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
            EditTaskSheet(
            task: TaskItem(title: "サンプルタスク"),
            taskStore: TaskStore()
        )
}
