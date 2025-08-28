import SwiftUI

struct TagSelectionView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var selectedTags: [String]
    @State private var showingTagManagement = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("タグ")
                    .font(.headline)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                
                Spacer()
                
                Button("管理") {
                    showingTagManagement = true
                }
                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                .font(.caption)
            }
            
            // すべてのタグの表示（横並びでスワイプ可能）
            if !taskStore.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(taskStore.tags, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                onTap: {
                                    if selectedTags.contains(tag) {
                                        // 選択されている場合は選択解除
                                        selectedTags.removeAll { $0 == tag }
                                    } else {
                                        // 選択されていない場合は選択
                                        selectedTags.append(tag)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            

        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementSheet(taskStore: taskStore)
        }
    }
    

}

// MARK: - Tag Chip Component
struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let onTap: (() -> Void)?
    
    init(tag: String, isSelected: Bool, onTap: (() -> Void)? = nil) {
        self.tag = tag
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(isSelected ? .white : TaskPlusTheme.colors.neonPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.clear : TaskPlusTheme.colors.textSecondary,
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    TagSelectionView(
        taskStore: TaskStore(),
        selectedTags: .constant(["#Someday", "#重要"])
    )
}
