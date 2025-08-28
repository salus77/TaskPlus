import SwiftUI

struct PomodoroTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int = 25 * 60 // 25分
    @State private var isTimerRunning = false
    @State private var selectedTag: String = ""
    @State private var showingTagSelection = false
    
    let task: TaskItem
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // タスク表示
                VStack(spacing: 16) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // タグ選択
                    Button(action: {
                        showingTagSelection = true
                    }) {
                        HStack {
                            Text(selectedTag.isEmpty ? "タグを選択 >" : selectedTag)
                                .foregroundColor(selectedTag.isEmpty ? TaskPlusTheme.colors.textSecondary : TaskPlusTheme.colors.neonPrimary)
                            if selectedTag.isEmpty {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedTag.isEmpty ? TaskPlusTheme.colors.textSecondary.opacity(0.3) : TaskPlusTheme.colors.neonPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                // タイマー
                ZStack {
                    // タイマーの円形の輪郭
                    Circle()
                        .stroke(TaskPlusTheme.colors.textSecondary.opacity(0.2), lineWidth: 2)
                        .frame(width: 280, height: 280)
                    
                    // プログレスドット（現在は開始位置）
                    Circle()
                        .fill(TaskPlusTheme.colors.neonPrimary)
                        .frame(width: 8, height: 8)
                        .offset(y: -140)
                    
                    // 時間表示
                    VStack(spacing: 8) {
                        Text(timeString)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        
                        Text(isTimerRunning ? "集中中..." : "準備完了")
                            .font(.caption)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                }
                
                // 設定アイコン
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Text("Style")
                            .font(.caption)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Text("Sound")
                            .font(.caption)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.title2)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Text("Mode")
                            .font(.caption)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // スタート/ストップボタン
                Button(action: {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isTimerRunning ? "ストップ" : "スタート")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(isTimerRunning ? TaskPlusTheme.colors.danger : TaskPlusTheme.colors.neonPrimary)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 設定メニュー
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagSelection) {
            TagSelectionSheet(selectedTags: $selectedTag, availableTags: task.tags)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isTimerRunning && timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining == 0 {
                    timerCompleted()
                }
            }
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        isTimerRunning = true
        print("DEBUG: ポモドーロタイマー開始 - タスク: '\(task.title)'")
    }
    
    private func stopTimer() {
        isTimerRunning = false
        print("DEBUG: ポモドーロタイマー停止 - タスク: '\(task.title)'")
    }
    
    private func timerCompleted() {
        isTimerRunning = false
        print("DEBUG: ポモドーロタイマー完了 - タスク: '\(task.title)'")
        // ここで通知や完了処理を追加できます
    }
}

// タグ選択用のシンプルなシート
struct TagSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: String
    let availableTags: [String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    Button(action: {
                        selectedTags = tag
                        dismiss()
                    }) {
                        HStack {
                            Text(tag)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            Spacer()
                            if selectedTags == tag {
                                Image(systemName: "checkmark")
                                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("タグを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PomodoroTimerView(task: TaskItem(
        title: "Jiraの整理がしたい",
        notes: "プロジェクトの整理と優先度の見直し",
        priority: .normal,
        tags: ["#重要", "#整理", "#優先度"]
    ))
}
