import SwiftUI

struct InboxView: View {
    @ObservedObject var taskStore: TaskStore
    @ObservedObject var guideManager: GuideModeManager
    @State private var showingAddSheet = false
    @State private var inlineAddText = ""
    
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
                
                if taskStore.inboxTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
                
                // Inline add bar
                VStack(spacing: 0) {
                    Divider()
                        .background(TaskPlusTheme.colors.surface)
                    
                    InlineAddBar(text: $inlineAddText) { text in
                        let task = TaskItem(title: text, sortOrder: taskStore.inboxTasks.count, notificationEnabled: true, notificationTime: nil)
                        taskStore.addTask(task)
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
        List {
            ForEach(taskStore.inboxTasks) { task in
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
            }
            .onMove(perform: { source, destination in
                taskStore.reorderTasks(in: .inbox, from: source, to: destination)
            })
        }
        .listStyle(PlainListStyle())
        .background(TaskPlusTheme.colors.bg)
    }
    
    // コンシェルジュカード
    private var conciergeCard: some View {
        if taskStore.inboxTasks.isEmpty {
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
