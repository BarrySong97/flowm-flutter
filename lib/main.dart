import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'db/app_database.dart';
import 'state/database/database_provider.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  final database = AppDatabase();

  // 使用ProviderScope包裹应用程序，使Riverpod的Provider在整个应用中可用
  // 并且提供数据库实例
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const MyApp(),
    ),
  );
}
