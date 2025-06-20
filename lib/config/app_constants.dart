import 'package:flutter/material.dart';

/// 应用级常量配置
class AppConstants {
  // 饼图颜色配置
  static const List<Color> pieChartColors = [
    Color(0xFFD32F2F), // Colors.red.shade800
    Color(0xFFFF9800), // Colors.orange
    Color(0xFF4CAF50), // Colors.green
    Color(0xFFE91E63), // Colors.pink
    Color(0xFF2196F3), // Colors.blue
    Color(0xFF64B5F6), // Colors.blue.shade300
    Color(0xFF9C27B0), // Colors.purple
    Color(0xFFBA68C8), // Colors.purple.shade300
    Color(0xFFFFC107), // Colors.amber
    Color(0xFF3F51B5), // Colors.indigo
    Color(0xFFFF5722), // Colors.deepOrange
    Color(0xFF795548), // Colors.brown
    Color(0xFFEF5350), // Colors.red.shade400
  ];

  // 收入页面颜色配置
  static const List<Color> incomeColors = [
    Color(0xFF2E7D32), // Colors.green.shade800
    Color(0xFF00695C), // Colors.teal
    Color(0xFF1976D2), // Colors.blue
    Color(0xFF689F38), // Colors.lightGreen
    Color(0xFF00ACC1), // Colors.cyan
    Color(0xFF4DD0E1), // Colors.cyan.shade300
    Color(0xFF303F9F), // Colors.indigo
    Color(0xFF7986CB), // Colors.indigo.shade300
    Color(0xFFAFB42B), // Colors.lime
    Color(0xFF455A64), // Colors.blueGrey
    Color(0xFF0288D1), // Colors.lightBlue
    Color(0xFF5D4037), // Colors.brown
    Color(0xFF66BB6A), // Colors.green.shade400
  ];

  // 数值格式化
  static const double largeAmountThreshold = 100000;
  static const String currencySymbol = '¥';
  static const String defaultLocale = 'zh_CN';

  // UI配置
  static const double defaultBorderRadius = 6.0;
  static const double defaultSpacing = 12.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 16.0;

  // 统计卡片高度
  static const double statsCardHeight = 54.0;
  static const double chartHeight = 240.0;
  static const double pieChartHeight = 260.0;

  // 加载状态配置
  static const double loadingHeight = 660.0;
  static const double loadingStrokeWidth = 2.0;
}
