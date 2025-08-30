//
//  CalendarWidget.swift
//  FlowmWidget
//
//  Created by Claude on 2025/8/30.
//

import SwiftUI
import WidgetKit

// MARK: - Calendar Widget

struct CalendarProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> CalendarEntry {
    CalendarEntry(
      date: Date(),
      configuration: ConfigurationAppIntent(),
      currentMonth: "2025年8月",
      selectedDay: 30,
      dayTransactions: mockDayTransactions()
    )
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async
    -> CalendarEntry
  {
    CalendarEntry(
      date: Date(),
      configuration: configuration,
      currentMonth: "2025年8月",
      selectedDay: 30,
      dayTransactions: mockDayTransactions()
    )
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    CalendarEntry
  > {
    let currentDate = Date()
    let calendar = Calendar.current
    let monthFormatter = DateFormatter()
    monthFormatter.locale = Locale(identifier: "zh_CN")
    monthFormatter.dateFormat = "yyyy年M月"

    let entry = CalendarEntry(
      date: currentDate,
      configuration: configuration,
      currentMonth: monthFormatter.string(from: currentDate),
      selectedDay: calendar.component(.day, from: currentDate),
      dayTransactions: mockDayTransactions()
    )

    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    return timeline
  }

  private func mockDayTransactions() -> [Int: DayTransaction] {
    return [
      15: DayTransaction(income: 2500.0, expense: 800.0),
      22: DayTransaction(income: 0.0, expense: 1200.0),
      28: DayTransaction(income: 3000.0, expense: 0.0),
      30: DayTransaction(income: 500.0, expense: 1500.0),
    ]
  }
}

struct CalendarEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let currentMonth: String
  let selectedDay: Int
  let dayTransactions: [Int: DayTransaction]
}

struct DayTransaction {
  let income: Double
  let expense: Double

  var hasTransaction: Bool {
    return income > 0 || expense > 0
  }
}

struct CalendarWidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: CalendarProvider.Entry

  private let weekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

  var body: some View {
    largeCalendarView
  }

  private var largeCalendarView: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Header
      HStack {
        Text(entry.currentMonth)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(.primary)

      }

      // Week header
      HStack {
        ForEach(weekDays, id: \.self) { day in
          Text(day)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
        }
      }
      .padding(.bottom, 4)

      // Full calendar grid
      VStack(spacing: 8) {
        calendarRow(
          days: [28, 29, 30, 31, 1, 2, 3],
          isCurrentMonth: [false, false, false, false, true, true, true])
        calendarRow(days: [4, 5, 6, 7, 8, 9, 10], isCurrentMonth: Array(repeating: true, count: 7))
        calendarRow(
          days: [11, 12, 13, 14, 15, 16, 17], isCurrentMonth: Array(repeating: true, count: 7))
        calendarRow(
          days: [18, 19, 20, 21, 22, 23, 24], isCurrentMonth: Array(repeating: true, count: 7))
        calendarRow(
          days: [25, 26, 27, 28, 29, 30, 31], isCurrentMonth: Array(repeating: true, count: 7))
      }
    }
    .padding(4)
  }

  private func calendarRow(days: [Int], isCurrentMonth: [Bool]) -> some View {
    HStack(spacing: 6) {
      ForEach(Array(zip(days.indices, days)), id: \.0) { index, day in
        let transaction = entry.dayTransactions[day]
        let isSelected = day == entry.selectedDay && isCurrentMonth[index]

        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)

          VStack(spacing: 3) {
            Text("\(day)")
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(isCurrentMonth[index] ? .primary : .secondary)

          }
        }
        .frame(maxWidth: .infinity, minHeight: 42)
      }
    }
  }
}

struct CalendarWidget: Widget {
  let kind: String = "CalendarWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: ConfigurationAppIntent.self, provider: CalendarProvider()
    ) { entry in
      CalendarWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("收支日历")
    .description("以日历形式查看每日收支情况。")
    .supportedFamilies([.systemLarge])
  }
}

#Preview(
  "Calendar Large",
  as: .systemLarge,
  widget: {
    CalendarWidget()
  },
  timeline: {
    CalendarEntry(
      date: .now,
      configuration: ConfigurationAppIntent(),
      currentMonth: "2025年8月",
      selectedDay: 30,
      dayTransactions: [
        15: DayTransaction(income: 2500.0, expense: 800.0),
        22: DayTransaction(income: 0.0, expense: 1200.0),
        28: DayTransaction(income: 3000.0, expense: 0.0),
        30: DayTransaction(income: 500.0, expense: 1500.0),
      ]
    )
  })
