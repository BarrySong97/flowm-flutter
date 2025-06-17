//
//  FlowmWidgetLiveActivity.swift
//  FlowmWidget
//
//  Created by 宋天健 on 2025/6/17.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FlowmWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FlowmWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlowmWidgetAttributes.self) { context in
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

extension FlowmWidgetAttributes {
    fileprivate static var preview: FlowmWidgetAttributes {
        FlowmWidgetAttributes(name: "World")
    }
}

extension FlowmWidgetAttributes.ContentState {
    fileprivate static var smiley: FlowmWidgetAttributes.ContentState {
        FlowmWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FlowmWidgetAttributes.ContentState {
         FlowmWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FlowmWidgetAttributes.preview) {
   FlowmWidgetLiveActivity()
} contentStates: {
    FlowmWidgetAttributes.ContentState.smiley
    FlowmWidgetAttributes.ContentState.starEyes
}
