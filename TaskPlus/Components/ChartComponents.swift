import SwiftUI

// MARK: - 円グラフ
struct PieChartView: View {
    let data: [(String, Double, Color)]
    let size: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                PieSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    color: item.2
                )
            }
        }
        .frame(width: size, height: size)
    }
    
    private func startAngle(for index: Int) -> Double {
        let previousValues = data.prefix(index).map { $0.1 }
        let total = data.reduce(0) { $0 + $1.1 }
        let previousSum = previousValues.reduce(0, +)
        return (previousSum / total) * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        let previousValues = data.prefix(index + 1).map { $0.1 }
        let total = data.reduce(0) { $0 + $1.1 }
        let previousSum = previousValues.reduce(0, +)
        return (previousSum / total) * 360
    }
}

struct PieSlice: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    
    var body: some View {
        Path { path in
            path.move(to: .zero)
            path.addArc(center: .zero, radius: 1, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
            path.closeSubpath()
        }
        .fill(color)
        .scaleEffect(0.5)
    }
}

// MARK: - 棒グラフ
struct BarChartView: View {
    let data: [(String, Double)]
    let maxValue: Double
    let barColor: Color
    let height: CGFloat
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(barColor)
                        .frame(width: 20, height: (item.1 / maxValue) * height)
                        .cornerRadius(4)
                    
                    Text(item.0)
                        .font(.caption2)
                        .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        .rotationEffect(.degrees(-45))
                        .offset(y: 8)
                }
            }
        }
        .frame(height: height + 30)
    }
}

// MARK: - プログレスバー
struct ProgressBarView: View {
    let progress: Double
    let title: String
    let color: Color
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(TaskPlusTheme.colors.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(TaskPlusTheme.colors.surface)
                        .frame(height: height)
                        .cornerRadius(height / 2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: height)
                        .cornerRadius(height / 2)
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - スパークライン
struct SparklineView: View {
    let data: [Double]
    let color: Color
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue
                
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - ((value - minValue) / range) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            .frame(height: height)
        }
        .frame(height: height)
    }
}

// MARK: - 統計カード
struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: Double? // 前日比の変化率
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(trend >= 0 ? .green : .red)
                            .font(.caption)
                        Text("\(abs(Int(trend)))%")
                            .font(.caption)
                            .foregroundColor(trend >= 0 ? .green : .red)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((trend >= 0 ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(4)
                }
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(TaskPlusTheme.colors.textPrimary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(TaskPlusTheme.colors.textPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(TaskPlusTheme.colors.textSecondary)
        }
        .padding()
        .background(TaskPlusTheme.colors.surface)
        .cornerRadius(16)
    }
}

// MARK: - カテゴリ別進捗
struct CategoryProgressView: View {
    let categoryProgress: [(String, Int, Int)] // カテゴリ名、完了数、総数
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カテゴリ別進捗")
                .font(.headline)
                .foregroundColor(TaskPlusTheme.colors.textPrimary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(categoryProgress.enumerated()), id: \.offset) { index, item in
                    let progress = item.2 > 0 ? Double(item.1) / Double(item.2) : 0.0
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.0)
                                .font(.subheadline)
                                .foregroundColor(TaskPlusTheme.colors.textPrimary)
                            Spacer()
                            Text("\(item.1)/\(item.2)")
                                .font(.caption)
                                .foregroundColor(TaskPlusTheme.colors.textSecondary)
                        }
                        
                        ProgressBarView(
                            progress: progress,
                            title: "",
                            color: TaskPlusTheme.colors.neonPrimary,
                            height: 6
                        )
                    }
                }
            }
        }
        .padding()
        .background(TaskPlusTheme.colors.surface)
        .cornerRadius(16)
    }
}
