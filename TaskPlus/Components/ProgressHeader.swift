import SwiftUI

struct ProgressHeader: View {
    let completedCount: Int
    let totalCount: Int
    
    private var progress: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress text
            HStack {
                Text("今日の進捗")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(TaskPlusTheme.colors.surface)
                        .frame(height: 8)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    TaskPlusTheme.colors.neonPrimary,
                                    TaskPlusTheme.colors.neonAccent
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .shadow(
                            color: TaskPlusTheme.colors.neonPrimary.opacity(0.6),
                            radius: 4,
                            x: 0,
                            y: 0
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            // Motivational text
            if totalCount > 0 {
                Text(motivationalText)
                    .font(.caption)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var motivationalText: String {
        if completedCount == 0 {
            return "今日も頑張ろう！"
        } else if completedCount < totalCount / 2 {
            return "順調に進んでいます"
        } else if completedCount < totalCount {
            return "あと少し！"
        } else {
            return "完璧です！🎉"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressHeader(completedCount: 0, totalCount: 5)
        ProgressHeader(completedCount: 2, totalCount: 5)
        ProgressHeader(completedCount: 5, totalCount: 5)
    }
    .padding()
    .background(TaskPlusTheme.colors.bg)
}
