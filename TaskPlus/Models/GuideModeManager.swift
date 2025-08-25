import Foundation
import SwiftUI

@MainActor
class GuideModeManager: ObservableObject {
    @AppStorage("guideMode.enabled") var isEnabled: Bool = true
    @AppStorage("guideMode.tutorialCompleted") var tutorialCompleted: Bool = false
    @AppStorage("guideMode.firstLaunch") var isFirstLaunch: Bool = true
    
    // 現在のステップ（0-4）
    @Published var currentStep: Int = 0
    
    // ガイドモードの5ステップ
    let steps = [
        GuideStep(id: 0, title: "書き出す", description: "頭の中をInboxに入れる", icon: "tray"),
        GuideStep(id: 1, title: "整理する", description: "スワイプで今日やるものに移す", icon: "arrow.right.circle"),
        GuideStep(id: 2, title: "準備する", description: "重要度やタグをつける", icon: "tag"),
        GuideStep(id: 3, title: "集中する", description: "Focusで取りかかる", icon: "bolt.fill"),
        GuideStep(id: 4, title: "振り返る", description: "終わったタスクを見直す", icon: "checkmark.circle")
    ]
    
    // ガイドモードを無効化
    func disableGuideMode() {
        isEnabled = false
    }
    
    // ガイドモードを有効化
    func enableGuideMode() {
        isEnabled = true
    }
    
    // チュートリアル完了
    func completeTutorial() {
        tutorialCompleted = true
        isFirstLaunch = false
    }
    
    // 次のステップに進む
    func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        }
    }
    
    // 前のステップに戻る
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    // 特定のステップに移動
    func goToStep(_ step: Int) {
        if step >= 0 && step < steps.count {
            currentStep = step
        }
    }
    
    // ガイドモードが表示されるべきかチェック
    var shouldShowGuide: Bool {
        return isEnabled && !tutorialCompleted
    }
    
    // 初回起動かチェック
    var isFirstTimeUser: Bool {
        return isFirstLaunch
    }
}

// ガイドステップの構造体
struct GuideStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
}

// ガイドモードの状態
enum GuideState {
    case welcome
    case step1 // 書き出す
    case step2 // 整理する
    case step3 // 準備する
    case step4 // 集中する
    case step5 // 振り返る
    case completed
}
