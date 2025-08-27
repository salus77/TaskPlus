//
//  TaskPlusWidgetBundle.swift
//  TaskPlusWidget
//
//  Created by Yasutaka Otsubo on 2025/08/25.
//

import WidgetKit
import SwiftUI

@main
struct TaskPlusWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskPlusWidget()
        TaskPlusWidgetControl()
        TaskPlusWidgetLiveActivity()
    }
}
