import SwiftUI

struct GuideProgressBar: View {
    @ObservedObject var guideManager: GuideModeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // タイトル
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(TaskPlusTheme.colors.warning)
                    .font(.caption)
                
                Text("GTDガイド")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                Spacer()
            }
            
            // プログレスバー
            HStack(spacing: 4) {
                ForEach(guideManager.steps) { step in
                    stepIndicator(for: step)
                }
            }
            
            // 現在のステップ説明
            if guideManager.currentStep < guideManager.steps.count {
                let currentStep = guideManager.steps[guideManager.currentStep]
                HStack(spacing: 8) {
                    Image(systemName: currentStep.icon)
                        .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        .font(.caption)
                    
                    Text("\(currentStep.title): \(currentStep.description)")
                        .font(.caption)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TaskPlusTheme.colors.surface.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(TaskPlusTheme.colors.neonPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(TaskPlusTheme.colors.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func stepIndicator(for step: GuideStep) -> some View {
        let isCompleted = step.id < guideManager.currentStep
        let isCurrent = step.id == guideManager.currentStep
        
        return VStack(spacing: 4) {
            // ステップアイコン
            ZStack {
                Circle()
                    .fill(stepColor(for: step, isCompleted: isCompleted, isCurrent: isCurrent))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: step.icon)
                        .font(.caption)
                        .foregroundColor(isCurrent ? .white : TaskPlusTheme.colors.textSecondary)
                }
            }
            .scaleEffect(isCurrent ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isCurrent)
            
            // ステップタイトル
            Text(step.title)
                .font(.caption2)
                .fontWeight(isCurrent ? .semibold : .medium)
                .foregroundColor(isCurrent ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func stepColor(for step: GuideStep, isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return TaskPlusTheme.colors.success
        } else if isCurrent {
            return TaskPlusTheme.colors.neonPrimary
        } else {
            return TaskPlusTheme.colors.surface
        }
    }
}

#Preview {
    GuideProgressBar(guideManager: GuideModeManager())
        .padding()
        .background(TaskPlusTheme.colors.bg)
}
