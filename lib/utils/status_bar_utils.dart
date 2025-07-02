import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// 状态栏样式配置工具类
class StatusBarUtils {
  /// 应用的标准状态栏样式
  static SystemUiOverlayStyle get standardStyle {
    if (Platform.isIOS) {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light, // iOS: 浅色背景，深色文字
      );
    } else {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android: 深色图标
        statusBarBrightness: Brightness.light,
      );
    }
  }

  /// 适用于浅色背景的状态栏样式（黑色图标/文字）
  static SystemUiOverlayStyle get lightStyle {
    if (Platform.isIOS) {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light, // iOS: 浅色背景，深色文字
      );
    } else {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android: 深色图标
        statusBarBrightness: Brightness.light,
      );
    }
  }

  /// 适用于深色背景的状态栏样式（白色图标/文字）
  static SystemUiOverlayStyle get darkStyle {
    if (Platform.isIOS) {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // iOS: 深色背景，浅色文字
      );
    } else {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android: 浅色图标
        statusBarBrightness: Brightness.dark,
      );
    }
  }

  /// 设置标准状态栏样式
  static void setStandardStyle() {
    SystemChrome.setSystemUIOverlayStyle(standardStyle);
  }

  /// 设置浅色状态栏样式
  static void setLightStyle() {
    SystemChrome.setSystemUIOverlayStyle(lightStyle);
  }

  /// 设置深色状态栏样式
  static void setDarkStyle() {
    SystemChrome.setSystemUIOverlayStyle(darkStyle);
  }

  /// 为Widget包装状态栏样式
  static Widget wrapWithStatusBarStyle(
    Widget child, {
    SystemUiOverlayStyle? style,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style ?? standardStyle,
      child: child,
    );
  }
}
