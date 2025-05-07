import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3); // 主色调
  static const Color primaryLightColor = Color(0xFF64B5F6); // 主色调（轻）
  static const Color primaryDarkColor = Color(0xFF1976D2); // 主色调（深）

  // Secondary colors
  static const Color secondaryColor = Color(0xFF4CAF50); // 次要色调
  static const Color secondaryLightColor = Color(0xFF81C784); // 次要色调（轻）
  static const Color secondaryDarkColor = Color(0xFF388E3C); // 次要色调（深）

  // Background colors
  static const Color backgroundColor = Color(0xFFFFFFFF); // 背景色
  static const Color surfaceColor = Color(0xFFF5F5F5); // 表面色
  static const Color cardColor = Color(0xFFFFFFFF); // 卡片色

  // Text colors
  static const Color primaryTextColor = Color(0xFF212121); // 主要文本色
  static const Color secondaryTextColor = Color(0xFF757575); // 次要文本色
  static const Color disabledTextColor = Color(0xFFBDBDBD); // 禁用文本色

  // Status colors
  static const Color successColor = Color(0xFF4CAF50); // 成功色
  static const Color errorColor = Color(0xFFE53935); // 错误色
  static const Color warningColor = Color(0xFFFFA726); // 警告色
  static const Color infoColor = Color(0xFF29B6F6); // 信息色

  // Get the light theme
  static ThemeData get lightTheme {
    return ThemeData(
      // 基础颜色
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),

      // 背景颜色
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,

      // AppBar主题
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // 禁用水波纹效果
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  // Get the dark theme (如果需要暗色主题，可以在这里添加)
  static ThemeData get darkTheme {
    // TODO: 实现暗色主题
    return lightTheme;
  }
}
