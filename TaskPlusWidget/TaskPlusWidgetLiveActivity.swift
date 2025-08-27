//
//  TaskPlusWidgetLiveActivity.swift
//  TaskPlusWidget
//
//  Created by Yasutaka Otsubo on 2025/08/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TaskPlusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TaskPlusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskPlusWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TaskPlusWidgetAttributes {
    fileprivate static var preview: TaskPlusWidgetAttributes {
        TaskPlusWidgetAttributes(name: "World")
    }
}

extension TaskPlusWidgetAttributes.ContentState {
    fileprivate static var smiley: TaskPlusWidgetAttributes.ContentState {
        TaskPlusWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TaskPlusWidgetAttributes.ContentState {
         TaskPlusWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TaskPlusWidgetAttributes.preview) {
   TaskPlusWidgetLiveActivity()
} contentStates: {
    TaskPlusWidgetAttributes.ContentState.smiley
    TaskPlusWidgetAttributes.ContentState.starEyes
}
