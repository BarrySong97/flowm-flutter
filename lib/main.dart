import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'utils/status_bar_utils.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 统一设置状态栏样式 - 全局生效
  StatusBarUtils.setStandardStyle();

  // 使用ProviderScope包裹应用程序，使Riverpod的Provider在整个应用中可用
  // 数据库实例现在由databaseProvider自己管理，支持动态重新创建
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
