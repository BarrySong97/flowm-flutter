//
//  FlowmIntents.swift
//  FlowmIntents
//
//  Created by 宋天健 on 2025/6/18.
//

import AppIntents
import Foundation

struct FlowmIntents: AppIntent {
  static var title: LocalizedStringResource { "Get Account Data" }
  static var description = IntentDescription("获取账户数据")

  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    // 从 App Group 中读取数据
    let userDefaults = UserDefaults(suiteName: "group.flowm")

    // 添加调试信息
    print("[FlowmIntents] Trying to access App Group: group.flowm")

    if userDefaults == nil {
      print("[FlowmIntents] ERROR: Unable to access App Group UserDefaults")
      return .result(value: "ERROR: Unable to access App Group")
    }

    // 列出所有可用的键
    let allKeys = userDefaults!.dictionaryRepresentation().keys
    print("[FlowmIntents] Available keys in App Group: \(Array(allKeys))")

    let accountData = userDefaults?.string(forKey: "accountDataJson") ?? ""
    print("[FlowmIntents] Retrieved accountDataJson length: \(accountData.count)")

    if accountData.isEmpty {
      // 尝试获取其他键的数据来调试
      let ledgerId = userDefaults?.object(forKey: "ledgerId")
      let lastUpdated = userDefaults?.string(forKey: "lastUpdated")
      print("[FlowmIntents] ledgerId: \(String(describing: ledgerId))")
      print("[FlowmIntents] lastUpdated: \(String(describing: lastUpdated))")

      return .result(value: "No data found. Available keys: \(Array(allKeys))")
    }

    return .result(value: accountData)
  }
}

// 添加返回结构化数据的 Intent
struct FlowmDataIntent: AppIntent {
  static var title: LocalizedStringResource { "Get Structured Account Data" }
  static var description = IntentDescription("获取 Flowm 应用中的结构化账户数据")

  func perform() async throws -> some IntentResult & ReturnsValue<FlowmAccountData> {
    let userDefaults = UserDefaults(suiteName: "group.flowm")

    let expense = userDefaults?.double(forKey: "expense") ?? 0.0
    let income = userDefaults?.double(forKey: "income") ?? 0.0
    let balance = userDefaults?.double(forKey: "balance") ?? 0.0

    let accountData = FlowmAccountData(
      expense: expense,
      income: income,
      balance: balance,
      lastUpdated: Date()
    )

    return .result(value: accountData)
  }
}

// 定义返回的数据结构
struct FlowmAccountData: AppEntity {
  let expense: Double
  let income: Double
  let balance: Double
  let lastUpdated: Date

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Flowm 账户数据"

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "余额: ¥\(String(format: "%.2f", balance))",
      subtitle: "收入: ¥\(String(format: "%.2f", income)), 支出: ¥\(String(format: "%.2f", expense))"
    )
  }

  static var defaultQuery = FlowmAccountDataQuery()

  var id: String {
    "\(lastUpdated.timeIntervalSince1970)"
  }
}

// 添加查询类
struct FlowmAccountDataQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [FlowmAccountData] {
    let userDefaults = UserDefaults(suiteName: "group.flowm")

    let expense = userDefaults?.double(forKey: "expense") ?? 0.0
    let income = userDefaults?.double(forKey: "income") ?? 0.0
    let balance = userDefaults?.double(forKey: "balance") ?? 0.0

    let accountData = FlowmAccountData(
      expense: expense,
      income: income,
      balance: balance,
      lastUpdated: Date()
    )

    return [accountData]
  }

  func suggestedEntities() async throws -> [FlowmAccountData] {
    return try await entities(for: [])
  }
}
