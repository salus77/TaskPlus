//
//  TaskPlusWidget.swift
//  TaskPlusWidget
//
//  Created by del mar y el sol on 2025/08/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), todayTasks: 5, completedTasks: 3, totalTasks: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let entry = TaskEntry(date: Date(), todayTasks: 5, completedTasks: 3, totalTasks: 8)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TaskEntry] = []

        // 現在の日付を取得
        let currentDate = Date()
        
        // 今日のタスクデータを取得（実際のアプリからデータを取得する場合はここで実装）
        let todayTasks = 5
        let completedTasks = 3
        let totalTasks = 8
        
        // 1時間ごとに更新
        for hourOffset in 0 ..< 24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = TaskEntry(date: entryDate, todayTasks: todayTasks, completedTasks: completedTasks, totalTasks: totalTasks)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let todayTasks: Int
    let completedTasks: Int
    let totalTasks: Int
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var progressPercentage: Int {
        return Int(completionRate * 100)
    }
}

struct TaskPlusWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    var entry: TaskEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("今日のタスク")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.completedTasks)/\(entry.totalTasks)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("完了")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ProgressView(value: entry.completionRate)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    var entry: TaskEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("今日の進捗")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.completedTasks) / \(entry.totalTasks) タスク完了")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("完了率: \(entry.progressPercentage)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: entry.completionRate)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(entry.progressPercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    var entry: TaskEntry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("今日のタスク管理")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("完了済み")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(entry.completedTasks)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("残り")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(entry.totalTasks - entry.completedTasks)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("進捗")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(entry.progressPercentage)%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: entry.completionRate)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
            }
            
            Spacer()
            
            Text("TaskPlus")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct TaskPlusWidget: Widget {
    let kind: String = "TaskPlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TaskPlusWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TaskPlusWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("TaskPlus ウィジェット")
        .description("今日のタスク進捗を表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    TaskPlusWidget()
} timeline: {
    TaskEntry(date: .now, todayTasks: 5, completedTasks: 3, totalTasks: 8)
    TaskEntry(date: .now, todayTasks: 3, completedTasks: 3, totalTasks: 6)
}

#Preview(as: .systemMedium) {
    TaskPlusWidget()
} timeline: {
    TaskEntry(date: .now, todayTasks: 5, completedTasks: 3, totalTasks: 8)
}

#Preview(as: .systemLarge) {
    TaskPlusWidget()
} timeline: {
    TaskEntry(date: .now, todayTasks: 5, completedTasks: 3, totalTasks: 8)
}
