//
//  TaskPlusApp.swift
//  TaskPlus
//
//  Created by Yasutaka Otsubo on 2025/08/24.
//

import SwiftUI

@main
struct TaskPlusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
