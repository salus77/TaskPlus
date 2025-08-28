import SwiftUI

struct InlineAddBar: View {
    @Binding var text: String
    let onAdd: (String) -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isGlowing = false
    @State private var isAddingTask = false // タスク追加時のアニメーション用
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .font(.title2)
                
                TextField("タスクを追加", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    .focused($isFocused)
                    .onSubmit {
                        addTask()
                    }
            }
            
            Button(action: addTask) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .font(.title3)
                    .rotationEffect(.degrees(isGlowing ? 15 : 0))
                    .scaleEffect(isGlowing ? 1.1 : 1.0)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TaskPlusTheme.colors.surface)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // 光るエフェクト（タスク追加時）
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            TaskPlusTheme.colors.neonPrimary.opacity(isAddingTask ? 0.8 : 0),
                            TaskPlusTheme.colors.neonPrimary.opacity(isAddingTask ? 0.4 : 0),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(isAddingTask ? 1.1 : 1.0)
                .opacity(isAddingTask ? 1 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? TaskPlusTheme.colors.neonPrimary : Color.clear,
                    lineWidth: isFocused ? 2 : 0
                )
                .shadow(
                    color: isFocused ? TaskPlusTheme.colors.neonPrimary.opacity(0.6) : Color.clear,
                    radius: 22,
                    x: 0,
                    y: 0
                )
        )
        // タスクチケット側のアニメーションに変更するため、InlineAddBarのアニメーションを無効化
        // .offset(y: isAddingTask ? -20 : 0) // 下から上へのスワイプ効果
        // .scaleEffect(isAddingTask ? 1.05 : 1.0) // スケール効果
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        // .animation(.easeInOut(duration: 0.6), value: isAddingTask)
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private func addTask() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // テキストをクリアしてフォーカスを外す（即座に実行）
        let taskText = trimmedText
        text = ""
        isFocused = false
        
        // タスクチケット側のアニメーションに変更するため、InlineAddBarのアニメーションを簡素化
        withAnimation(.easeIn(duration: 0.1)) {
            isAddingTask = true
        }
        
        // すぐにタスクを追加（タスクチケット側のアニメーションが動作する）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onAdd(taskText)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
            
            // アニメーション終了
            withAnimation(.easeOut(duration: 0.1)) {
                isAddingTask = false
            }
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isGlowing = true
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        InlineAddBar(text: .constant(""), onAdd: { _ in })
        InlineAddBar(text: .constant("サンプルタスク"), onAdd: { _ in })
    }
    .padding()
    .background(TaskPlusTheme.colors.bg)
}
