import SwiftUI

struct ConciergeCard: View {
    let message: String
    let icon: String
    let actionText: String?
    let onAction: (() -> Void)?
    
    init(message: String, icon: String, actionText: String? = nil, onAction: (() -> Void)? = nil) {
        self.message = message
        self.icon = icon
        self.actionText = actionText
        self.onAction = onAction
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(TaskPlusTheme.colors.neonAccent)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(TaskPlusTheme.colors.neonAccent.opacity(0.2))
                )
            
            // メッセージ
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                if let actionText = actionText {
                    Text(actionText)
                        .font(.caption)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            // アクションボタン
            if let onAction = onAction, let actionText = actionText {
                Button(action: onAction) {
                    Text("やってみる")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(TaskPlusTheme.colors.neonPrimary.opacity(0.2))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(TaskPlusTheme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(TaskPlusTheme.colors.neonAccent.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// コンシェルジュカードのファクトリー
struct ConciergeCardFactory {
    static func createCard(for context: ConciergeContext, taskStore: TaskStore) -> ConciergeCard? {
        switch context {
        case .emptyInbox:
            return ConciergeCard(
                message: "頭の中を整理してみましょう",
                icon: "plus.circle",
                actionText: "新しいタスクを追加して、まずは書き出してみてください"
            ) {
                // タスク追加シートを表示する処理
            }
            
        case .inboxNotEmptyButTodayEmpty:
            return ConciergeCard(
                message: "今日やることを選んでみませんか？",
                icon: "arrow.right.circle",
                actionText: "Inboxのタスクを右にスワイプして、今日やるものに移動させてください"
            ) {
                // ガイドの次のステップに進む
            }
            
        case .todayHasTasks:
            return ConciergeCard(
                message: "どれから始めますか？",
                icon: "bolt.fill",
                actionText: "タスクをタップして詳細を確認し、集中モードに入りましょう！"
            ) {
                // 集中モードの説明
            }
            
        case .tasksCompleted:
            return ConciergeCard(
                message: "素晴らしい進歩です！",
                icon: "checkmark.circle.fill",
                actionText: "完了したタスクを振り返って、明日の計画を立ててみましょう"
            ) {
                // 振り返りの説明
            }
            
        case .welcome:
            return ConciergeCard(
                message: "Task Plusへようこそ！",
                icon: "hand.wave",
                actionText: "GTDの流れに沿って、やることを整理していきましょう"
            ) {
                // チュートリアル開始
            }
        }
    }
}

// コンシェルジュカードの表示コンテキスト
enum ConciergeContext {
    case emptyInbox
    case inboxNotEmptyButTodayEmpty
    case todayHasTasks
    case tasksCompleted
    case welcome
}

#Preview {
    VStack(spacing: 16) {
        ConciergeCard(
            message: "今日やることを選んでみませんか？",
            icon: "arrow.right.circle",
            actionText: "Inboxのタスクを右にスワイプして、今日やるものに移動させてください"
        ) {
            print("アクション実行")
        }
        
        ConciergeCard(
            message: "頭の中を整理してみましょう",
            icon: "plus.circle"
        )
    }
    .padding()
    .background(TaskPlusTheme.colors.bg)
}
