import SwiftUI

struct InlineAddBar: View {
    @Binding var text: String
    let onAdd: (String) -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isGlowing = false
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .font(.title2)
                
                TextField("すぐ書いてEnterで追加", text: $text)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private func addTask() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        onAdd(trimmedText)
        text = ""
        isFocused = false
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
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
