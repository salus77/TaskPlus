import SwiftUI

struct DailyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskStore: TaskStore
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 16) {
                    Text("デイリーレビュー")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.title3)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // タブ選択
                Picker("レビュータイプ", selection: $selectedTab) {
                    Text("今日の振り返り").tag(0)
                    Text("明日の計画").tag(1)
                    Text("全体の進捗").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // タブコンテンツ
                TabView(selection: $selectedTab) {
                    // 今日の振り返り
                    todayReviewTab
                        .tag(0)
                    
                    // 明日の計画
                    tomorrowPlanTab
                        .tag(1)
                    
                    // 全体の進捗
                    overallProgressTab
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
    
    // MARK: - 今日の振り返りタブ
    private var todayReviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 統計カード（グリッドレイアウト）
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCardView(
                        title: "完了タスク",
                        value: "\(completedTasksCount)",
                        subtitle: "今日完了",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        trend: nil
                    )
                    
                    StatCardView(
                        title: "未完了",
                        value: "\(incompleteTasks.count)",
                        subtitle: "残りタスク",
                        icon: "clock",
                        color: .orange,
                        trend: nil
                    )
                }
                
                // カテゴリ別進捗（円グラフ付き）
                if !completedTasks.isEmpty {
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
                                data: categoryChartData,
                                size: 120
                            )
                            
                            // 凡例
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(categoryChartData.enumerated()), id: \.offset) { index, item in
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
                
                // 時間帯別完了数（棒グラフ）
                if !completedTasks.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            Text("時間帯別完了数")
                                .font(.headline)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            Spacer()
                        }
                        
                        BarChartView(
                            data: hourlyChartData,
                            maxValue: hourlyChartData.map { $0.1 }.max() ?? 1,
                            barColor: TaskPlusTheme.colors.neonPrimary,
                            height: 100
                        )
                    }
                    .padding()
                    .background(TaskPlusTheme.colors.surface)
                    .cornerRadius(16)
                }
                
                // 完了タスク一覧
                if !completedTasks.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            Text("完了したタスク")
                                .font(.headline)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            Spacer()
                        }
                        
                        LazyVStack(spacing: 12) {
                            ForEach(completedTasks) { task in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(task.title)
                                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                                    Spacer()
                                    if let categoryId = task.categoryId,
                                       let category = taskStore.categories.first(where: { $0.id == categoryId }) {
                                        Text(category.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(TaskPlusTheme.colors.neonAccent.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(TaskPlusTheme.colors.surface)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 明日の計画タブ
    private var tomorrowPlanTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 明日のタスク数
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(TaskPlusTheme.colors.neonPrimary)
                            .font(.title2)
                        Text("明日のタスク")
                            .font(.headline)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(tomorrowTasksCount)")
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
                            count: highPriorityCount,
                            color: .red,
                            icon: "exclamationmark.triangle.fill"
                        )
                        
                        priorityDistributionCard(
                            title: "中",
                            count: mediumPriorityCount,
                            color: .orange,
                            icon: "exclamationmark.circle.fill"
                        )
                        
                        priorityDistributionCard(
                            title: "低",
                            count: lowPriorityCount,
                            color: .blue,
                            icon: "info.circle.fill"
                        )
                    }
                }
                .padding()
                .background(TaskPlusTheme.colors.surface)
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    // MARK: - 全体の進捗タブ
    private var overallProgressTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 今週の進捗
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(TaskPlusTheme.colors.neonAccent)
                            .font(.title2)
                        Text("今週の進捗")
                            .font(.headline)
                            .foregroundColor(TaskPlusTheme.colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(weeklyCompletionRate, specifier: "%.1f")")
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
                
                // カテゴリ別の進捗
                VStack(spacing: 16) {
                    Text("カテゴリ別の進捗")
                        .font(.headline)
                        .foregroundColor(TaskPlusTheme.colors.textPrimary)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(categoryProgress, id: \.category) { progress in
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
    
    // カテゴリ別チャートデータ
    private var categoryChartData: [(String, Double, Color)] {
        let categoryCounts = Dictionary(grouping: completedTasks) { task in
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
    
    // 時間帯別チャートデータ
    private var hourlyChartData: [(String, Double)] {
        let hourCounts = Dictionary(grouping: completedTasks) { task in
            let hour = Calendar.current.component(.hour, from: task.updatedAt)
            return "\(hour):00"
        }
        
        let sortedHours = hourCounts.sorted { hour1, hour2 in
            let hour1Value = Int(hour1.key.split(separator: ":")[0]) ?? 0
            let hour2Value = Int(hour2.key.split(separator: ":")[0]) ?? 0
            return hour1Value < hour2Value
        }
        
        return sortedHours.map { (hour, tasks) in
            (hour, Double(tasks.count))
        }
    }
    
    private var completedTasks: [TaskItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status == .done && 
            Calendar.current.isDate(task.updatedAt, inSameDayAs: today)
        }
    }
    
    private var completedTasksCount: Int {
        completedTasks.count
    }
    
    private var incompleteTasks: [TaskItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done && 
            task.due != nil && Calendar.current.isDate(task.due!, inSameDayAs: today)
        }
    }
    
    private var tomorrowTasksCount: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowStart = Calendar.current.startOfDay(for: tomorrow)
        let tomorrowEnd = Calendar.current.date(byAdding: .day, value: 1, to: tomorrowStart) ?? tomorrow
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done && 
            task.due != nil && task.due! >= tomorrowStart && task.due! < tomorrowEnd
        }.count
    }
    
    private var highPriorityCount: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowStart = Calendar.current.startOfDay(for: tomorrow)
        let tomorrowEnd = Calendar.current.date(byAdding: .day, value: 1, to: tomorrowStart) ?? tomorrow
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done && 
            task.due != nil && task.due! >= tomorrowStart && task.due! < tomorrowEnd &&
            task.priority == .high
        }.count
    }
    
    private var mediumPriorityCount: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowStart = Calendar.current.startOfDay(for: tomorrow)
        let tomorrowEnd = Calendar.current.date(byAdding: .day, value: 1, to: tomorrowStart) ?? tomorrow
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done && 
            task.due != nil && task.due! >= tomorrowStart && task.due! < tomorrowEnd &&
            task.priority == .normal
        }.count
    }
    
    private var lowPriorityCount: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowStart = Calendar.current.startOfDay(for: tomorrow)
        let tomorrowEnd = Calendar.current.date(byAdding: .day, value: 1, to: tomorrowStart) ?? tomorrow
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        return allTasks.filter { task in
            task.status != .done && 
            task.due != nil && task.due! >= tomorrowStart && task.due! < tomorrowEnd &&
            task.priority == .low
        }.count
    }
    
    private var weeklyCompletionRate: Double {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        let weekTasks = allTasks.filter { task in
            task.due != nil && task.due! >= weekStart && task.due! < weekEnd
        }
        
        let completedWeekTasks = weekTasks.filter { $0.status == .done }
        
        guard !weekTasks.isEmpty else { return 0.0 }
        return Double(completedWeekTasks.count) / Double(weekTasks.count) * 100.0
    }
    
    private var categoryProgress: [CategoryProgress] {
        let allTasks = taskStore.inboxTasks + taskStore.todayTasks + taskStore.doneTasks
        
        return taskStore.categories.map { category in
            let categoryTasks = allTasks.filter { $0.categoryId == category.id }
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
}



#Preview {
    DailyReviewView(taskStore: TaskStore())
}
