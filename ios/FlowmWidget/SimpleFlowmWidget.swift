//
//  SimpleFlowmWidget.swift
//  FlowmWidget
//
//  Created by Claude on 2025/9/3.
//

import SwiftUI
import WidgetKit

// MARK: - Data Models
struct FinanceData {
  let expense: Double
  let income: Double  
  let balance: Double
  
  static let placeholder = FinanceData(expense: 1234.56, income: 5678.90, balance: 4444.34)
}

// MARK: - Timeline Provider
struct SimpleFlowmProvider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleFlowmEntry {
    SimpleFlowmEntry(date: Date(), financeData: FinanceData.placeholder)
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SimpleFlowmEntry) -> ()) {
    let entry = SimpleFlowmEntry(date: Date(), financeData: loadFinanceData())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleFlowmEntry>) -> ()) {
    print("🟢 SimpleFlowmWidget getTimeline() called")
    
    let financeData = loadFinanceData()
    let entry = SimpleFlowmEntry(date: Date(), financeData: financeData)
    
    print("🟢 SimpleFlowmWidget data - expense: \(financeData.expense), income: \(financeData.income), balance: \(financeData.balance)")
    
    // 每15分钟更新一次
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    
    print("🟢 SimpleFlowmWidget timeline created, next update: \(nextUpdate)")
    completion(timeline)
  }
  
  private func loadFinanceData() -> FinanceData {
    guard let userDefaults = UserDefaults(suiteName: "group.flowm") else {
      print("⚠️ SimpleFlowmWidget: Cannot access UserDefaults, using placeholder data")
      return FinanceData.placeholder
    }
    
    let expenseString = userDefaults.string(forKey: "expense") ?? ""
    let incomeString = userDefaults.string(forKey: "income") ?? ""
    let balanceString = userDefaults.string(forKey: "balance") ?? ""
    
    print("🟢 SimpleFlowmWidget raw data - expense: '\(expenseString)', income: '\(incomeString)', balance: '\(balanceString)'")
    
    let expense = Double(expenseString) ?? 0.0
    let income = Double(incomeString) ?? 0.0
    let balance = Double(balanceString) ?? 0.0
    
    return FinanceData(expense: expense, income: income, balance: balance)
  }
}

// MARK: - Timeline Entry
struct SimpleFlowmEntry: TimelineEntry {
  let date: Date
  let financeData: FinanceData
}

// MARK: - Widget View
struct SimpleFlowmWidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: SimpleFlowmProvider.Entry
  
  var body: some View {
    print("🟢 SimpleFlowmWidgetEntryView rendering - expense: \(entry.financeData.expense), income: \(entry.financeData.income), balance: \(entry.financeData.balance)")
    
    return Group {
      switch widgetFamily {
      case .systemSmall:
        smallWidgetView
      case .systemMedium:
        mediumWidgetView
      default:
        smallWidgetView
      }
    }
  }
  
  // MARK: - Small Widget View
  private var smallWidgetView: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 标题
      Text("Flowm")
        .font(.headline)
        .fontWeight(.bold)
        .foregroundColor(.primary)
      
      // 财务数据
      VStack(alignment: .leading, spacing: 4) {
        FinanceRow(label: "支出", amount: entry.financeData.expense, color: .red)
        FinanceRow(label: "收入", amount: entry.financeData.income, color: .green)
        FinanceRow(label: "结余", amount: entry.financeData.balance, 
                  color: entry.financeData.balance >= 0 ? .primary : .red)
      }
      
      Spacer()
    }
    .padding(12)
    .containerBackground(.fill.tertiary, for: .widget)
  }
  
  // MARK: - Medium Widget View  
  private var mediumWidgetView: some View {
    HStack(spacing: 16) {
      // 左侧：当月标题
      VStack(alignment: .leading, spacing: 8) {
        Text("Flowm")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)
        
        Text(getCurrentMonth())
          .font(.subheadline)
          .foregroundColor(.secondary)
        
        Spacer()
      }
      
      Spacer()
      
      // 右侧：财务数据
      VStack(alignment: .trailing, spacing: 6) {
        FinanceRow(label: "支出", amount: entry.financeData.expense, color: .red, alignment: .trailing)
        FinanceRow(label: "收入", amount: entry.financeData.income, color: .green, alignment: .trailing)
        FinanceRow(label: "结余", amount: entry.financeData.balance, 
                  color: entry.financeData.balance >= 0 ? .primary : .red, alignment: .trailing)
      }
    }
    .padding(16)
    .containerBackground(.fill.tertiary, for: .widget)
  }
  
  // MARK: - Helper Views
  private struct FinanceRow: View {
    let label: String
    let amount: Double
    let color: Color
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
      VStack(alignment: alignment, spacing: 2) {
        Text(label)
          .font(.caption)
          .foregroundColor(.secondary)
        Text(formatCurrency(amount))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(color)
      }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
      if abs(amount) >= 10000 {
        let kValue = amount / 1000
        return String(format: "%.1fk", kValue)
      } else {
        return String(format: "%.0f", amount)
      }
    }
  }
  
  // MARK: - Helper Methods
  private func getCurrentMonth() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月"
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: Date())
  }
}

// MARK: - Widget Configuration
struct SimpleFlowmWidget: Widget {
  let kind: String = "SimpleFlowmWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: SimpleFlowmProvider()) { entry in
      SimpleFlowmWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("财务概览")
    .description("简洁的财务数据展示")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Previews
#Preview("small", as: .systemSmall, widget: {
  SimpleFlowmWidget()
}, timeline: {
  SimpleFlowmEntry(date: .now, financeData: FinanceData.placeholder)
})

#Preview("medium", as: .systemMedium, widget: {
  SimpleFlowmWidget()
}, timeline: {
  SimpleFlowmEntry(date: .now, financeData: FinanceData.placeholder)
})