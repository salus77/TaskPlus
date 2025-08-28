import Foundation
import SwiftUI

// MARK: - Generic Data Structure for FocusPlus Integration
struct TaskPlusData: Codable {
    var version: String = "1.0.0"
    var lastModified: Date = Date()
    var tasks: [TaskData]
    var categories: [CategoryData]
    var settings: [String: String]
    var metadata: [String: AnyCodable]
    
    init(tasks: [TaskData] = [], categories: [CategoryData] = [], settings: [String: String] = [:], metadata: [String: AnyCodable] = [:]) {
        self.tasks = tasks
        self.categories = categories
        self.settings = settings
        self.metadata = metadata
    }
}

// MARK: - Generic Task Data Structure
struct TaskData: Codable, Identifiable {
    var id: String
    var title: String
    var notes: String?
    var due: Date?
    var createdAt: Date
    var updatedAt: Date
    var status: String
    var priority: String
    var context: String
    var categoryId: String?
    var tags: [String]
    var estimatedTime: Int? // 分単位
    var actualTime: Int? // 分単位
    var focusSessions: [FocusSession]
    var customFields: [String: AnyCodable]
    
    init(id: String = UUID().uuidString, title: String, notes: String? = nil, due: Date? = nil, priority: String = "normal", context: String = "none", categoryId: String? = nil, tags: [String] = [], estimatedTime: Int? = nil, actualTime: Int? = nil, focusSessions: [FocusSession] = [], customFields: [String: AnyCodable] = [:]) {
        self.id = id
        self.title = title
        self.notes = notes
        self.due = due
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = "inbox" // 固定値で初期化
        self.priority = priority
        self.context = context
        self.categoryId = categoryId
        self.tags = tags
        self.estimatedTime = estimatedTime
        self.actualTime = actualTime
        self.focusSessions = focusSessions
        self.customFields = customFields
    }
}

// MARK: - Focus Session for FocusPlus Integration
struct FocusSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var startTime: Date
    var endTime: Date?
    var duration: Int? // 分単位
    var focusMode: String // "pomodoro", "deep_work", "custom"
    var notes: String?
    var interruptions: Int
    var energyLevel: Int? // 1-10
    var productivity: Int? // 1-10
    
    init(startTime: Date = Date(), endTime: Date? = nil, duration: Int? = nil, focusMode: String = "pomodoro", notes: String? = nil, interruptions: Int = 0, energyLevel: Int? = nil, productivity: Int? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.focusMode = focusMode
        self.notes = notes
        self.interruptions = interruptions
        self.energyLevel = energyLevel
        self.productivity = productivity
    }
}

// MARK: - Generic Category Data Structure
struct CategoryData: Codable, Identifiable {
    var id: String
    var name: String
    var icon: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    var description: String?
    var parentId: String?
    var sortOrder: Int
    var isActive: Bool
    var customFields: [String: AnyCodable]
    
    init(id: String = UUID().uuidString, name: String, icon: String = "folder", color: String = "blue", description: String? = nil, parentId: String? = nil, sortOrder: Int = 0, isActive: Bool = true, customFields: [String: AnyCodable] = [:]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
        self.description = description
        self.parentId = parentId
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.customFields = customFields
    }
}

// MARK: - AnyCodable for Flexible JSON Fields
struct AnyCodable: Codable, Hashable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let uint = try? container.decode(UInt.self) {
            self.value = uint
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let uint as UInt:
            try container.encode(uint)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
    
    // Hashable準拠のための実装
    func hash(into hasher: inout Hasher) {
        switch value {
        case let bool as Bool:
            hasher.combine(bool)
        case let int as Int:
            hasher.combine(int)
        case let uint as UInt:
            hasher.combine(uint)
        case let double as Double:
            hasher.combine(double)
        case let string as String:
            hasher.combine(string)
        case let array as [Any]:
            hasher.combine(array.count)
        case let dictionary as [String: Any]:
            hasher.combine(dictionary.count)
        default:
            hasher.combine(0)
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // 簡易的な比較実装
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
}

// MARK: - Legacy Models for Backward Compatibility
struct TaskItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var notes: String?
    var due: Date?
    var createdAt: Date
    var updatedAt: Date
    var status: TaskStatus
    var priority: TaskPriority
    var context: TaskContext
    var categoryId: UUID?
    var tags: [String] // タグの配列
    var sortOrder: Int // 並び替え順序を保存するフィールドを追加
    var notificationEnabled: Bool // 通知の有効/無効
    var notificationTime: Date? // 通知時刻（期限とは別に設定可能）
    var originalStatus: TaskStatus? // 完了前のステータスを記録
    var isRestoring: Bool = false // 復元時のアニメーション制御用

    
    init(title: String, notes: String? = nil, due: Date? = nil, priority: TaskPriority = .normal, context: TaskContext = .none, categoryId: UUID? = nil, tags: [String] = [], sortOrder: Int = 0, notificationEnabled: Bool = true, notificationTime: Date? = nil) {
        self.id = UUID()  // 初期化時に一度だけUUIDを生成
        self.title = title
        self.notes = notes
        self.due = due
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = .inbox
        self.priority = priority
        self.context = context
        self.categoryId = categoryId
        self.tags = tags
        self.sortOrder = sortOrder
        self.notificationEnabled = notificationEnabled
        self.notificationTime = notificationTime
        self.originalStatus = nil
    }
    
    // 既存のタスクをコピーするためのイニシャライザ
    init(copying task: TaskItem, withNewStatus status: TaskStatus? = nil) {
        self.id = task.id  // 既存のIDを保持
        self.title = task.title
        self.notes = task.notes
        self.due = task.due
        self.createdAt = task.createdAt
        self.updatedAt = Date()
        self.status = status ?? task.status
        self.priority = task.priority
        self.context = task.context
        self.categoryId = task.categoryId
        self.tags = task.tags
        self.sortOrder = task.sortOrder
        self.notificationEnabled = task.notificationEnabled
        self.notificationTime = task.notificationTime
        self.originalStatus = task.originalStatus
        self.isRestoring = task.isRestoring
    }
    
    // Convert to generic TaskData
    func toTaskData() -> TaskData {
        return TaskData(
            id: id.uuidString,
            title: title,
            notes: notes,
            due: due,
            priority: priority.rawValue,
            context: context.rawValue,
            categoryId: categoryId?.uuidString,
            tags: tags,
            estimatedTime: nil,
            actualTime: nil,
            focusSessions: [],
            customFields: [:]
        )
    }
}

struct Category: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: CategoryIcon
    var color: CategoryColor
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, icon: CategoryIcon = .briefcase, color: CategoryColor = .blue) {
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Convert to generic CategoryData
    func toCategoryData() -> CategoryData {
        return CategoryData(
            id: id.uuidString,
            name: name,
            icon: icon.rawValue,
            color: color.rawValue,
            description: nil,
            parentId: nil,
            sortOrder: 0,
            isActive: true,
            customFields: [:]
        )
    }
}

// MARK: - Enums for Backward Compatibility
enum TaskStatus: String, CaseIterable {
    case inbox = "inbox"
    case today = "today"
    case done = "done"
    case deleted = "deleted"
}



enum TaskPriority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    
    var rawValue: String {
        switch self {
        case .low: return "low"
        case .normal: return "normal"
        case .high: return "high"
        }
    }
    
    var priorityValue: Int {
        switch self {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .normal: return "普通"
        case .high: return "高"
        }
    }
}

enum TaskContext: String, CaseIterable {
    case none = "none"
    case home = "home"
    case work = "work"
    case call = "call"
    case errand = "errand"
    
    var displayName: String {
        switch self {
        case .none: return "なし"
        case .home: return "家"
        case .work: return "仕事"
        case .call: return "電話"
        case .errand: return "外出"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .none: return ""
        case .home: return "house"
        case .work: return "laptopcomputer"
        case .call: return "phone.fill"
        case .errand: return "figure.walk"
        }
    }
}

// MARK: - Category Icon (Legacy)
enum CategoryIcon: String, CaseIterable {
    case folder = "folder"
    case briefcase = "briefcase"
    case book = "book"
    case graduationcap = "graduationcap"
    case house = "house"
    case car = "car"
    case gamecontroller = "gamecontroller"
    case heart = "heart"
    case star = "star"
    case leaf = "leaf"
    case flame = "flame"
    case drop = "drop"
    case bolt = "bolt"
    case cloud = "cloud"
    
    var systemName: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .folder: return "フォルダ"
        case .briefcase: return "ブリーフケース"
        case .book: return "本"
        case .graduationcap: return "卒業帽"
        case .house: return "家"
        case .car: return "車"
        case .gamecontroller: return "ゲーム"
        case .heart: return "ハート"
        case .star: return "星"
        case .leaf: return "葉"
        case .flame: return "炎"
        case .drop: return "水滴"
        case .bolt: return "稲妻"
        case .cloud: return "雲"
        }
    }
}

// MARK: - Category Color (Legacy)
enum CategoryColor: String, CaseIterable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case cyan = "cyan"
    case teal = "teal"
    case indigo = "indigo"
    case brown = "brown"
    
    var color: Color {
        switch self {
        case .blue: return Color(hex: "007AFF")
        case .green: return Color(hex: "34C759")
        case .orange: return Color(hex: "FF9500")
        case .red: return Color(hex: "FF3B30")
        case .purple: return Color(hex: "AF52DE")
        case .pink: return Color(hex: "FF2D92")
        case .yellow: return Color(hex: "FFCC00")
        case .cyan: return Color(hex: "5AC8FA")
        case .teal: return Color(hex: "5AC8FA")
        case .indigo: return Color(hex: "5856D6")
        case .brown: return Color(hex: "A2845E")
        }
    }
    
    var displayName: String {
        switch self {
        case .blue: return "青"
        case .green: return "緑"
        case .orange: return "オレンジ"
        case .red: return "赤"
        case .purple: return "紫"
        case .pink: return "ピンク"
        case .yellow: return "黄"
        case .cyan: return "水色"
        case .teal: return "ターコイズ"
        case .indigo: return "青紫"
        case .brown: return "茶"
        }
    }
}
