import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let isInbox: Bool
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onMoveToToday: () -> Void
    
    @State private var isPressed = false
    @State private var showingEditSheet = false
    @State private var isDragging = false
    @ObservedObject var taskStore: TaskStore
    
    init(task: TaskItem, isInbox: Bool, onComplete: @escaping () -> Void, onDelete: @escaping () -> Void, onMoveToToday: @escaping () -> Void, taskStore: TaskStore) {
        self.task = task
        self.isInbox = isInbox
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onMoveToToday = onMoveToToday
        self.taskStore = taskStore
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Leading indicator
            leadingIndicator
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        .lineLimit(2)
                }
                
                // Badges
                if !isInbox {
                    HStack(spacing: 8) {
                        priorityBadge
                        contextBadge
                    }
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TaskPlusTheme.colors.surface)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isPressed ? TaskPlusTheme.colors.neonPrimary : Color.clear,
                    lineWidth: isPressed ? 2 : 0
                )
                .shadow(
                    color: isPressed ? TaskPlusTheme.colors.neonPrimary.opacity(0.6) : Color.clear,
                    radius: 22,
                    x: 0,
                    y: 0
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isPressed)
        .onTapGesture {
            // タップで編集シートを表示
            showingEditSheet = true
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // 長押しで並び替えモード開始
            isDragging = true
            isPressed = true
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = pressing
                if !pressing {
                    isDragging = false
                }
            }
        }
        .overlay(
            // 長押しヒント
            VStack {
                Spacer()
            }
            .padding(.top, 8)
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .shadow(
            color: isDragging ? TaskPlusTheme.colors.neonPrimary.opacity(0.3) : .clear,
            radius: isDragging ? 12 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .sheet(isPresented: $showingEditSheet) {
            EditTaskSheet(task: task, taskStore: taskStore)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if isInbox {
                Button(action: onMoveToToday) {
                    Label("Todayへ", systemImage: "bolt.fill")
                }
                .tint(TaskPlusTheme.colors.neonPrimary)
            } else {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        onComplete()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // showParticles = false // This line was removed
                    }
                }) {
                    Label("完了", systemImage: "checkmark.circle.fill")
                }
                .tint(TaskPlusTheme.colors.success)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if isInbox {
                Button(action: onDelete) {
                    Label("削除", systemImage: "trash.fill")
                }
                .tint(TaskPlusTheme.colors.danger)
            } else {
                Button(action: onDelete) {
                    Label("削除", systemImage: "trash.fill")
                }
                .tint(TaskPlusTheme.colors.danger)
            }
        }
    }
    
    // MARK: - Subviews
    private var leadingIndicator: some View {
        Group {
            if isInbox {
                Circle()
                    .fill(TaskPlusTheme.colors.neonAccent)
                    .frame(width: 8, height: 8)
                    .shadow(color: TaskPlusTheme.colors.neonAccent.opacity(0.6), radius: 4)
            } else {
                Rectangle()
                    .fill(priorityColor)
                    .frame(width: 4, height: 24)
                    .cornerRadius(2)
            }
        }
    }
    
    private var priorityBadge: some View {
        Text(task.priority.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(priorityColor.opacity(0.2))
            )
            .foregroundColor(priorityColor)
    }
    
    private var contextBadge: some View {
        Group {
            if let categoryId = task.categoryId,
               let category = taskStore.categories.first(where: { $0.id == categoryId }) {
                HStack(spacing: 4) {
                    Image(systemName: category.icon.systemName)
                        .font(.caption2)
                        .foregroundColor(category.color.color)
                    Text(category.name)
                        .font(.caption2)
                        .foregroundColor(category.color.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.color.opacity(0.1))
                )
            } else {
                EmptyView()
            }
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return TaskPlusTheme.colors.warning
        case .normal:
            return TaskPlusTheme.colors.neonPrimary
        case .low:
            return TaskPlusTheme.colors.textSecondary
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TaskRow(
            task: TaskItem(title: "サンプルタスク", notes: "これはサンプルタスクです"),
            isInbox: true,
            onComplete: { },
            onDelete: { },
            onMoveToToday: { },
            taskStore: TaskStore()
        )
        
        TaskRow(
            task: TaskItem(title: "今日のタスク", notes: "これは今日のタスクです"),
            isInbox: false,
            onComplete: { },
            onDelete: { },
            onMoveToToday: { },
            taskStore: TaskStore()
        )
    }
    .padding()
    .background(TaskPlusTheme.colors.bg)
}
