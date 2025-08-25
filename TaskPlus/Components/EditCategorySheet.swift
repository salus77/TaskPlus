import SwiftUI

struct EditCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskStore: TaskStore
    let category: Category?
    
    @State private var name: String
    @State private var selectedIcon: CategoryIcon
    @State private var selectedColor: CategoryColor
    @State private var showingDeleteAlert = false
    
    init(category: Category?, taskStore: TaskStore) {
        self.category = category
        self.taskStore = taskStore
        self._name = State(initialValue: category?.name ?? "")
        self._selectedIcon = State(initialValue: category?.icon ?? .briefcase)
        self._selectedColor = State(initialValue: category?.color ?? .blue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // カテゴリ名入力欄
                        VStack(alignment: .leading, spacing: 12) {
                            Text("カテゴリ名")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            
                            TextField("カテゴリ名を入力", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // アイコン選択セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("アイコン")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                                ForEach(CategoryIcon.allCases, id: \.self) { icon in
                                    IconSelectionButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        action: { selectedIcon = icon }
                                    )
                                }
                            }
                        }
                        
                        // 色選択セクション
                        VStack(alignment: .leading, spacing: 16) {
                            Text("色")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                                ForEach(CategoryColor.allCases, id: \.self) { color in
                                    ColorSelectionButton(
                                        color: color,
                                        isSelected: selectedColor == color,
                                        action: { selectedColor = color }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // カテゴリ削除ボタン（編集時のみ表示）
                if category != nil {
                    Button(action: { showingDeleteAlert = true }) {
                        Text("カテゴリを削除")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(TaskPlusTheme.colors.danger)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(TaskPlusTheme.colors.bg)
            .navigationTitle(category != nil ? "カテゴリを編集" : "カテゴリを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCategory()
                    }
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("カテゴリを削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteCategory()
            }
        } message: {
            Text("このカテゴリを削除しますか？この操作は取り消せません。")
        }
    }
    
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existingCategory = category {
            // 既存カテゴリを更新
            var updatedCategory = existingCategory
            updatedCategory.name = trimmedName
            updatedCategory.icon = selectedIcon
            updatedCategory.color = selectedColor
            updatedCategory.updatedAt = Date()
            taskStore.updateCategory(updatedCategory)
        } else {
            // 新しいカテゴリを作成
            let newCategory = Category(
                name: trimmedName,
                icon: selectedIcon,
                color: selectedColor
            )
            taskStore.addCategory(newCategory)
        }
        
        dismiss()
    }
    
    private func deleteCategory() {
        guard let category = category else { return }
        taskStore.deleteCategory(category)
        dismiss()
    }
}

// アイコン選択ボタン
struct IconSelectionButton: View {
    let icon: CategoryIcon
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon.systemName)
                .font(.title2)
                .foregroundColor(isSelected ? .white : TaskPlusTheme.colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? TaskPlusTheme.colors.neonPrimary : TaskPlusTheme.colors.surface)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 色選択ボタン
struct ColorSelectionButton: View {
    let color: CategoryColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? TaskPlusTheme.colors.neonPrimary : Color.clear,
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: isSelected ? TaskPlusTheme.colors.neonPrimary.opacity(0.6) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 0
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EditCategorySheet(
        category: Category(name: "仕事", icon: .briefcase, color: .blue),
        taskStore: TaskStore()
    )
    .preferredColorScheme(.dark)
}
