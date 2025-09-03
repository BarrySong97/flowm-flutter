//
//  OriginalFlowmWidget.swift
//  FlowmWidget
//
//  Created by Claude on 2025/9/3.
//

import Charts
import Foundation
import SwiftUI
import WidgetKit

struct DailyExpenseItem: Identifiable {
  let id: Int
  let date: Date
  let dayName: String
  let dateString: String
  let amount: Double
}

extension DateFormatter {
  static let weekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "EEE"
    return formatter
  }()

  static let shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M/d"
    return formatter
  }()
}

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(), configuration: ConfigurationAppIntent(), expense: 12345.67, income: 23456.78,
      balance: 11111.11, dailyExpenses: mockDailyExpenses())
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry
  {
    SimpleEntry(
      date: Date(), configuration: configuration, expense: 12345.67, income: 23456.78,
      balance: 11111.11, dailyExpenses: mockDailyExpenses())
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    print("🔵 FlowmWidget timeline() called")

    let userDefaults = UserDefaults(suiteName: "group.flowm")
    let expenseString = userDefaults?.string(forKey: "expense") ?? ""
    let incomeString = userDefaults?.string(forKey: "income") ?? ""
    let balanceString = userDefaults?.string(forKey: "balance") ?? ""

    print(
      "🔵 FlowmWidget raw data - expense: '\(expenseString)', income: '\(incomeString)', balance: '\(balanceString)'"
    )

    let expense = Double(expenseString) ?? 0.0
    let income = Double(incomeString) ?? 0.0
    let balance = Double(balanceString) ?? 0.0

    print("🔵 FlowmWidget parsed data - expense: \(expense), income: \(income), balance: \(balance)")

    let entry = SimpleEntry(
      date: Date(), configuration: configuration, expense: expense, income: income,
      balance: balance,
      dailyExpenses: mockDailyExpenses()
    )

    print("🔵 FlowmWidget entry created successfully")

    // Refresh the timeline every 15 minutes
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

    print("🔵 FlowmWidget timeline created, next update: \(nextUpdate)")
    return timeline
  }

  private func mockDailyExpenses() -> [DailyExpenseItem] {
    let calendar = Calendar.current
    let today = Date()
    var expenses: [DailyExpenseItem] = []

    // 生成过去10天的数据
    for i in 9...0 {
      let date = calendar.date(byAdding: .day, value: -i, to: today)!
      let amount = Double.random(in: 200...2000)
      let dayName = DateFormatter.weekdayFormatter.string(from: date)
      let dateString = DateFormatter.shortDateFormatter.string(from: date)

      expenses.append(
        DailyExpenseItem(
          id: i,
          date: date,
          dayName: dayName,
          dateString: dateString,
          amount: amount
        ))
    }

    return expenses
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let expense: Double
  let income: Double
  let balance: Double
  let dailyExpenses: [DailyExpenseItem]
}

struct FlowmWidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: Provider.Entry

  private func formatCurrency(_ value: Double) -> String {
    return NumberFormatUtils.formatCurrency(value)
  }

  private func getCurrentMonth() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月"
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: Date())
  }

  var body: some View {
    print(
      "🔵 FlowmWidgetEntryView rendering - expense: \(entry.expense), income: \(entry.income), balance: \(entry.balance)"
    )
    return Text("Hello, World!")
    // return Group {
    //   switch widgetFamily {
    //   case .systemSmall:
    //     smallWidgetView
    //   case .systemMedium:
    //     mediumWidgetView
    //   default:
    //     mediumWidgetView
    //   }
    // }
  }

  private var smallWidgetView: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 月份标题
      Text(getCurrentMonth())
        .font(.headline)
        .fontWeight(.medium)
        .foregroundColor(.primary)

      // 垂直布局：收入、支出、结余
      VStack(alignment: .leading, spacing: 6) {
        // 支出
        HStack {
          Text("支出")
            .font(.caption2)
            .foregroundColor(.secondary)
          Spacer()
          Text(formatCurrency(entry.expense))
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.red)
        }
        // 收入
        HStack {
          Text("收入")
            .font(.caption2)
            .foregroundColor(.secondary)
          Spacer()
          Text(formatCurrency(entry.income))
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.green)
        }

        // 结余
        HStack {
          Text("结余")
            .font(.caption2)
            .foregroundColor(.secondary)
          Spacer()
          Text(formatCurrency(entry.balance))
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(entry.balance >= 0 ? .primary : .red)
        }
      }

      Spacer()
    }
    .padding(12)
  }

  private var mediumWidgetView: some View {
    VStack(alignment: .leading, spacing: 12) {
      // 上方：当月总支出、总收入、结余（横向布局）
      monthlyOverviewSection

      // 下方：每日支出柱状图
      dailyExpenseChartSection
    }
    .padding(.vertical, 0)
    .padding(.horizontal, 4)
  }

  private var monthlyOverviewSection: some View {
    HStack(alignment: .top, spacing: 12) {
      // 总支出
      VStack(alignment: .leading, spacing: 2) {
        Text("\(getCurrentMonth())总支出")
          .font(.caption2)
          .foregroundColor(.secondary)
        Text(formatCurrency(entry.expense))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.red)
      }

      Spacer()

      // 总收入
      VStack(alignment: .leading, spacing: 2) {
        Text("\(getCurrentMonth())总收入")
          .font(.caption2)
          .foregroundColor(.secondary)
        Text(formatCurrency(entry.income))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.green)
      }

      Spacer()

      // 结余
      VStack(alignment: .leading, spacing: 2) {
        Text("\(getCurrentMonth())结余")
          .font(.caption2)
          .foregroundColor(.secondary)
        Text(formatCurrency(entry.balance))
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(entry.balance >= 0 ? .primary : .red)
      }
    }
  }

  private var dailyExpenseChartSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 柱状图
      Chart(entry.dailyExpenses) { expense in
        BarMark(
          x: .value("日期", expense.dateString),
          y: .value("金额", expense.amount)
        )
        .foregroundStyle(.red)
        .cornerRadius(2, style: .continuous)
        .annotation(position: .top) {
          Text(NumberFormatUtils.formatNumberWithK(expense.amount))
            .font(.system(size: 7, weight: .medium))
            .foregroundColor(.primary)
        }
      }
      .chartYAxis(.hidden)
      .chartXAxis {
        AxisMarks(position: .bottom) { value in
          AxisValueLabel {
            if let dateString = value.as(String.self) {
              Text(dateString)
                .font(.system(size: 7))
                .foregroundColor(.secondary)
            }
          }
        }
      }
      .frame(height: 70)
    }
  }
}

struct FlowmWidget: Widget {
  let kind: String = "FlowmWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      FlowmWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("月度概览")
    .description("快速查看当月收入、支出和结余。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(
  "small",
  as: .systemSmall,
  widget: {
    FlowmWidget()
  },
  timeline: {
    SimpleEntry(
      date: .now,
      configuration: ConfigurationAppIntent(),
      expense: 1234.56,
      income: 5678.90,
      balance: 4444.34,
      dailyExpenses: Array(0..<10).map { i in
        DailyExpenseItem(
          id: i,
          date: Calendar.current.date(byAdding: .day, value: -9 + i, to: Date()) ?? Date(),
          dayName: "周\(i % 7 + 1)",
          dateString: "9/\(1 + i)",
          amount: Double.random(in: 300...1500)
        )
      }
    )
  })

#Preview(
  "medium",
  as: .systemMedium,
  widget: {
    FlowmWidget()
  },
  timeline: {
    SimpleEntry(
      date: .now,
      configuration: ConfigurationAppIntent(),
      expense: 1234.56,
      income: 5678.90,
      balance: 4444.34,
      dailyExpenses: Array(0..<10).map { i in
        DailyExpenseItem(
          id: i,
          date: Calendar.current.date(byAdding: .day, value: -9 + i, to: Date()) ?? Date(),
          dayName: "周\(i % 7 + 1)",
          dateString: "9/\(1 + i)",
          amount: Double.random(in: 300...1500)
        )
      }
    )
  })
