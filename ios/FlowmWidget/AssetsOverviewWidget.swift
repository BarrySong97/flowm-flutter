//
//  AssetsOverviewWidget.swift
//  FlowmWidget
//
//  Created by Claude on 2025/8/30.
//

import SwiftUI
import WidgetKit

// MARK: - Assets Overview Widget

struct AssetsOverviewProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> AssetsOverviewEntry {
    AssetsOverviewEntry(
      date: Date(),
      configuration: ConfigurationAppIntent(),
      netAssets: 150000.0,
      totalAssets: 200000.0,
      totalLiabilities: 50000.0,
      assets: mockAssets()
    )
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async
    -> AssetsOverviewEntry
  {
    AssetsOverviewEntry(
      date: Date(),
      configuration: configuration,
      netAssets: 150000.0,
      totalAssets: 200000.0,
      totalLiabilities: 50000.0,
      assets: mockAssets()
    )
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    AssetsOverviewEntry
  > {
    print("🟢 AssetsOverviewWidget timeline() called")
    
    let userDefaults = UserDefaults(suiteName: "group.flowm")
    let assetsOverviewDataString = userDefaults?.string(forKey: "assetsOverviewData") ?? ""
    
    print("🟢 AssetsOverviewWidget raw data: '\(assetsOverviewDataString)'")
    
    var netAssets: Double = 150000.0
    var totalAssets: Double = 200000.0
    var totalLiabilities: Double = 50000.0
    var assets: [AssetOverviewItem] = []
    
    // Try to parse real data from UserDefaults
    if !assetsOverviewDataString.isEmpty {
      print("🟢 AssetsOverviewWidget: Attempting to parse JSON data")
      
      if let data = assetsOverviewDataString.data(using: .utf8) {
        do {
          if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("🟢 AssetsOverviewWidget: Successfully parsed JSON object")
            
            // Extract summary data
            if let netAssetsValue = jsonObject["netAssets"] as? Double {
              netAssets = netAssetsValue
              print("🟢 AssetsOverviewWidget: netAssets = \(netAssets)")
            }
            
            if let totalAssetsValue = jsonObject["totalAssets"] as? Double {
              totalAssets = totalAssetsValue
              print("🟢 AssetsOverviewWidget: totalAssets = \(totalAssets)")
            }
            
            if let totalLiabilitiesValue = jsonObject["totalLiabilities"] as? Double {
              totalLiabilities = totalLiabilitiesValue
              print("🟢 AssetsOverviewWidget: totalLiabilities = \(totalLiabilities)")
            }
            
            // Extract asset items
            if let assetItems = jsonObject["assetItems"] as? [[String: Any]] {
              print("🟢 AssetsOverviewWidget: Found \(assetItems.count) asset items")
              
              let backgroundColor = Color(red: 0.91, green: 0.96, blue: 0.91)
              
              for item in assetItems {
                if let id = item["id"] as? Int,
                   let name = item["name"] as? String,
                   let amount = item["amount"] as? Double,
                   let percentage = item["percentage"] as? Double {
                  
                  let assetItem = AssetOverviewItem(
                    id: id,
                    name: name,
                    amount: amount,
                    percentage: percentage,
                    backgroundColor: backgroundColor
                  )
                  assets.append(assetItem)
                  
                  print("🟢 AssetsOverviewWidget: Added asset '\(name)' with amount \(amount)")
                }
              }
            }
          }
        } catch {
          print("🟢 AssetsOverviewWidget: JSON parsing failed - \(error)")
        }
      }
    }
    
    // Use mock data if real data is not available
    if assets.isEmpty {
      print("🟢 AssetsOverviewWidget: Using mock data")
      assets = mockAssets()
      netAssets = 150000.0
      totalAssets = 200000.0
      totalLiabilities = 50000.0
    } else {
      print("🟢 AssetsOverviewWidget: Using real data with \(assets.count) assets")
    }
    
    let entry = AssetsOverviewEntry(
      date: Date(),
      configuration: configuration,
      netAssets: netAssets,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      assets: assets
    )

    print("🟢 AssetsOverviewWidget: Entry created successfully")

    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    
    print("🟢 AssetsOverviewWidget: Timeline created, next update: \(nextUpdate)")
    return timeline
  }

  private func mockAssets() -> [AssetOverviewItem] {
    let backgroundColor = Color(red: 0.91, green: 0.96, blue: 0.91)  // 0xFFE8F5E9
    let totalAssets = 300000.0  // 总资产

    return [
      AssetOverviewItem(
        id: 1,
        name: "现金",
        amount: 12000.0,
        percentage: (12000.0 / totalAssets) * 100, // 4.0%
        backgroundColor: backgroundColor
      ),
      AssetOverviewItem(
        id: 2,
        name: "银行卡",
        amount: 88000.0,
        percentage: (88000.0 / totalAssets) * 100, // 29.3%
        backgroundColor: backgroundColor
      ),
      AssetOverviewItem(
        id: 3,
        name: "股票",
        amount: 60000.0,
        percentage: (60000.0 / totalAssets) * 100, // 20.0%
        backgroundColor: backgroundColor
      ),
      AssetOverviewItem(
        id: 4,
        name: "基金",
        amount: 40000.0,
        percentage: (40000.0 / totalAssets) * 100, // 13.3%
        backgroundColor: backgroundColor
      ),
      AssetOverviewItem(
        id: 5,
        name: "债券",
        amount: 25000.0,
        percentage: (25000.0 / totalAssets) * 100, // 8.3%
        backgroundColor: backgroundColor
      ),
      AssetOverviewItem(
        id: 6,
        name: "定期存款",
        amount: 75000.0,
        percentage: (75000.0 / totalAssets) * 100, // 25.0%
        backgroundColor: backgroundColor
      ),
    ]
  }
}

struct AssetsOverviewEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let netAssets: Double
  let totalAssets: Double
  let totalLiabilities: Double
  let assets: [AssetOverviewItem]
}

struct AssetOverviewItem {
  let id: Int
  let name: String
  let amount: Double
  let percentage: Double
  let backgroundColor: Color
}

struct AssetsOverviewWidgetEntryView: View {
  @Environment(\.widgetFamily) var widgetFamily
  var entry: AssetsOverviewProvider.Entry

  private func formatCurrency(_ value: Double) -> String {
    return NumberFormatUtils.formatCurrency(value)
  }

  private func formatPercentage(_ value: Double) -> String {
    return String(format: "%.1f%%", value)
  }

  var body: some View {
    print("🟢 AssetsOverviewWidgetEntryView rendering - netAssets: \(entry.netAssets), assets count: \(entry.assets.count)")
    
    return Group {
      switch widgetFamily {
      case .systemMedium:
        mediumAssetsOverview
      case .systemLarge:
        largeAssetsOverview
      default:
        mediumAssetsOverview
      }
    }
  }

  private var mediumAssetsOverview: some View {
    VStack(alignment: .leading, spacing: 12) {

      // Overview Row
      HStack {
        overviewItem("净资产", entry.netAssets, .purple)
        Spacer()
        overviewItem("总资产", entry.totalAssets, .blue)
        Spacer()
        overviewItem("总负债", entry.totalLiabilities, .orange)
      }

      // Assets Grid (2 cards for medium)
      HStack(spacing: 8) {
        ForEach(Array(entry.assets.prefix(2).enumerated()), id: \.offset) { _, asset in
          assetCard(asset)
        }
      }
    }
    .padding(0)
  }

  private var largeAssetsOverview: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Title
      HStack {
        Text("资产概览")
          .font(.headline)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        Spacer()
      }

      // Overview Row
      HStack {
        overviewItem("净资产", entry.netAssets, .purple)
        Spacer()
        overviewItem("总资产", entry.totalAssets, .blue)
        Spacer()
        overviewItem("总负债", entry.totalLiabilities, .orange)
      }

      // Assets Grid (2x3 for large - 6 assets, 3 rows 2 columns)
      VStack(spacing: 6) {
        HStack(spacing: 6) {
          assetCard(entry.assets[0])
          assetCard(entry.assets[1])
        }
        HStack(spacing: 6) {
          assetCard(entry.assets[2])
          assetCard(entry.assets[3])
        }
        HStack(spacing: 6) {
          assetCard(entry.assets[4])
          assetCard(entry.assets[5])
        }
      }
    }
    .padding(.vertical, 2)
    .padding(.horizontal, 2)
  }

  private func overviewItem(_ label: String, _ amount: Double, _ color: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption2)
        .foregroundColor(.secondary)
      Text(formatCurrency(amount))
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(color)
    }
  }

  private func assetCard(_ asset: AssetOverviewItem) -> some View {
    VStack(alignment: .leading) {
      HStack {
        Text(asset.name)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.primary)
        Spacer()
        Text(formatPercentage(asset.percentage))
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.blue)
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .background(Color.blue.opacity(0.15))
          .cornerRadius(4)
      }
      Spacer()

      Text(formatCurrency(asset.amount))
        .font(.system(size: widgetFamily == .systemLarge ? 14 : 16, weight: .semibold))
        .foregroundColor(.primary)
    }
    .padding(8)
    .frame(maxWidth: .infinity, minHeight: 70)
    .background(asset.backgroundColor)
    .cornerRadius(8)
  }
}

struct AssetsOverviewWidget: Widget {
  let kind: String = "AssetsOverviewWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: ConfigurationAppIntent.self, provider: AssetsOverviewProvider()
    ) { entry in
      AssetsOverviewWidgetEntryView(entry: entry)
        .containerBackground(.white, for: .widget)
    }
    .configurationDisplayName("资产概览")
    .description("显示净资产、总资产、总负债和主要资产明细。")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

#Preview(
  "Assets Overview Medium",
  as: .systemMedium,
  widget: {
    AssetsOverviewWidget()
  },
  timeline: {
    AssetsOverviewEntry(
      date: .now,
      configuration: ConfigurationAppIntent(),
      netAssets: 150000.0,
      totalAssets: 200000.0,
      totalLiabilities: 50000.0,
      assets: [
        AssetOverviewItem(
          id: 1, name: "现金", amount: 12000.0, percentage: 4.0,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 2, name: "银行卡", amount: 88000.0, percentage: 29.3,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 3, name: "股票", amount: 60000.0, percentage: 20.0,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 4, name: "基金", amount: 40000.0, percentage: 13.3,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 5, name: "债券", amount: 25000.0, percentage: 8.3,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 6, name: "定期存款", amount: 75000.0, percentage: 25.0,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
      ]
    )
  })

#Preview(
  "Assets Overview Large",
  as: .systemLarge,
  widget: {
    AssetsOverviewWidget()
  },
  timeline: {
    AssetsOverviewEntry(
      date: .now,
      configuration: ConfigurationAppIntent(),
      netAssets: 150000.0,
      totalAssets: 200000.0,
      totalLiabilities: 50000.0,
      assets: [
        AssetOverviewItem(
          id: 1, name: "现金", amount: 12000.0, percentage: 4.0,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 2, name: "银行卡", amount: 88000.0, percentage: 29.3,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 3, name: "股票", amount: 60000.0, percentage: 20.0,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 4, name: "基金", amount: 40000.0, percentage: 13.3,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 5, name: "债券", amount: 25000.0, percentage: 8.3,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
        AssetOverviewItem(
          id: 6, name: "定期存款", amount: 75000.0, percentage: 25.0,
          backgroundColor: Color(red: 0.91, green: 0.96, blue: 0.91)),
      ]
    )
  })
