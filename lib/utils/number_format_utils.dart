import 'package:intl/intl.dart';
import '../config/app_constants.dart';

/// 数字格式化工具类
class NumberFormatUtils {
  static final NumberFormat _currencyFormat = NumberFormat(
    '#,##0.00',
    AppConstants.defaultLocale,
  );

  /// 格式化货币显示
  /// 对于大于10万的金额使用k单位显示
  static String formatCurrency(double amount) {
    if (amount >= AppConstants.largeAmountThreshold) {
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return _currencyFormat.format(amount);
    }
  }

  /// 格式化完整货币显示（带货币符号）
  static String formatCurrencyWithSymbol(double amount, {String? currencySymbol}) {
    final symbol = currencySymbol ?? AppConstants.currencySymbol;
    return '$symbol ${formatCurrency(amount)}';
  }

  /// 格式化百分比显示
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(0)}%';
  }

  /// 格式化简单数字
  static String formatNumber(double number) {
    return _currencyFormat.format(number);
  }

  /// 格式化数字，万以上显示为k
  /// 例如：15000 -> 15k, 1500 -> ¥1,500
  static String formatCurrencyWithK(double amount, {String symbol = AppConstants.currencySymbol}) {
    if (amount.abs() >= 10000) {
      // 超过万的数字用k表示
      final kValue = amount / 1000;
      if (kValue % 1 == 0) {
        // 整数k值
        return '$symbol${kValue.toInt()}k';
      } else {
        // 保留一位小数的k值
        return '$symbol${kValue.toStringAsFixed(2)}k';
      }
    } else {
      // 小于万的正常显示
      final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: symbol);
      return formatter.format(amount);
    }
  }

  /// 格式化数字，不带货币符号
  static String formatNumberWithK(double amount) {
    if (amount.abs() >= 10000) {
      final kValue = amount / 1000;
      if (kValue % 1 == 0) {
        return '${kValue.toInt()}k';
      } else {
        return '${kValue.toStringAsFixed(2)}k';
      }
    } else {
      final formatter = NumberFormat('#,##0.##', 'zh_CN');
      return formatter.format(amount);
    }
  }

  /// 智能格式化，根据数值大小选择最合适的显示方式
  /// 万以上用k，十万以上可选择用w（万）
  /// [minFormatThreshold] 最小格式化阈值，低于此值不使用k或万格式化
  static String smartFormatCurrency(double amount,
      {String symbol = AppConstants.currencySymbol, bool useWan = false, double? minFormatThreshold}) {
    final threshold = minFormatThreshold ?? 10000; // 默认万以上才格式化

    // 如果金额低于阈值，直接使用正常格式
    if (amount.abs() < threshold) {
      final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: symbol);
      return formatter.format(amount);
    }

    if (useWan && amount.abs() >= 100000) {
      // 十万以上用万表示
      final wanValue = amount / 10000;
      if (wanValue % 1 == 0) {
        return '$symbol${wanValue.toInt()}万';
      } else {
        return '$symbol${wanValue.toStringAsFixed(2)}万';
      }
    } else if (amount.abs() >= 10000) {
      // 万以上用k表示
      final kValue = amount / 1000;
      if (kValue % 1 == 0) {
        return '$symbol${kValue.toInt()}k';
      } else {
        return '$symbol${kValue.toStringAsFixed(2)}k';
      }
    } else {
      // 小于万的正常显示
      final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: symbol);
      return formatter.format(amount);
    }
  }
}
