//
//  FlowmWidget.swift
//  FlowmWidget
//
//  Created by 宋天健 on 2025/6/17.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(), configuration: ConfigurationAppIntent(), expense: 12345.67, income: 23456.78,
      balance: 11111.11)
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry
  {
    SimpleEntry(
      date: Date(), configuration: configuration, expense: 12345.67, income: 23456.78,
      balance: 11111.11)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    let userDefaults = UserDefaults(suiteName: "group.flowm")
    let expense = Double(userDefaults?.string(forKey: "expense") ?? "") ?? 0.0
    let income = Double(userDefaults?.string(forKey: "income") ?? "") ?? 0.0
    let balance = Double(userDefaults?.string(forKey: "balance") ?? "") ?? 0.0

    let entry = SimpleEntry(
      date: Date(), configuration: configuration, expense: expense, income: income, balance: balance
    )

    // Refresh the timeline every 15 minutes
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    return timeline
  }

  //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
  //        // Generate a list containing the contexts this widget is relevant in.
  //    }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let expense: Double
  let income: Double
  let balance: Double
}

struct FlowmWidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: Provider.Entry

  private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.currencySymbol = "¥"
    return formatter.string(from: NSNumber(value: value)) ?? "¥0.00"
  }

  var body: some View {
    switch widgetFamily {
    case .systemSmall:
      smallWidgetView
    case .systemMedium:
      mediumWidgetView
    default:
      mediumWidgetView
    }
  }

  private var smallWidgetView: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("本月结余")
        .font(.caption)
        .foregroundColor(.secondary)

      Text(formatCurrency(entry.balance))
        .font(.system(.title3, design: .rounded))
        .fontWeight(.semibold)
        .foregroundColor(entry.balance >= 0 ? Color.primary : Color.red)

      HStack {
        Text("收入")
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        Text(formatCurrency(entry.income))
          .font(.caption)
          .foregroundColor(.green)
      }

      HStack {
        Text("支出")
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        Text(formatCurrency(entry.expense))
          .font(.caption)
          .foregroundColor(.red)
      }
    }.padding(0)
  }

  private var mediumWidgetView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("本月概览")
        .font(.headline)
        .foregroundColor(.secondary)

      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          Text("收入")
            .font(.caption)
          Text(formatCurrency(entry.income))
            .font(.system(.body, design: .rounded))
            .foregroundColor(.green)
        }
        Spacer()
        VStack(alignment: .leading) {
          Text("支出")
            .font(.caption)
          Text(formatCurrency(entry.expense))
            .font(.system(.body, design: .rounded))
            .foregroundColor(.red)
        }
      }

      VStack(alignment: .leading) {
        Text("结余")
          .font(.caption)
        Text(formatCurrency(entry.balance))
          .font(.system(.title2, design: .rounded))
          .fontWeight(.semibold)
          .foregroundColor(entry.balance >= 0 ? Color.primary : Color.red)
      }
    }.padding()
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
  }
}



extension ConfigurationAppIntent {
  fileprivate static var smiley: ConfigurationAppIntent {
    let intent = ConfigurationAppIntent()
    intent.favoriteEmoji = "😀"
    return intent
  }

  fileprivate static var starEyes: ConfigurationAppIntent {
    let intent = ConfigurationAppIntent()
    intent.favoriteEmoji = "🤩"
    return intent
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
      balance: 4444.34
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
      balance: 4444.34
    )
  })
