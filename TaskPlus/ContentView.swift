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
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        TabView {
            InboxView(taskStore: taskStore)
                .tabItem {
                    Image(systemName: "tray")
                    Text("Inbox")
                }
            
            TodayView(taskStore: taskStore)
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Today")
                }
            
            SettingsView(taskStore: taskStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
        }
        .accentColor(TaskPlusTheme.colors.neonPrimary)
        .preferredColorScheme(.dark)
        .onAppear {
            // 通知の許可を要求
            requestNotificationPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // アプリがアクティブになったタイミングでバッジをクリア
            print("App became active - clearing badge")
            notificationManager.clearBadge()
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
