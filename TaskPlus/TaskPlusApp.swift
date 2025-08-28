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
    @StateObject private var taskStore = TaskStore()
    @State private var showingDailyReview = false
    @State private var showingWeeklyReview = false
    @State private var dailyReviewTimer: Timer?
    @State private var weeklyReviewTimer: Timer?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .environmentObject(taskStore)
                .onAppear {
                    // アプリ起動時にレガシーデータの移行を実行
                    persistenceController.migrateFromLegacyModels()
                    
                    // 通知許可を要求
                    Task {
                        await notificationManager.requestNotificationPermission()
                    }
                    
                    // デイリーレビューとウィークリーレビューのタイマーを設定
                    setupDailyReviewTimer()
                    setupWeeklyReviewTimer()
                }
                .sheet(isPresented: $showingDailyReview) {
                    DailyReviewView(taskStore: taskStore)
                }
                .sheet(isPresented: $showingWeeklyReview) {
                    WeeklyReviewView(taskStore: taskStore)
                }
        }
    }
    
    // MARK: - Daily Review Timer
    private func setupDailyReviewTimer() {
        // 毎分チェックして、設定された時間になったらデイリーレビューを表示
        dailyReviewTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            checkDailyReviewTime()
        }
    }
    
    private func checkDailyReviewTime() {
        guard notificationManager.notificationSettings.dailySummaryEnabled else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let scheduledTime = calendar.dateComponents([.hour, .minute], from: notificationManager.notificationSettings.dailySummaryTime)
        
        if currentTime.hour == scheduledTime.hour && currentTime.minute == scheduledTime.minute {
            DispatchQueue.main.async {
                showingDailyReview = true
            }
        }
    }
    
    // MARK: - Weekly Review Timer
    private func setupWeeklyReviewTimer() {
        // 毎分チェックして、設定された曜日・時間になったらウィークリーレビューを表示
        weeklyReviewTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            checkWeeklyReviewTime()
        }
    }
    
    private func checkWeeklyReviewTime() {
        guard notificationManager.notificationSettings.weeklyReviewEnabled else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let currentWeekday = calendar.component(.weekday, from: now) - 1 // 0=日曜日, 1=月曜日, ..., 6=土曜日
        let scheduledTime = calendar.dateComponents([.hour, .minute], from: notificationManager.notificationSettings.weeklyReviewTime)
        let scheduledWeekday = notificationManager.notificationSettings.weeklyReviewDay
        
        if currentWeekday == scheduledWeekday && 
           currentTime.hour == scheduledTime.hour && 
           currentTime.minute == scheduledTime.minute {
            DispatchQueue.main.async {
                showingWeeklyReview = true
            }
        }
    }
}
