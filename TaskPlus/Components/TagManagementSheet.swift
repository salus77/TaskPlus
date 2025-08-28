import SwiftUI

struct TagManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskStore: TaskStore
    @State private var newTagName = ""
    @State private var editingTag: String?
    @State private var editingTagName = ""
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 新しいタグ追加セクション
                VStack(spacing: 16) {
                    HStack {
                        TextField("タグ名（#は自動追加）", text: $newTagName)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        Button("追加") {
                            addNewTag()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(TaskPlusTheme.colors.neonPrimary)
                        )
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    

                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 既存タグ一覧
                List {
                    ForEach(taskStore.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            
                            Spacer()
                            
                            if editingTag == tag {
                                // 編集モード
                                HStack(spacing: 8) {
                                    TextField("タグ名", text: $editingTagName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 120)
                                    
                                    Button("保存") {
                                        saveTagEdit()
                                    }
                                    .foregroundColor(TaskPlusTheme.colors.success)
                                    .font(.caption)
                                    
                                    Button("キャンセル") {
                                        cancelTagEdit()
                                    }
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                    .font(.caption)
                                }
                            } else {
                                // 通常モード
                                HStack(spacing: 8) {
                                    Button("編集") {
                                        startTagEdit(tag)
                                    }
                                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                                    .font(.caption)
                                    
                                    Button("削除") {
                                        tagToDelete = tag
                                        showingDeleteAlert = true
                                    }
                                    .foregroundColor(TaskPlusTheme.colors.danger)
                                    .font(.caption)
                                }
                            }
                        }
                        .listRowBackground(TaskPlusTheme.colors.surface)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(TaskPlusTheme.colors.bg)
            .navigationTitle("タグ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                }
            }
            .alert("タグを削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    if let tag = tagToDelete {
                        taskStore.removeTag(tag)
                    }
                }
            } message: {
                Text("このタグを使用しているタスクからも削除されます。この操作は取り消せません。")
            }
        }
    }
    
    private func addNewTag() {
        let trimmedTag = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty {
            // #で始まっていない場合は自動的に追加
            let finalTag = trimmedTag.hasPrefix("#") ? trimmedTag : "#\(trimmedTag)"
            taskStore.addTag(finalTag)
            newTagName = ""
        }
    }
    
    private func startTagEdit(_ tag: String) {
        editingTag = tag
        editingTagName = tag
    }
    
    private func saveTagEdit() {
        if let oldTag = editingTag {
            taskStore.updateTag(oldTag, to: editingTagName)
            editingTag = nil
            editingTagName = ""
        }
    }
    
    private func cancelTagEdit() {
        editingTag = nil
        editingTagName = ""
    }
}



#Preview {
    TagManagementSheet(taskStore: TaskStore())
}
