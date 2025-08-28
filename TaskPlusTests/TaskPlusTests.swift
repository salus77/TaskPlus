//
//  TaskPlusTests.swift
//  TaskPlusTests
//
//  Created by del mar y el el sol on 2025/08/24.
//

import XCTest
import Combine
@testable import TaskPlus

@MainActor
class TaskPlusTests: XCTestCase {
    var taskStore: TaskStore!
    
    override func setUpWithError() throws {
        taskStore = TaskStore()
    }
    
    override func tearDownWithError() throws {
        taskStore = nil
    }
    
    // MARK: - タスク完了・復元の重複問題をデバッグするテスト
    
    func testTaskCompletionAndRestoreNoDuplication() throws {
        // 1. 初期状態の確認
        XCTAssertEqual(taskStore.inboxTasks.count, 0, "初期状態ではinboxTasksは空")
        XCTAssertEqual(taskStore.doneTasks.count, 0, "初期状態ではdoneTasksは空")
        
        // 2. タスクを追加
        let task = TaskItem(title: "テストタスク", priority: .normal)
        taskStore.addTask(task)
        
        XCTAssertEqual(taskStore.inboxTasks.count, 1, "タスク追加後、inboxTasksは1個")
        XCTAssertEqual(taskStore.doneTasks.count, 0, "タスク追加後、doneTasksは0個")
        
        // 3. タスクを完了
        let inboxTask = taskStore.inboxTasks.first!
        taskStore.completeTask(inboxTask)
        
        XCTAssertEqual(taskStore.inboxTasks.count, 0, "タスク完了後、inboxTasksは0個")
        XCTAssertEqual(taskStore.doneTasks.count, 1, "タスク完了後、doneTasksは1個")
        
        // 4. 完了済みタスクを復元
        let doneTask = taskStore.doneTasks.first!
        taskStore.restoreTask(doneTask)
        
        XCTAssertEqual(taskStore.inboxTasks.count, 1, "タスク復元後、inboxTasksは1個")
        XCTAssertEqual(taskStore.doneTasks.count, 0, "タスク復元後、doneTasksは0個")
        
        // 5. 重複チェック
        let allTaskIds = Set(taskStore.inboxTasks.map { $0.id } + taskStore.doneTasks.map { $0.id })
        let expectedTaskIds = Set([task.id])
        
        XCTAssertEqual(allTaskIds, expectedTaskIds, "タスクIDに重複がないことを確認")
        XCTAssertEqual(taskStore.inboxTasks.count + taskStore.doneTasks.count, 1, "総タスク数は1個")
    }
    
    func testMultipleTaskCompletionAndRestore() throws {
        // 1. 複数のタスクを追加
        let task1 = TaskItem(title: "タスク1", priority: .normal)
        let task2 = TaskItem(title: "タスク2", priority: .high)
        let task3 = TaskItem(title: "タスク3", priority: .low)
        
        taskStore.addTask(task1)
        taskStore.addTask(task2)
        taskStore.addTask(task3)
        
        XCTAssertEqual(taskStore.inboxTasks.count, 3, "3個のタスクを追加後、inboxTasksは3個")
        
        // 2. 順番にタスクを完了
        let inboxTask1 = taskStore.inboxTasks.first { $0.title == "タスク1" }!
        taskStore.completeTask(inboxTask1)
        
        XCTAssertEqual(taskStore.inboxTasks.count, 2, "1個目のタスク完了後、inboxTasksは2個")
        XCTAssertEqual(taskStore.doneTasks.count, 1, "1個目のタスク完了後、doneTasksは1個")
        
        // 3. 完了済みタスクを復元
        let doneTask1 = taskStore.doneTasks.first!
        taskStore.restoreTask(doneTask1)
        
        XCTAssertEqual(taskStore.inboxTasks.count, 3, "タスク復元後、inboxTasksは3個")
        XCTAssertEqual(taskStore.doneTasks.count, 0, "タスク復元後、doneTasksは0個")
        
        // 4. 重複チェック
        let allTaskIds = Set(taskStore.inboxTasks.map { $0.id } + taskStore.doneTasks.map { $0.id })
        let expectedTaskIds = Set([task1.id, task2.id, task3.id])
        
        XCTAssertEqual(allTaskIds, expectedTaskIds, "タスクIDに重複がないことを確認")
        XCTAssertEqual(taskStore.inboxTasks.count + taskStore.doneTasks.count, 3, "総タスク数は3個")
    }
    
    func testTaskStoreStateConsistency() throws {
        // 1. タスクを追加
        let task = TaskItem(title: "状態確認タスク", priority: .normal)
        taskStore.addTask(task)
        
        let initialInboxCount = taskStore.inboxTasks.count
        let initialDoneCount = taskStore.doneTasks.count
        
        // 2. タスクを完了
        let inboxTask = taskStore.inboxTasks.first!
        taskStore.completeTask(inboxTask)
        
        let afterCompleteInboxCount = taskStore.inboxTasks.count
        let afterCompleteDoneCount = taskStore.doneTasks.count
        
        // 3. 完了済みタスクを復元
        let doneTask = taskStore.doneTasks.first!
        taskStore.restoreTask(doneTask)
        
        let afterRestoreInboxCount = taskStore.inboxTasks.count
        let afterRestoreDoneCount = taskStore.doneTasks.count
        
        // 4. 状態の一貫性をチェック
        XCTAssertEqual(afterCompleteInboxCount, initialInboxCount - 1, "完了後、inboxTasksは1個減少")
        XCTAssertEqual(afterCompleteDoneCount, initialDoneCount + 1, "完了後、doneTasksは1個増加")
        XCTAssertEqual(afterRestoreInboxCount, initialInboxCount, "復元後、inboxTasksは元の数に戻る")
        XCTAssertEqual(afterRestoreDoneCount, initialDoneCount, "復元後、doneTasksは元の数に戻る")
        
        // 5. 総タスク数の一貫性
        let totalTasksBefore = initialInboxCount + initialDoneCount
        let totalTasksAfterComplete = afterCompleteInboxCount + afterCompleteDoneCount
        let totalTasksAfterRestore = afterRestoreInboxCount + afterRestoreDoneCount
        
        XCTAssertEqual(totalTasksBefore, totalTasksAfterComplete, "完了前後で総タスク数は同じ")
        XCTAssertEqual(totalTasksBefore, totalTasksAfterRestore, "復元前後で総タスク数は同じ")
    }
    
    func testTaskItemCopyingBehavior() throws {
        // 1. 元のタスクを作成
        var originalTask = TaskItem(title: "コピーテスト", priority: .high)
        originalTask.due = Date()
        originalTask.notes = "テストノート"
        
        // 2. タスクを完了
        taskStore.addTask(originalTask)
        let inboxTask = taskStore.inboxTasks.first!
        taskStore.completeTask(inboxTask)
        
        // 3. 完了済みタスクを復元
        let doneTask = taskStore.doneTasks.first!
        taskStore.restoreTask(doneTask)
        
        // 4. 復元されたタスクのプロパティをチェック
        let restoredTask = taskStore.inboxTasks.first!
        
        XCTAssertEqual(restoredTask.title, originalTask.title, "タイトルが保持されている")
        XCTAssertEqual(restoredTask.priority, originalTask.priority, "優先度が保持されている")
        XCTAssertEqual(restoredTask.notes, originalTask.notes, "ノートが保持されている")
        XCTAssertEqual(restoredTask.due, originalTask.due, "期限が保持されている")
        
        // 5. IDの一意性をチェック
        XCTAssertNotEqual(restoredTask.id, originalTask.id, "復元されたタスクは新しいIDを持つ")
    }
    
    func testTaskStoreDataIntegrity() throws {
        // 1. 複数のタスクを追加
        let tasks = [
            TaskItem(title: "タスクA", priority: .normal),
            TaskItem(title: "タスクB", priority: .high),
            TaskItem(title: "タスクC", priority: .low)
        ]
        
        for task in tasks {
            taskStore.addTask(task)
        }
        
        // 2. 各タスクを順番に完了・復元
        for i in 0..<tasks.count {
            let inboxTask = taskStore.inboxTasks.first { $0.title == tasks[i].title }!
            taskStore.completeTask(inboxTask)
            
            let doneTask = taskStore.doneTasks.first!
            taskStore.restoreTask(doneTask)
        }
        
        // 3. 最終状態の整合性をチェック
        XCTAssertEqual(taskStore.inboxTasks.count, tasks.count, "最終的にinboxTasksは元の数に戻る")
        XCTAssertEqual(taskStore.doneTasks.count, 0, "最終的にdoneTasksは0個")
        
        // 4. タスクの内容が正しく保持されているかチェック
        for originalTask in tasks {
            let restoredTask = taskStore.inboxTasks.first { $0.title == originalTask.title }
            XCTAssertNotNil(restoredTask, "タスク'\(originalTask.title)'が復元されている")
            
            if let restored = restoredTask {
                XCTAssertEqual(restored.priority, originalTask.priority, "優先度が保持されている")
            }
        }
        
        // 5. 重複チェック
        let allTaskIds = Set(taskStore.inboxTasks.map { $0.id })
        XCTAssertEqual(allTaskIds.count, tasks.count, "タスクIDに重複がない")
    }
}
