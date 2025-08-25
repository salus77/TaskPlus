import SwiftUI

struct TutorialView: View {
    @ObservedObject var guideManager: GuideModeManager
    @ObservedObject var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var showingSampleTask = false
    
    private let tutorialSteps = [
        TutorialStep(
            title: "Task Plusへようこそ！",
            description: "GTD（Getting Things Done）の流れに沿って、やることを整理していきましょう。",
            icon: "hand.wave.fill",
            action: "始める"
        ),
        TutorialStep(
            title: "ステップ1: 書き出す",
            description: "まずは頭の中にあるやることを、すべてInboxに書き出してみましょう。",
            icon: "tray.fill",
            action: "タスクを追加"
        ),
        TutorialStep(
            title: "ステップ2: 整理する",
            description: "書き出したタスクを、今日やるものとそうでないものに分けましょう。",
            icon: "arrow.right.circle.fill",
            action: "今日に移動"
        ),
        TutorialStep(
            title: "ステップ3: 準備する",
            description: "今日やるタスクに優先度やタグをつけて、準備を整えましょう。",
            icon: "tag.fill",
            action: "詳細設定"
        ),
        TutorialStep(
            title: "ステップ4: 集中する",
            description: "準備が整ったタスクに集中して取り組みましょう。",
            icon: "bolt.fill",
            action: "集中モード"
        ),
        TutorialStep(
            title: "ステップ5: 振り返る",
            description: "完了したタスクを振り返って、明日の計画を立てましょう。",
            icon: "checkmark.circle.fill",
            action: "完了"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景
            TaskPlusTheme.colors.bg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // メインコンテンツ
                ScrollView {
                    VStack(spacing: 24) {
                        // 現在のステップ表示
                        currentStepView
                        
                        // プログレスインジケーター
                        progressIndicator
                        
                        // アクションボタン
                        actionButton
                        
                        // スキップボタン
                        skipButton
                    }
                    .padding(24)
                }
            }
        }
        .onAppear {
            startTutorial()
        }
        .sheet(isPresented: $showingSampleTask) {
            sampleTaskSheet
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("チュートリアル")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(TaskPlusTheme.colors.textPrimary)
            
            Spacer()
            
            Button("スキップ") {
                completeTutorial()
            }
            .font(.subheadline)
            .foregroundColor(TaskPlusTheme.colors.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var currentStepView: some View {
        VStack(spacing: 16) {
            // アイコン
            Image(systemName: tutorialSteps[currentStep].icon)
                .font(.system(size: 64))
                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                .shadow(color: TaskPlusTheme.colors.neonPrimary.opacity(0.6), radius: 16)
            
            // タイトル
            Text(tutorialSteps[currentStep].title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                .multilineTextAlignment(.center)
            
            // 説明
            Text(tutorialSteps[currentStep].description)
                .font(.body)
                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(.vertical, 32)
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<tutorialSteps.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.textSecondary.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(index == currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: handleAction) {
            HStack(spacing: 8) {
                Text(tutorialSteps[currentStep].action)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if currentStep < tutorialSteps.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(TaskPlusTheme.colors.neonPrimary)
                    .shadow(color: TaskPlusTheme.colors.neonPrimary.opacity(0.6), radius: 8, x: 0, y: 4)
            )
        }
        .scaleEffect(currentStep == 0 ? 1.0 : 1.0)
        .animation(.spring(response: 0.3), value: currentStep)
    }
    
    private var skipButton: some View {
        Button("チュートリアルをスキップ") {
            completeTutorial()
        }
        .font(.subheadline)
        .foregroundColor(TaskPlusTheme.colors.textSecondary)
        .padding(.top, 16)
    }
    
    private var sampleTaskSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("サンプルタスクを追加しました！")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                Text("「牛乳を買う」というタスクがInboxに追加されました。右にスワイプしてTodayに移動してみましょう。")
                    .font(.body)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                
                Button("続ける") {
                    showingSampleTask = false
                    nextStep()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(TaskPlusTheme.colors.neonPrimary)
                )
                
                Spacer()
            }
            .padding(24)
            .background(TaskPlusTheme.colors.bg)
            .navigationTitle("サンプルタスク追加")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func startTutorial() {
        currentStep = 0
        guideManager.currentStep = 0
    }
    
    private func handleAction() {
        switch currentStep {
        case 1: // タスクを追加
            addSampleTask()
        case 2: // 今日に移動
            moveSampleTaskToToday()
        case 3: // 詳細設定
            showDetailSettings()
        case 4: // 集中モード
            showFocusMode()
        case 5: // 完了
            completeTutorial()
        default:
            nextStep()
        }
    }
    
    private func addSampleTask() {
        let sampleTask = TaskItem(title: "牛乳を買う", notes: "サンプルタスクです", priority: .normal, context: .errand)
        taskStore.addTask(sampleTask)
        showingSampleTask = true
    }
    
    private func moveSampleTaskToToday() {
        if let sampleTask = taskStore.inboxTasks.first(where: { $0.title == "牛乳を買う" }) {
            taskStore.moveToToday(sampleTask)
        }
        nextStep()
    }
    
    private func showDetailSettings() {
        // 詳細設定の説明
        nextStep()
    }
    
    private func showFocusMode() {
        // 集中モードの説明
        nextStep()
    }
    
    private func nextStep() {
        if currentStep < tutorialSteps.count - 1 {
            withAnimation(.spring(response: 0.5)) {
                currentStep += 1
                guideManager.currentStep = currentStep
            }
        } else {
            completeTutorial()
        }
    }
    
    private func completeTutorial() {
        guideManager.completeTutorial()
        dismiss()
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let action: String
}

#Preview {
    TutorialView(
        guideManager: GuideModeManager(),
        taskStore: TaskStore()
    )
}
