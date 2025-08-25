import SwiftUI

struct TodayView: View {
    @ObservedObject var taskStore: TaskStore
    @ObservedObject var guideManager: GuideModeManager
    @State private var showingAddSheet = false
    
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
                
                if taskStore.todayTasks.isEmpty && taskStore.todayCompletedCount == 0 {
                    emptyStateView
                } else {
                    taskListView
                }
            }
            .background(TaskPlusTheme.colors.bg)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
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
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bolt.fill")
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
            if !taskStore.todayTasks.isEmpty {
                Section {
                    ForEach(taskStore.todayTasks) { task in
                        TaskRow(
                            task: task,
                            isInbox: false,
                            onComplete: { taskStore.completeTask(task) },
                            onDelete: { taskStore.deleteTask(task) },
                            onMoveToToday: { },
                            taskStore: taskStore
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                    .onMove(perform: { source, destination in
                        taskStore.reorderTasks(in: .today, from: source, to: destination)
                    })
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
            
            // Completed tasks
            if taskStore.todayCompletedCount > 0 {
                Section {
                    ForEach(taskStore.doneTasks.filter { $0.status == .done }, id: \.id) { task in
                        completedTaskRow(task)
                    }
                } header: {
                    HStack {
                        Text("完了済み")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(taskStore.todayCompletedCount)")
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
    }
    
    private func completedTaskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 14) {
            // Completed indicator
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(TaskPlusTheme.colors.success)
                .font(.title3)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    .strikethrough()
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(TaskPlusTheme.colors.surface.opacity(0.5))
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
    }
    
    // コンシェルジュカード
    private var conciergeCard: some View {
        if taskStore.todayTasks.isEmpty && taskStore.todayCompletedCount == 0 {
            return ConciergeCard(
                message: "今日のタスクはありません",
                icon: "calendar.badge.plus",
                actionText: "Inboxからタスクを整理して、今日やることを決めましょう"
            ) {
                // ガイドの次のステップに進む
                guideManager.nextStep()
            }
        } else if taskStore.todayCompletedCount > 0 {
            return ConciergeCard(
                message: "素晴らしい進歩です！",
                icon: "checkmark.circle.fill",
                actionText: "完了したタスクを振り返って、明日の計画を立ててみましょう"
            ) {
                // ガイドの次のステップに進む
                guideManager.nextStep()
            }
        } else {
            return ConciergeCard(
                message: "どれから始めますか？",
                icon: "bolt.fill",
                actionText: "タスクをタップして詳細を確認し、集中モードに入りましょう！"
            ) {
                // ガイドの次のステップに進む
                guideManager.nextStep()
            }
        }
    }
}

#Preview {
    TodayView(
        taskStore: TaskStore(),
        guideManager: GuideModeManager()
    )
        .preferredColorScheme(.dark)
}
