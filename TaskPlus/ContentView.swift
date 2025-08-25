//
//  ContentView.swift
//  TaskPlus
//
//  Created by del mar y el sol on 2025/08/24.
//

import SwiftUI
import UserNotifications
import UIKit

struct ContentView: View {
    @StateObject private var taskStore = TaskStore()
    @StateObject private var guideManager = GuideModeManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingTutorial = false
    
    var body: some View {
        TabView {
            InboxView(taskStore: taskStore, guideManager: guideManager)
                .tabItem {
                    Image(systemName: "tray")
                    Text("Inbox")
                }
            
            TodayView(taskStore: taskStore, guideManager: guideManager)
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Today")
                }
            
            SettingsView(guideManager: guideManager, taskStore: taskStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
        }
        .accentColor(TaskPlusTheme.colors.neonPrimary)
        .preferredColorScheme(.dark)
        .onAppear {
            // 初回起動時はチュートリアルを表示
            if guideManager.isFirstTimeUser {
                showingTutorial = true
            }
            
            // 通知の許可を要求
            requestNotificationPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // アプリがアクティブになったタイミングでバッジをクリア
            print("App became active - clearing badge")
            notificationManager.clearBadge()
        }
        .sheet(isPresented: $showingTutorial) {
            TutorialView(guideManager: guideManager, taskStore: taskStore)
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            await notificationManager.requestNotificationPermission()
        }
    }
}

#Preview {
    ContentView()
}
