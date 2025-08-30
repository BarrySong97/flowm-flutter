//
//  NumberFormatUtils.swift
//  FlowmWidget
//
//  Created by Claude on 2025/8/30.
//

import Foundation

/// 数字格式化工具类
struct NumberFormatUtils {

  // MARK: - Constants
  static let defaultLocale = "zh_CN"
  static let currencySymbol = "¥"
  static let largeAmountThreshold: Double = 10000000.0  // 10万

  // MARK: - Private formatters
  private static let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: defaultLocale)
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
  }()

  private static let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: defaultLocale)
    formatter.maximumFractionDigits = 2
    return formatter
  }()

  // MARK: - Public Methods

  /// 格式化货币显示
  /// 对于大于10万的金额使用k单位显示
  static func formatCurrency(_ amount: Double) -> String {
    if amount >= largeAmountThreshold {
      return "\((amount / 1000).formatted(.number.precision(.fractionLength(2))))k"
    } else {
      return currencyFormatter.string(from: NSNumber(value: amount)) ?? "0.00"
    }
  }

  /// 格式化完整货币显示（带货币符号）
  static func formatCurrencyWithSymbol(
    _ amount: Double, currencySymbol: String = NumberFormatUtils.currencySymbol
  ) -> String {
    return "\(currencySymbol) \(formatCurrency(amount))"
  }

  /// 格式化百分比显示
  static func formatPercentage(_ percentage: Double) -> String {
    return "\(Int(percentage.rounded()))%"
  }

  /// 格式化简单数字
  static func formatNumber(_ number: Double) -> String {
    return currencyFormatter.string(from: NSNumber(value: number)) ?? "0"
  }

  /// 格式化数字，万以上显示为k
  /// 例如：15000 -> ¥15k, 1500 -> ¥1,500
  static func formatCurrencyWithK(_ amount: Double, symbol: String = currencySymbol) -> String {
    if abs(amount) >= 10000 {
      // 超过万的数字用k表示
      let kValue = amount / 1000
      if kValue.truncatingRemainder(dividingBy: 1) == 0 {
        // 整数k值
        return "\(symbol)\(Int(kValue))k"
      } else {
        // 保留一位小数的k值
        return "\(symbol)\(String(format: "%.2f", kValue))k"
      }
    } else {
      // 小于万的正常显示
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      formatter.locale = Locale(identifier: "zh_CN")
      formatter.currencySymbol = symbol
      return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)0.00"
    }
  }

  /// 格式化数字，不带货币符号
  static func formatNumberWithK(_ amount: Double) -> String {
    if abs(amount) >= 10000 {
      let kValue = amount / 1000
      if kValue.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(Int(kValue))k"
      } else {
        return String(format: "%.2f", kValue) + "k"
      }
    } else {
      return numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
    }
  }

  /// 智能格式化，根据数值大小选择最合适的显示方式
  /// 万以上用k，十万以上可选择用w（万）
  static func smartFormatCurrency(
    _ amount: Double,
    symbol: String = currencySymbol,
    useWan: Bool = false,
    minFormatThreshold: Double = 10000
  ) -> String {

    // 如果金额低于阈值，直接使用正常格式
    if abs(amount) < minFormatThreshold {
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      formatter.locale = Locale(identifier: "zh_CN")
      formatter.currencySymbol = symbol
      return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)0.00"
    }

    if useWan && abs(amount) >= 100000 {
      // 十万以上用万表示
      let wanValue = amount / 10000
      if wanValue.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(symbol)\(Int(wanValue))万"
      } else {
        return "\(symbol)\(String(format: "%.2f", wanValue))万"
      }
    } else if abs(amount) >= 10000 {
      // 万以上用k表示
      let kValue = amount / 1000
      if kValue.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(symbol)\(Int(kValue))k"
      } else {
        return "\(symbol)\(String(format: "%.2f", kValue))k"
      }
    } else {
      // 小于万的正常显示
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      formatter.locale = Locale(identifier: "zh_CN")
      formatter.currencySymbol = symbol
      return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)0.00"
    }
  }
}
