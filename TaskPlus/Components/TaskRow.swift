import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let isInbox: Bool
    let isTodayView: Bool // TodayViewでのスワイプアクション制御用
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onMoveToToday: () -> Void
    
    @State private var showingEditSheet = false
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var isSwipingOut = false // スワイプアウトアニメーション用
    @State private var isGlowing = false // 光るエフェクト用
    @State private var swipeDirection: SwipeDirection = .none // スワイプ方向
    @State private var isRestoring = false // 復元時のアニメーション制御用
    @State private var isCompleting = false // 完了時のアニメーション制御用
    @State private var isFadingOut = false // フェードアウトアニメーション制御用
    @State private var fadeDirection: FadeDirection = .none // フェードアニメーションの方向

    @ObservedObject var taskStore: TaskStore
    
    init(task: TaskItem, isInbox: Bool, isTodayView: Bool = false, onComplete: @escaping () -> Void, onDelete: @escaping () -> Void, onMoveToToday: @escaping () -> Void, taskStore: TaskStore) {
        self.task = task
        self.isInbox = isInbox
        self.isTodayView = isTodayView
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onMoveToToday = onMoveToToday
        self.taskStore = taskStore
        

    }
    
    var body: some View {
        let _ = print("DEBUG: TaskRow body rendering for task: '\(task.title)' with status: \(task.status)")
        HStack(spacing: 12) {
            // ラジオボタン（左側）
            leadingIndicator
            
            // タスク情報（中央）
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(task.status == .done ? TaskPlusTheme.colors.textSecondary : TaskPlusTheme.colors.textPrimary)
                    .strikethrough(task.status == .done, color: TaskPlusTheme.colors.textSecondary)
                    .onTapGesture {
                        // タイトルをタップした場合のみ編集シートを表示
                        showingEditSheet = true
                    }
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        .lineLimit(2)
                        .onTapGesture {
                            // メモをタップした場合も編集シートを表示
                            showingEditSheet = true
                        }
                }
                
                // Badges
                HStack(spacing: 8) {
                    priorityBadge
                    contextBadge
                }
                .opacity(task.status == .done ? 0.6 : 1.0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 編集アイコン（右側）
            Button(action: {
                print("DEBUG: 編集アイコンがタップされました")
                print("DEBUG: タスクID: \(task.id)")
                print("DEBUG: タスクのタイトル: '\(task.title)'")
                
                // 編集シートを表示
                showingEditSheet = true
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(task.status == .done ? TaskPlusTheme.colors.surface.opacity(0.7) : TaskPlusTheme.colors.surface)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // 光るエフェクト
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            TaskPlusTheme.colors.neonPrimary.opacity(isGlowing ? 0.8 : 0),
                            TaskPlusTheme.colors.neonPrimary.opacity(isGlowing ? 0.4 : 0),
                            Color.clear
                        ],
                        startPoint: swipeDirection == .left ? .leading : 
                                   swipeDirection == .right ? .trailing :
                                   swipeDirection == .down ? .top : .leading,
                        endPoint: swipeDirection == .left ? .trailing : 
                                 swipeDirection == .right ? .leading :
                                 swipeDirection == .down ? .bottom : .trailing
                    )
                )
                .scaleEffect(isGlowing ? 1.1 : 1.0)
                .opacity(isGlowing ? 1 : 0)
        )
        .offset(
            x: isSwipingOut && (swipeDirection == .left || swipeDirection == .right) ? 
                (swipeDirection == .left ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width) : 0,
            y: isSwipingOut && swipeDirection == .down ? UIScreen.main.bounds.height : 
                 isRestoring ? 100 : // 復元時は下から上にスライドイン
                 isCompleting ? -100 : // 完了時は上から下にスライドイン
                 0
        )
        .opacity(isSwipingOut || isFadingOut ? 0 : 1.0) // スワイプアウト時またはフェードアウト時は透明
        .onAppear {
            print("DEBUG: TaskRow appeared for task: '\(task.title)' with status: \(task.status) and ID: \(task.id)")
            
            // 復元時のアニメーション制御
            if task.isRestoring {
                print("DEBUG: TaskRow restoring animation started for task: '\(task.title)'")
                // 復元されたタスクの場合、下から上にフェードイン
                isRestoring = true
                
                // 少し遅延してからアニメーション開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isRestoring = false
                    }
                }
            }
            
            // 完了時のアニメーション制御
            if task.status == .done && !isCompleting {
                print("DEBUG: TaskRow completing animation started for task: '\(task.title)'")
                // 完了状態になった場合、上から下にフェードイン
                isCompleting = true
                
                // 少し遅延してからアニメーション開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isCompleting = false
                    }
                }
            }
        }
        .onChange(of: task.status) { oldStatus, newStatus in
            // タスクの状態変更を監視
            if oldStatus != .done && newStatus == .done {
                // 完了状態になった場合
                print("DEBUG: Task status changed to done, starting completion animation")
                startCompletionAnimation()
            } else if oldStatus == .done && newStatus != .done {
                // 復元状態になった場合
                print("DEBUG: Task status changed from done, starting restoration animation")
                startRestorationAnimation()
            }
        }
        .onDisappear {
            print("DEBUG: TaskRow disappeared for task: '\(task.title)' with status: \(task.status) and ID: \(task.id)")
        }
        .onTapGesture {
            // 背景をタップした場合も編集シートを表示（ラジオボタン以外の部分）
            showingEditSheet = true
        }
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
            // ラジオボタン部分をタップした場合は何もしない
            // タスク詳細表示は別の方法で行う
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
            if isInbox && !isTodayView {
                // InboxViewでのみ雷マークを表示（Todayへ移動）
                Button(action: {
                    swipeOutAndExecute(onMoveToToday, direction: .right)
                }) {
                    Label("Todayへ", systemImage: "bolt.fill")
                }
                .tint(TaskPlusTheme.colors.neonPrimary)
            } else if isTodayView {
                // TodayViewではInboxアイコンを表示（Inboxに戻す）
                Button(action: {
                    swipeOutAndExecute(onComplete, direction: .right)
                }) {
                    Label("完了", systemImage: "checkmark.circle.fill")
                }
                .tint(TaskPlusTheme.colors.success)
            } else {
                // その他の場合（TodayViewでないInboxタスク）
                Button(action: {
                    swipeOutAndExecute({
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            onComplete()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // showParticles = false // This line was removed
                        }
                    }, direction: .right)
                }) {
                    Label("完了", systemImage: "checkmark.circle.fill")
                }
                .tint(TaskPlusTheme.colors.success)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if isInbox {
                Button(action: {
                    swipeOutAndExecute(onDelete, direction: .left)
                }) {
                    Label("削除", systemImage: "trash.fill")
                }
                .tint(TaskPlusTheme.colors.danger)
            } else {
                Button(action: {
                    swipeOutAndExecute(onDelete, direction: .left)
                }) {
                    Label("削除", systemImage: "trash.fill")
                }
                .tint(TaskPlusTheme.colors.danger)
            }
        }
    }
    
    // MARK: - Enums
    enum SwipeDirection {
        case left, right, none, down
    }
    
    enum FadeDirection {
        case up, down, none
    }
    
    // MARK: - Helper Functions
    private func swipeOutAndExecute(_ action: @escaping () -> Void, direction: SwipeDirection = .left) {
        swipeDirection = direction
        
        // 1. 一瞬光るエフェクトを開始
        withAnimation(.easeIn(duration: 0.1)) {
            isGlowing = true
        }
        
        // 2. 光るエフェクトを少し遅れて終了し、同時にスワイプアウトを開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGlowing = false
                isSwipingOut = true
            }
        }
        
        // 3. スワイプアウト完了後にアクションを実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            action()
        }
    }
    
    // 完了処理用の新しいアニメーション関数
    private func completeTaskWithAnimation(_ action: @escaping () -> Void) {
        // 1. 一瞬光るエフェクトを開始
        withAnimation(.easeIn(duration: 0.1)) {
            isGlowing = true
        }
        
        // 2. 光るエフェクトを少し遅れて終了し、同時に上から下にフェードアウトを開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isGlowing = false
                isFadingOut = true
                fadeDirection = .down
            }
        }
        
        // 3. フェードアウト完了後にアクションを実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            action()
        }
    }
    
    // 完了時のアニメーション開始関数
    private func startCompletionAnimation() {
        // 1. 一瞬光るエフェクトを開始
        withAnimation(.easeIn(duration: 0.1)) {
            isGlowing = true
        }
        
        // 2. 光るエフェクトを少し遅れて終了し、同時に上から下にフェードアウトを開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isGlowing = false
                isFadingOut = true
                fadeDirection = .down
            }
        }
        
        // 3. フェードアウト完了後にフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isFadingOut = false
            fadeDirection = .none
        }
    }
    
    // 復元時のアニメーション開始関数
    private func startRestorationAnimation() {
        // 1. 一瞬光るエフェクトを開始
        withAnimation(.easeIn(duration: 0.1)) {
            isGlowing = true
        }
        
        // 2. 光るエフェクトを少し遅れて終了し、同時に上から下にフェードアウトを開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isGlowing = false
                isFadingOut = true
                fadeDirection = .up
            }
        }
        
        // 3. フェードアウト完了後にフラグをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            isFadingOut = false
            fadeDirection = .none
        }
    }
    

    
    // MARK: - Subviews
    private var leadingIndicator: some View {
        Group {
            if isInbox {
                // Inboxではタスク完了状態のラジオボタンと優先度バーの両方を表示
                HStack(spacing: 8) {
                    // 優先度バー
                    Rectangle()
                        .fill(priorityColor)
                        .frame(width: 4, height: 24)
                        .cornerRadius(2)
                    
                    // ラジオボタン
                    Button(action: {
                        print("DEBUG: ラジオボタンがタップされました")
                        print("DEBUG: タスクID: \(task.id)")
                        print("DEBUG: タスクの現在のステータス: \(task.status)")
                        print("DEBUG: タスクのタイトル: '\(task.title)'")
                        
                        if task.status == .done {
                            print("DEBUG: 完了済みタスクの復元を実行")
                        } else {
                            print("DEBUG: 未完了タスクの完了を実行")
                        }
                        
                        completeTaskWithAnimation(onComplete)
                    }) {
                        ZStack {
                            Circle()
                                .stroke(task.status == .done ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.textSecondary, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if task.status == .done {
                                Circle()
                                    .fill(TaskPlusTheme.colors.neonPrimary)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                // Today Viewでは優先度バーのみを表示
                Rectangle()
                    .fill(priorityColor)
                    .frame(width: 4, height: 24)
                    .cornerRadius(2)
            }
        }
    }
    
    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: priorityIcon)
                .font(.caption)
                .foregroundColor(priorityColor)
            Text(task.priority.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(priorityColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(priorityColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var contextBadge: some View {
        Group {
            if let categoryId = task.categoryId,
               let category = taskStore.categories.first(where: { $0.id == categoryId }) {
                HStack(spacing: 4) {
                    Image(systemName: category.icon.systemName)
                        .font(.caption)
                        .foregroundColor(category.color.color)
                    Text(category.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(category.color.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.color.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(category.color.color.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // カテゴリがない場合は「未分類」バッジを表示
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    Text("未分類")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TaskPlusTheme.colors.textSecondary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(TaskPlusTheme.colors.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var priorityIcon: String {
        switch task.priority {
        case .high:
            return "exclamationmark.triangle.fill"
        case .normal:
            return "circle.fill"
        case .low:
            return "minus.circle.fill"
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
    
    // MARK: - Animation Helper Functions

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
