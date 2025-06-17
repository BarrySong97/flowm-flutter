//
//  FlowmWidgetBundle.swift
//  FlowmWidget
//
//  Created by 宋天健 on 2025/6/17.
//

import WidgetKit
import SwiftUI

@main
struct FlowmWidgetBundle: WidgetBundle {
    var body: some Widget {
        FlowmWidget()
        FlowmWidgetControl()
        FlowmWidgetLiveActivity()
    }
}
