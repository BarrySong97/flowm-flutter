//
//  FlowmIntentsExtension.swift
//  FlowmIntents
//
//  Created by 宋天健 on 2025/6/18.
//

import AppIntents

@main
struct FlowmIntentsExtension: AppIntentsExtension {
  static var appIntents: [any AppIntent.Type] {
    [FlowmIntents.self, FlowmDataIntent.self]
  }

  static var includeAppIntents: [any AppIntent.Type] {
    [FlowmIntents.self, FlowmDataIntent.self]
  }
}
