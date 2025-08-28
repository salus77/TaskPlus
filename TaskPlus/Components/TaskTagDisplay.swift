import SwiftUI

struct TaskTagDisplay: View {
    let tags: [String]
    
    var body: some View {
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(TaskPlusTheme.colors.neonPrimary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(TaskPlusTheme.colors.neonPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    TaskTagDisplay(tags: ["#仕事", "#緊急", "#会議"])
        .padding()
        .background(TaskPlusTheme.colors.bg)
}
