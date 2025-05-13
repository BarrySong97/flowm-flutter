import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 使用ProviderScope包裹应用程序，使Riverpod的Provider在整个应用中可用
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
