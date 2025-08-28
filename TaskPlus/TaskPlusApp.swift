//
//  TaskPlusApp.swift
//  TaskPlus
//
//  Created by del mar y el sol on 2025/08/24.
//

import SwiftUI

@main
struct TaskPlusApp: App {
    @StateObject private var persistenceController = TaskPlusPersistenceController.shared
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .onAppear {
                    // アプリ起動時にレガシーデータの移行を実行
                    persistenceController.migrateFromLegacyModels()
                    
                    // 通知許可を要求
                    Task {
                        await notificationManager.requestNotificationPermission()
                    }
                }
        }
    }
}
