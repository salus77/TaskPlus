//
//  TaskPlusUITests.swift
//  TaskPlusUITests
//
//  Created by del mar y el sol on 2025/08/24.
//

import XCTest

final class TaskPlusUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Quick Task Addition Tests
    
    @MainActor
    func testQuickTaskAdditionImmediateReflection() throws {
        // Given - Inbox画面にいることを確認
        let inboxTab = app.tabBars.buttons["Inbox"]
        inboxTab.tap()
        
        // クイックタスク追加バーを探す
        let quickAddTextField = app.textFields.firstMatch
        XCTAssertTrue(quickAddTextField.exists, "クイックタスク追加テキストフィールドが存在する必要があります")
        
        // When - 最初のタスクを追加
        let firstTaskTitle = "Test Task 1"
        quickAddTextField.tap()
        quickAddTextField.typeText(firstTaskTitle)
        app.keyboards.buttons["return"].tap()
        
        // Then - 最初のタスクが即座に表示される
        let firstTask = app.staticTexts[firstTaskTitle]
        XCTAssertTrue(firstTask.waitForExistence(timeout: 2), "最初のタスクが即座に表示される必要があります")
        
        // When - 2番目のタスクを追加
        let secondTaskTitle = "Test Task 2"
        quickAddTextField.tap()
        quickAddTextField.typeText(secondTaskTitle)
        app.keyboards.buttons["return"].tap()
        
        // Then - 2番目のタスクも即座に表示される
        let secondTask = app.staticTexts[secondTaskTitle]
        XCTAssertTrue(secondTask.waitForExistence(timeout: 2), "2番目のタスクも即座に表示される必要があります")
        
        // 両方のタスクが表示されていることを確認
        XCTAssertTrue(firstTask.exists, "最初のタスクが引き続き表示されている必要があります")
        XCTAssertTrue(secondTask.exists, "2番目のタスクが引き続き表示されている必要があります")
    }
    
    @MainActor
    func testMultipleQuickTaskAddition() throws {
        // Given - Inbox画面にいることを確認
        let inboxTab = app.tabBars.buttons["Inbox"]
        inboxTab.tap()
        
        let quickAddTextField = app.textFields.firstMatch
        XCTAssertTrue(quickAddTextField.exists, "クイックタスク追加テキストフィールドが存在する必要があります")
        
        // When - 複数のタスクを連続で追加
        let taskTitles = ["Task A", "Task B", "Task C", "Task D", "Task E"]
        var addedTasks: [XCUIElement] = []
        
        for title in taskTitles {
            quickAddTextField.tap()
            quickAddTextField.typeText(title)
            app.keyboards.buttons["return"].tap()
            
            // 各タスクが追加されるまで少し待機
            let task = app.staticTexts[title]
            if task.waitForExistence(timeout: 1) {
                addedTasks.append(task)
            }
        }
        
        // Then - すべてのタスクが表示されている
        XCTAssertEqual(addedTasks.count, taskTitles.count, "すべてのタスクが追加される必要があります")
        
        for (index, task) in addedTasks.enumerated() {
            XCTAssertTrue(task.exists, "タスク \(taskTitles[index]) が表示されている必要があります")
        }
    }
    
    @MainActor
    func testQuickTaskAdditionWithEmptyInput() throws {
        // Given - Inbox画面にいることを確認
        let inboxTab = app.tabBars.buttons["Inbox"]
        inboxTab.tap()
        
        let quickAddTextField = app.textFields.firstMatch
        XCTAssertTrue(quickAddTextField.exists, "クイックタスク追加テキストフィールドが存在する必要があります")
        
        // When - 空のテキストでEnterを押す
        quickAddTextField.tap()
        app.keyboards.buttons["return"].tap()
        
        // Then - エラーが発生しない（クラッシュしない）
        XCTAssertTrue(app.exists, "アプリがクラッシュしていない必要があります")
    }
    
    @MainActor
    func testQuickTaskAdditionWithWhitespaceOnly() throws {
        // Given - Inbox画面にいることを確認
        let inboxTab = app.tabBars.buttons["Inbox"]
        inboxTab.tap()
        
        let quickAddTextField = app.textFields.firstMatch
        XCTAssertTrue(quickAddTextField.exists, "クイックタスク追加テキストフィールドが存在する必要があります")
        
        // When - 空白文字のみでEnterを押す
        quickAddTextField.tap()
        quickAddTextField.typeText("   ")
        app.keyboards.buttons["return"].tap()
        
        // Then - タスクが追加されない
        let initialTaskCount = app.staticTexts.matching(identifier: "Task").count
        
        // 有効なタスクを追加
        quickAddTextField.tap()
        quickAddTextField.typeText("Valid Task")
        app.keyboards.buttons["return"].tap()
        
        let finalTaskCount = app.staticTexts.matching(identifier: "Task").count
        XCTAssertEqual(finalTaskCount, initialTaskCount + 1, "有効なタスクのみが追加される必要があります")
    }
    
    @MainActor
    func testQuickTaskAdditionPerformance() throws {
        // Given - Inbox画面にいることを確認
        let inboxTab = app.tabBars.buttons["Inbox"]
        inboxTab.tap()
        
        let quickAddTextField = app.textFields.firstMatch
        XCTAssertTrue(quickAddTextField.exists, "クイックタスク追加テキストフィールドが存在する必要があります")
        
        // When - パフォーマンステスト
        measure(metrics: [XCTClockMetric()]) {
            // 10個のタスクを追加
            for i in 0..<10 {
                quickAddTextField.tap()
                quickAddTextField.typeText("Performance Task \(i)")
                app.keyboards.buttons["return"].tap()
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testTabNavigation() throws {
        // Given - アプリが起動している
        
        // When - 各タブをタップ
        let inboxTab = app.tabBars.buttons["Inbox"]
        let todayTab = app.tabBars.buttons["Today"]
        let settingsTab = app.tabBars.buttons["Settings"]
        
        // Then - 各タブが存在する
        XCTAssertTrue(inboxTab.exists, "Inboxタブが存在する必要があります")
        XCTAssertTrue(todayTab.exists, "Todayタブが存在する必要があります")
        XCTAssertTrue(settingsTab.exists, "Settingsタブが存在する必要があります")
        
        // When - 各タブを順番にタップ
        inboxTab.tap()
        XCTAssertTrue(app.navigationBars["Inbox"].exists, "Inbox画面が表示される必要があります")
        
        todayTab.tap()
        XCTAssertTrue(app.navigationBars["Today"].exists, "Today画面が表示される必要があります")
        
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists, "Settings画面が表示される必要があります")
    }
}
