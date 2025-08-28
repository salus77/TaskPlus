import SwiftUI

struct WeeklyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskStore: TaskStore
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 16) {
                    Text("ウィークリーレビュー")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    Text("今週の振り返りと来週の計画")
                        .font(.title3)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // タブ選択
                Picker("レビュータイプ", selection: $selectedTab) {
                    Text("今週の振り返り").tag(0)
                    Text("来週の計画").tag(1)
                    Text("月間の進捗").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // タブコンテンツ
                TabView(selection: $selectedTab) {
                    // 今週の振り返り
                    thisWeekReviewTab
                        .tag(0)
                    
                    // 来週の計画
                    nextWeekPlanTab
                        .tag(1)
                    
                    // 月間の進捗
                    monthlyProgressTab
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                
                Spacer()
                
                // 完了ボタン
                Button(action: {
                    dismiss()
                }) {
                    Text("完了")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(TaskPlusTheme.colors.neonPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(TaskPlusTheme.colors.bg)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 今週の振り返りタブ
    private var thisWeekReviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 統計カード（グリッドレイアウト）
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCardView(
                        title: "今週完了",
                        value: "\(thisWeekCompletedTasksCount)",
                        subtitle: "タスク数",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        trend: weeklyTrend
                    )
                    
                    StatCardView(
                        title: "今週作成",
                        value: "\(thisWeekCreatedTasksCount)",
                        subtitle: "新規タスク",
                        icon: "plus.circle.fill",
                        color: TaskPlusTheme.colors.neonPrimary,
                        trend: nil
                    )
                }
                
                // 週間の進捗推移（スパークライン）
                VStack(spacing: 16) {
                    HStack {
                        Text("週間の進捗推移")
                            .font(.headline)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack {
                        SparklineView(
                            data: weeklyProgressDataForSparkline,
                            color: TaskPlusTheme.colors.neonPrimary,
                            height: 60
                        )
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("今週の完了数")
                                .font(.caption)
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                            Text("\(thisWeekCompletedTasksCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        }
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
                
                // カテゴリ別進捗（円グラフ付き）
                if !thisWeekCompletedTasks.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            Text("カテゴリ別完了率")
                                .font(.headline)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            // 円グラフ
                            PieChartView(
                                data: weeklyCategoryChartData,
                                size: 120
                            )
                            
                            // 凡例
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(weeklyCategoryChartData.enumerated()), id: \.offset) { index, item in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(item.2)
                                            .frame(width: 12, height: 12)
                                        Text(item.0)
                                            .font(.caption)
                                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                        Text("\(Int(item.1))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(TaskPlusTheme.colors.surface)
                    .cornerRadius(16)
                }
                
                // 日別完了数（棒グラフ）
                VStack(spacing: 16) {
                    HStack {
                        Text("日別完了数")
                            .font(.headline)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        Spacer()
                    }
                    
                    BarChartView(
                        data: dailyChartData,
                        maxValue: dailyChartData.map { $0.1 }.max() ?? 1,
                        barColor: TaskPlusTheme.colors.neonPrimary,
                        height: 120
                    )
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
                
                // 日別の完了タスク数
                VStack(spacing: 16) {
                    Text("日別の完了数")
                        .font(.headline)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(0..<7, id: \.self) { dayOffset in
                            let date = Calendar.current.date(byAdding: .day, value: dayOffset - 6, to: Date()) ?? Date()
                            let dayTasks = getCompletedTasksForDay(date)
                            
                            VStack(spacing: 8) {
                                Text(dayOfWeekString(from: date))
                                    .font(.caption)
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                Text("\(dayTasks.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TaskPlusTheme.colors.surface)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
                
                // カテゴリ別の進捗
                VStack(spacing: 16) {
                    Text("カテゴリ別の進捗")
                        .font(.headline)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(thisWeekCategoryProgress, id: \.category) { progress in
                            HStack {
                                Text(progress.category)
                                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                                Spacer()
                                Text("\(progress.completed)/\(progress.total)")
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                Text("(\(Int(progress.rate * 100))%)")
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                            }
                            .padding()
                            .background(TaskPlusTheme.colors.surface)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    // MARK: - 来週の計画タブ
    private var nextWeekPlanTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 来週のタスク数
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            .font(.title2)
                        Text("来週のタスク")
                            .font(.headline)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(nextWeekTasksCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                        Text("個")
                            .font(.title2)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Spacer()
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
                
                // 優先度別のタスク分布
                VStack(spacing: 16) {
                    Text("優先度別の分布")
                        .font(.headline)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    HStack(spacing: 20) {
                        priorityDistributionCard(
                            title: "高",
                            count: nextWeekHighPriorityCount,
                            color: .red,
                            icon: "exclamationmark.triangle.fill"
                        )
                        
                        priorityDistributionCard(
                            title: "中",
                            count: nextWeekMediumPriorityCount,
                            color: .orange,
                            icon: "exclamationmark.circle.fill"
                        )
                        
                        priorityDistributionCard(
                            title: "低",
                            count: nextWeekLowPriorityCount,
                            color: .blue,
                            icon: "info.circle.fill"
                        )
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
                
                // 日別のタスク分布
                VStack(spacing: 16) {
                    Text("日別のタスク分布")
                        .font(.headline)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(0..<7, id: \.self) { dayOffset in
                            let date = Calendar.current.date(byAdding: .day, value: dayOffset + 1, to: Date()) ?? Date()
                            let dayTasks = getTasksForDay(date)
                            
                            VStack(spacing: 8) {
                                Text(dayOfWeekString(from: date))
                                    .font(.caption)
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                Text("\(dayTasks.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TaskPlusTheme.colors.surface)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    // MARK: - 月間の進捗タブ
    private var monthlyProgressTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 今月の進捗
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            .font(.title2)
                        Text("今月の進捗")
                            .font(.headline)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(monthlyCompletionRate, specifier: "%.1f")")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                        Text("%")
                            .font(.title2)
                            .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        Spacer()
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
                
                // 週別の進捗
                VStack(spacing: 16) {
                    Text("週別の進捗")
                        .font(.headline)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(weeklyProgressData, id: \.week) { progress in
                            HStack {
                                Text(progress.week)
                                    .foregroundColor(TaskPlusTheme.colors.textPrimary)
                                Spacer()
                                Text("\(progress.completed)/\(progress.total)")
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                                Text("(\(Int(progress.rate * 100))%)")
                                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                            }
                            .padding()
                            .background(TaskPlusTheme.colors.surface)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    // MARK: - ヘルパービュー
    private func priorityDistributionCard(title: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text(title)
                .font(.caption)
                .foregroundColor(TaskPlusTheme.colors.textSecondary)
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(TaskPlusTheme.colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - 計算プロパティ
    
    // 週間のトレンド（前週比）
    private var weeklyTrend: Double? {
        let thisWeekCount = thisWeekCompletedTasksCount
        let lastWeekCount = lastWeekCompletedTasksCount
        guard lastWeekCount > 0 else { return nil }
        return ((Double(thisWeekCount - lastWeekCount) / Double(lastWeekCount)) * 100).rounded()
    }
    
    // 前週完了タスク数
    private var lastWeekCompletedTasksCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let lastWeekEnd = calendar.date(byAdding: .weekOfYear, value: 0, to: now) ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status == .done &&
            task.updatedAt >= lastWeekStart && task.updatedAt < lastWeekEnd
        }.count
    }
    
    // 今週作成タスク数
    private var thisWeekCreatedTasksCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.createdAt >= weekStart && task.createdAt < weekEnd
        }.count
    }
    
    // 週間の進捗データ（スパークライン用）
    private var weeklyProgressDataForSparkline: [Double] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? today
            let dayTasks = thisWeekCompletedTasks.filter { task in
                return calendar.isDate(task.updatedAt, inSameDayAs: date)
            }
            return Double(dayTasks.count)
        }
    }
    
    // 週間のカテゴリ別チャートデータ
    private var weeklyCategoryChartData: [(String, Double, Color)] {
        let categoryCounts = Dictionary(grouping: thisWeekCompletedTasks) { task in
            if let categoryId = task.categoryId,
               let category = taskStore.categories.first(where: { $0.id == categoryId }) {
                return category.name
            }
            return "未分類"
        }
        
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .yellow, .mint]
        
        return Array(categoryCounts.enumerated()).map { index, element in
            (element.key, Double(element.value.count), colors[index % colors.count])
        }
    }
    
    // 日別チャートデータ
    private var dailyChartData: [(String, Double)] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) ?? today
            let dayTasks = thisWeekCompletedTasks.filter { task in
                return calendar.isDate(task.updatedAt, inSameDayAs: date)
            }
            return (weekdays[dayOffset], Double(dayTasks.count))
        }
    }
    
    private var thisWeekCompletedTasksCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status == .done &&
            task.updatedAt >= weekStart && task.updatedAt < weekEnd
        }.count
    }
    
    private var thisWeekCompletedTasks: [TaskItem] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status == .done &&
            task.updatedAt >= weekStart && task.updatedAt < weekEnd
        }
    }
    
    private var nextWeekTasksCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        let nextWeekEnd = calendar.date(byAdding: .weekOfYear, value: 2, to: now) ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done &&
            task.due != nil && task.due! >= nextWeekStart && task.due! < nextWeekEnd
        }.count
    }
    
    private var nextWeekHighPriorityCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        let nextWeekEnd = calendar.date(byAdding: .weekOfYear, value: 2, to: now) ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done &&
            task.due != nil && task.due! >= nextWeekStart && task.due! < nextWeekEnd &&
            task.priority == .high
        }.count
    }
    
    private var nextWeekMediumPriorityCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        let nextWeekEnd = calendar.date(byAdding: .weekOfYear, value: 2, to: now) ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done &&
            task.due != nil && task.due! >= nextWeekStart && task.due! < nextWeekEnd &&
            task.priority == .normal
        }.count
    }
    
    private var nextWeekLowPriorityCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        let nextWeekEnd = calendar.date(byAdding: .weekOfYear, value: 2, to: now) ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done &&
            task.due != nil && task.due! >= nextWeekStart && task.due! < nextWeekEnd &&
            task.priority == .low
        }.count
    }
    
    private var monthlyCompletionRate: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        let monthTasks = allTasks.filter { task in
            task.due != nil && task.due! >= monthStart && task.due! < monthEnd
        }
        
        let completedMonthTasks = monthTasks.filter { $0.status == .done }
        
        guard !monthTasks.isEmpty else { return 0.0 }
        return Double(completedMonthTasks.count) / Double(monthTasks.count) * 100.0
    }
    
    private var thisWeekCategoryProgress: [CategoryProgress] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        let weekTasks = allTasks.filter { task in
            task.due != nil && task.due! >= weekStart && task.due! < weekEnd
        }
        
        return taskStore.categories.map { category in
            let categoryTasks = weekTasks.filter { $0.categoryId == category.id }
            let completedCategoryTasks = categoryTasks.filter { $0.status == .done }
            let rate = categoryTasks.isEmpty ? 0.0 : Double(completedCategoryTasks.count) / Double(categoryTasks.count)
            
            return CategoryProgress(
                category: category.name,
                total: categoryTasks.count,
                completed: completedCategoryTasks.count,
                rate: rate
            )
        }.sorted { $0.rate > $1.rate }
    }
    
    private var weeklyProgressData: [WeeklyProgress] {
        let calendar = Calendar.current
        let now = Date()
        let currentWeek = calendar.component(.weekOfYear, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        var weeklyData: [WeeklyProgress] = []
        
        for weekOffset in -3...0 {
            let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: now) ?? now
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.start ?? targetDate
            let weekEnd = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.end ?? targetDate
            
            let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
            let weekTasks = allTasks.filter { task in
                task.due != nil && task.due! >= weekStart && task.due! < weekEnd
            }
            
            let completedWeekTasks = weekTasks.filter { $0.status == .done }
            let rate = weekTasks.isEmpty ? 0.0 : Double(completedWeekTasks.count) / Double(weekTasks.count)
            
            let weekLabel = weekOffset == 0 ? "今週" : "\(weekOffset)週前"
            
            weeklyData.append(WeeklyProgress(
                week: weekLabel,
                total: weekTasks.count,
                completed: completedWeekTasks.count,
                rate: rate
            ))
        }
        
        return weeklyData
    }
    
    // MARK: - ヘルパー関数
    private func getCompletedTasksForDay(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status == .done &&
            task.updatedAt >= dayStart && task.updatedAt < dayEnd
        }
    }
    
    private func getTasksForDay(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done &&
            task.due != nil && task.due! >= dayStart && task.due! < dayEnd
        }
    }
    
    private func dayOfWeekString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - ヘルパー構造体
struct CategoryProgress {
    let category: String
    let total: Int
    let completed: Int
    let rate: Double
}

struct WeeklyProgress {
    let week: String
    let total: Int
    let completed: Int
    let rate: Double
}

#Preview {
    WeeklyReviewView(taskStore: TaskStore())
}
