//
//  ExpensePieChartWidget.swift
//  FlowmWidget
//
//  Created by Claude on 2025/9/3.
//

import SwiftUI
import WidgetKit
import Charts
import Foundation

// MARK: - Expense Pie Chart Widget

struct ExpenseCategoryItem: Identifiable {
  let id: Int
  let name: String
  let amount: Double
  let percentage: Double
  let color: Color
}

struct ExpensePieChartProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> ExpensePieChartEntry {
    ExpensePieChartEntry(
      date: Date(),
      configuration: ConfigurationAppIntent(),
      totalExpense: 8500.0,
      categories: mockExpenseCategories()
    )
  }
  
  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ExpensePieChartEntry {
    ExpensePieChartEntry(
      date: Date(),
      configuration: configuration,
      totalExpense: 8500.0,
      categories: mockExpenseCategories()
    )
  }
  
  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ExpensePieChartEntry> {
    let entry = ExpensePieChartEntry(
      date: Date(),
      configuration: configuration,
      totalExpense: 8500.0,
      categories: mockExpenseCategories()
    )
    
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    return timeline
  }
  
  private func mockExpenseCategories() -> [ExpenseCategoryItem] {
    let totalAmount = 8500.0
    
    // Define colors - different colors for each category
    let colorRed = Color.red
    let colorBlue = Color.blue
    let colorGreen = Color.green
    let colorOrange = Color.orange
    let colorPurple = Color.purple
    let colorTeal = Color.teal
    let colorGray = Color.gray
    
    // Define expense data
    let expenseData = [
      ("餐饮", 2800.0, colorRed),
      ("交通", 1200.0, colorBlue),
      ("购物", 1800.0, colorGreen),
      ("娱乐", 800.0, colorOrange),
      ("医疗", 600.0, colorPurple),
      ("教育", 900.0, colorTeal),
      ("其他", 400.0, colorGray)
    ]
    
    var categories: [ExpenseCategoryItem] = []
    
    for (index, data) in expenseData.enumerated() {
      let name = data.0
      let amount = data.1
      let color = data.2
      let percentage = (amount / totalAmount) * 100
      
      let category = ExpenseCategoryItem(
        id: index,
        name: name,
        amount: amount,
        percentage: percentage,
        color: color
      )
      categories.append(category)
    }
    
    return categories
  }
}

struct ExpensePieChartEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let totalExpense: Double
  let categories: [ExpenseCategoryItem]
}

struct ExpensePieChartWidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: ExpensePieChartProvider.Entry
  
  private func formatCurrency(_ value: Double) -> String {
    return NumberFormatUtils.formatCurrency(value)
  }
  
  private func formatPercentage(_ value: Double) -> String {
    return String(format: "%.1f%%", value)
  }
  
  private func getCurrentMonth() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月"
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: Date())
  }
  
  var body: some View {
    HStack(spacing: 16) {
      // 左侧：饼图
      pieChartSection
      
      // 右侧：图例
      legendSection
    }
    .padding(12)
  }
  
  private var pieChartSection: some View {
    Chart(entry.categories) { category in
      SectorMark(
        angle: .value("金额", category.amount),
        innerRadius: .ratio(0.5),
        angularInset: 0.5
      )
      .foregroundStyle(category.color)
      .opacity(0.8)
    }
    .frame(width: 120, height: 120)
  }
  
  private var legendSection: some View {
    VStack(alignment: .leading, spacing: 4) {
      // 标题
      HStack {
        Text("\(getCurrentMonth())总支出")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        
        Spacer()
        
        Text(formatCurrency(entry.totalExpense))
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      
      // 分类列表
      LazyVStack(alignment: .leading, spacing: 3) {
        ForEach(entry.categories.prefix(6)) { category in
          HStack(spacing: 6) {
            // 颜色指示器
            Circle()
              .fill(category.color)
              .frame(width: 8, height: 8)
            
            // 分类名称
            Text(category.name)
              .font(.system(size: 10))
              .foregroundColor(.primary)
            
            Spacer()
            
            // 百分比
            Text(formatPercentage(category.percentage))
              .font(.system(size: 9, weight: .medium))
              .foregroundColor(.secondary)
            
            // 金额
            Text(formatCurrency(category.amount))
              .font(.system(size: 9, weight: .medium))
              .foregroundColor(.primary)
          }
        }
        
        // 如果有更多分类，显示"其他"
        if entry.categories.count > 6 {
          HStack(spacing: 6) {
            Circle()
              .fill(Color.gray.opacity(0.3))
              .frame(width: 8, height: 8)
            
            Text("其他")
              .font(.system(size: 10))
              .foregroundColor(.secondary)
            
            Spacer()
            
            let remainingAmount = entry.categories.dropFirst(6).reduce(0) { $0 + $1.amount }
            let remainingPercentage = (remainingAmount / entry.totalExpense) * 100
            
            Text(formatPercentage(remainingPercentage))
              .font(.system(size: 9, weight: .medium))
              .foregroundColor(.secondary)
            
            Text(formatCurrency(remainingAmount))
              .font(.system(size: 9, weight: .medium))
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ExpensePieChartWidget: Widget {
  let kind: String = "ExpensePieChartWidget"
  
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: ConfigurationAppIntent.self, provider: ExpensePieChartProvider()
    ) { entry in
      ExpensePieChartWidgetEntryView(entry: entry)
        .containerBackground(.white, for: .widget)
    }
    .configurationDisplayName("支出分类饼图")
    .description("显示各类支出的占比分布。")
    .supportedFamilies([.systemMedium])
  }
}

#Preview(
  "Expense Pie Chart Widget",
  as: .systemMedium,
  widget: {
    ExpensePieChartWidget()
  },
  timeline: {
    ExpensePieChartEntry(
      date: .now,
      configuration: ConfigurationAppIntent(),
      totalExpense: 8500.0,
      categories: [
        ExpenseCategoryItem(id: 1, name: "餐饮", amount: 2800.0, percentage: 32.9, color: .red),
        ExpenseCategoryItem(id: 2, name: "交通", amount: 1200.0, percentage: 14.1, color: .blue),
        ExpenseCategoryItem(id: 3, name: "购物", amount: 1800.0, percentage: 21.2, color: .green),
        ExpenseCategoryItem(id: 4, name: "娱乐", amount: 800.0, percentage: 9.4, color: .orange),
        ExpenseCategoryItem(id: 5, name: "医疗", amount: 600.0, percentage: 7.1, color: .purple),
        ExpenseCategoryItem(id: 6, name: "教育", amount: 900.0, percentage: 10.6, color: .teal),
        ExpenseCategoryItem(id: 7, name: "其他", amount: 400.0, percentage: 4.7, color: .gray)
      ]
    )
  }
)