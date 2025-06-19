import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 状态栏样式配置工具类
class StatusBarUtils {
  /// 应用的标准状态栏样式
  static const SystemUiOverlayStyle standardStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// 适用于浅色背景的状态栏样式（黑色图标）
  static const SystemUiOverlayStyle lightStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// 适用于深色背景的状态栏样式（白色图标）
  static const SystemUiOverlayStyle darkStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

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
