# Flutter 项目模板 - 完整应用架构

现代化 Flutter 应用的完整项目模板结构和最佳实践指南。

## 项目概述

本模板提供了一个完整的 Flutter 应用架构，包含：
- 多平台支持（iOS/Android/Web/Desktop）
- 现代化状态管理（Riverpod）
- 类型安全的数据库操作（Drift ORM）
- 原生平台集成
- 响应式 UI 设计
- 代码生成支持

## 项目结构

```
project_root/
├── CLAUDE.md                    # 项目开发指导文档
├── README.md                    # 项目说明文档
├── pubspec.yaml                 # 依赖配置文件
├── analysis_options.yaml        # 代码分析配置
├── 
├── android/                     # Android 平台配置
│   ├── app/
│   │   ├── src/main/kotlin/     # Android 原生代码
│   │   │   └── com/example/app/
│   │   │       ├── MainActivity.kt
│   │   │       └── AppWidget.kt         # Android 小组件
│   │   └── src/main/res/        # Android 资源文件
│   │       ├── layout/          # 小组件布局
│   │       ├── drawable/        # 图标资源
│   │       ├── values/          # 字符串、样式配置
│   │       └── xml/             # 小组件配置
│   └── build.gradle            # Android 构建配置
│
├── ios/                        # iOS 平台配置
│   ├── Runner/                 # iOS 主应用
│   │   ├── AppDelegate.swift
│   │   └── Info.plist
│   ├── AppWidget/             # iOS 小组件扩展
│   │   ├── AppWidget.swift
│   │   ├── AppWidgetBundle.swift
│   │   ├── AppIntent.swift
│   │   └── Info.plist
│   └── Podfile                # CocoaPods 依赖配置
│
├── lib/                       # Flutter 主代码目录
│   ├── main.dart             # 应用入口点
│   ├── app.dart              # 应用主类
│   │
│   ├── config/               # 配置文件
│   │   ├── app_constants.dart    # 应用常量
│   │   └── theme.dart           # 主题配置
│   │
│   ├── db/                   # 数据库层（Drift ORM）
│   │   ├── app_database.dart        # 主数据库类
│   │   ├── connection.dart          # 数据库连接配置
│   │   ├── connection/              # 平台特定连接
│   │   │   ├── native.dart
│   │   │   ├── web.dart
│   │   │   └── unsupported.dart
│   │   ├── tables/                  # 数据表定义
│   │   │   ├── example_table.dart
│   │   │   └── ...
│   │   ├── dao/                     # 数据访问对象
│   │   │   ├── example_dao.dart
│   │   │   └── ...
│   │   └── seed_data.dart          # 初始数据
│   │
│   ├── state/                # 状态管理（Riverpod）
│   │   ├── database/             # 数据库提供者
│   │   │   └── database_provider.dart
│   │   ├── [feature]/            # 功能模块状态
│   │   │   ├── [feature]_providers.dart
│   │   │   └── [feature]_repository.dart
│   │   └── app/                  # 应用级状态
│   │       └── app_state_provider.dart
│   │
│   ├── navigation/           # 导航配置
│   │   └── app_router.dart      # GoRouter 路由配置
│   │
│   ├── pages/               # 页面/屏幕
│   │   ├── splash_page.dart        # 启动页
│   │   ├── main_screen.dart        # 主屏幕（带底部导航）
│   │   ├── home_page.dart          # 首页
│   │   ├── settings_page.dart      # 设置页面
│   │   └── [feature]/              # 功能特定页面
│   │       ├── [feature]_list_page.dart
│   │       ├── [feature]_detail_page.dart
│   │       └── [feature]_form_page.dart
│   │
│   ├── components/          # 可复用组件
│   │   ├── common/              # 通用组件
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── loading_widget.dart
│   │   │   ├── error_widget.dart
│   │   │   ├── bottom_sheet_base.dart
│   │   │   ├── custom_button.dart
│   │   │   ├── input_field.dart
│   │   │   └── ...
│   │   ├── layout/              # 布局组件
│   │   │   ├── responsive_layout.dart
│   │   │   └── scaffold_with_nav.dart
│   │   └── [feature]/           # 功能特定组件
│   │       ├── [feature]_card.dart
│   │       ├── [feature]_list_item.dart
│   │       └── ...
│   │
│   ├── models/              # 数据模型
│   │   ├── base_model.dart
│   │   ├── [feature]_model.dart
│   │   └── ...
│   │
│   ├── services/            # 服务层
│   │   ├── api_service.dart        # API 服务
│   │   ├── storage_service.dart    # 本地存储服务
│   │   ├── notification_service.dart # 通知服务
│   │   └── ...
│   │
│   ├── utils/               # 工具类
│   │   ├── constants.dart          # 常量定义
│   │   ├── extensions.dart         # 扩展方法
│   │   ├── validators.dart         # 验证工具
│   │   ├── formatters.dart         # 格式化工具
│   │   ├── helpers.dart            # 辅助函数
│   │   └── platform_utils.dart     # 平台工具
│   │
│   ├── hooks/               # Flutter Hooks（可选）
│   │   └── common_hooks.dart
│   │
│   └── l10n/                # 国际化（可选）
│       ├── app_localizations.dart
│       └── arb/
│           ├── app_en.arb
│           └── app_zh.arb
│
├── assets/                  # 静态资源
│   ├── images/                  # 图片资源
│   │   ├── icons/               # 图标
│   │   └── illustrations/       # 插图
│   ├── fonts/                   # 字体文件
│   └── data/                    # 静态数据文件
│
├── test/                    # 测试文件
│   ├── unit/                    # 单元测试
│   ├── widget/                  # 组件测试
│   └── integration/             # 集成测试
│
└── scripts/                 # 构建脚本
    ├── build.sh
    └── deploy.sh
```

## 核心架构模式

### 1. 数据库层（Drift ORM）

**特点：**
- 类型安全的 SQL 操作
- 代码生成支持
- 跨平台兼容（SQLite）
- 迁移策略支持

**核心文件结构：**
```dart
// lib/db/app_database.dart
@DriftDatabase(
  tables: [ExampleTable, ...],
  daos: [ExampleDao, ...],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
  );
}

// lib/db/tables/example_table.dart
class ExampleTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// lib/db/dao/example_dao.dart
@DriftAccessor(tables: [ExampleTable])
class ExampleDao extends DatabaseAccessor<AppDatabase> with _$ExampleDaoMixin {
  ExampleDao(AppDatabase db) : super(db);
  
  Stream<List<ExampleTableData>> watchAll() => select(exampleTable).watch();
  Future<ExampleTableData> create(ExampleTableCompanion data) => 
      into(exampleTable).insertReturning(data);
}
```

### 2. 状态管理（Riverpod）

**架构模式：**
- Repository Pattern：数据访问抽象
- Provider Pattern：状态管理
- 依赖注入：服务解耦

**示例结构：**
```dart
// lib/state/database/database_provider.dart
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

// lib/state/[feature]/[feature]_repository.dart
class FeatureRepository {
  final ExampleDao _dao;
  FeatureRepository(this._dao);
  
  Stream<List<ExampleTableData>> watchAll() => _dao.watchAll();
  Future<ExampleTableData> create(ExampleTableCompanion data) => _dao.create(data);
}

// lib/state/[feature]/[feature]_providers.dart
final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return FeatureRepository(database.exampleDao);
});

final featureListProvider = StreamProvider<List<ExampleTableData>>((ref) {
  final repository = ref.watch(featureRepositoryProvider);
  return repository.watchAll();
});
```

### 3. 导航系统（GoRouter）

**特点：**
- 声明式路由
- 深度链接支持
- 自定义过渡动画
- 类型安全参数传递

```dart
// lib/navigation/app_router.dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
        routes: [
          GoRoute(
            path: 'feature',
            builder: (context, state) => const FeatureListPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => FeatureDetailPage(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
```

### 4. 组件化架构

**分层结构：**
- **Pages（页面层）**：完整的屏幕/页面
- **Components（组件层）**：可复用的 UI 组件
- **Common（通用层）**：跨功能共享组件

**组织原则：**
```dart
// lib/components/common/custom_button.dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  
  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.style,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style ?? Theme.of(context).elevatedButtonTheme.style,
      child: Text(text),
    );
  }
}

// lib/components/layout/responsive_layout.dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 800) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

## 依赖配置模板

### 核心依赖（pubspec.yaml）

```yaml
name: app_template
description: Flutter application template
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # 状态管理
  flutter_riverpod: ^2.6.1
  hooks_riverpod: ^2.6.1      # 可选：如果使用 Flutter Hooks
  flutter_hooks: ^0.21.2      # 可选：如果使用 Flutter Hooks
  riverpod_annotation: ^2.3.5

  # 数据库
  drift: ^2.26.1
  sqlite3: ^2.4.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.8.3

  # 导航
  go_router: ^15.1.1

  # UI 组件
  cupertino_icons: ^1.0.6

  # 网络请求
  dio: ^5.4.0                 # 可选：HTTP 客户端
  
  # 本地存储
  shared_preferences: ^2.2.2  # 可选：简单键值存储
  
  # 工具类
  intl: ^0.20.2
  package_info_plus: ^8.0.0
  
  # 原生集成（可选）
  home_widget: ^0.8.0         # 原生小组件
  app_links: ^6.3.4           # 深度链接

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 代码生成
  drift_dev: ^2.26.1
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.11  # 如果使用 riverpod_annotation

  # 代码质量
  flutter_lints: ^6.0.0

  # 图标生成（可选）
  flutter_launcher_icons: ^0.14.0

# Flutter 配置
flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/data/
  
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont-Regular.ttf
        - asset: assets/fonts/CustomFont-Bold.ttf
          weight: 700

# 图标配置（可选）
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon.png"
```

## 开发工作流

### 1. 项目初始化
```bash
# 创建项目
flutter create --org com.example app_name

# 安装依赖
flutter pub get

# 初次代码生成
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. 开发命令
```bash
# 运行应用
flutter run                    # 调试模式
flutter run --release          # 发布模式

# 代码生成（开发期间）
flutter pub run build_runner watch  # 监听模式
flutter pub run build_runner build --delete-conflicting-outputs  # 一次性生成

# 代码分析和测试
flutter analyze
flutter test
```

### 3. 构建部署
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release

# Web
flutter build web --release

# Desktop（macOS/Windows/Linux）
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## 最佳实践

### 1. 文件命名规范
- 文件名使用 `snake_case`
- 类名使用 `PascalCase`
- 变量和方法使用 `camelCase`
- 常量使用 `UPPER_SNAKE_CASE`

### 2. 目录组织原则
- 按功能模块分组，而非按文件类型
- 共享组件放在 `common` 目录
- 平台特定代码使用条件导入

### 3. 状态管理规范
```dart
// Provider 命名规范
final dataProvider = StreamProvider<Data>((ref) => ...);
final dataRepositoryProvider = Provider<DataRepository>((ref) => ...);
final dataNotifierProvider = StateNotifierProvider<DataNotifier, DataState>((ref) => ...);

// Repository 模式
abstract class BaseRepository<T> {
  Stream<List<T>> watchAll();
  Future<T> getById(int id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(int id);
}
```

### 4. 数据库设计规范
```dart
// 基础表结构
abstract class BaseTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// 具体表实现
class ExampleTable extends BaseTable {
  @override
  String get tableName => 'examples';
  
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

### 5. 主题配置模板
```dart
// lib/config/theme.dart
class AppTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFB00020);
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
  );
}
```

## 多平台特性模板

### 1. 平台条件导入
```dart
// lib/utils/platform_utils.dart
import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_mobile.dart'
    if (dart.library.html) 'platform_utils_web.dart';

abstract class PlatformUtils {
  static PlatformUtils get instance => getInstance();
  
  bool get isMobile;
  bool get isWeb;
  bool get isDesktop;
  
  Future<String> getDeviceInfo();
}
```

### 2. 响应式设计
```dart
// lib/utils/responsive.dart
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;
      
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;
      
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;
}
```

## 测试模板

### 1. 单元测试
```dart
// test/unit/repository_test.dart
void main() {
  group('ExampleRepository', () {
    late MockExampleDao dao;
    late ExampleRepository repository;
    
    setUp(() {
      dao = MockExampleDao();
      repository = ExampleRepository(dao);
    });
    
    test('should return list of items', () async {
      // Arrange
      when(() => dao.watchAll()).thenAnswer((_) => Stream.value([]));
      
      // Act
      final result = repository.watchAll();
      
      // Assert
      expect(result, emitsInOrder([isEmpty]));
    });
  });
}
```

### 2. 组件测试
```dart
// test/widget/custom_button_test.dart
void main() {
  group('CustomButton', () {
    testWidgets('should display text', (tester) async {
      // Arrange
      const buttonText = 'Test Button';
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: CustomButton(text: buttonText, onPressed: () {}),
        ),
      );
      
      // Assert
      expect(find.text(buttonText), findsOneWidget);
    });
  });
}
```

## 总结

这个 Flutter 项目模板提供了：

1. **完整的架构结构**：清晰的分层和模块化组织
2. **现代化技术栈**：Riverpod + Drift + GoRouter 最佳实践
3. **多平台支持**：一套代码适配所有平台
4. **开发效率工具**：代码生成、热重载、类型安全
5. **可扩展设计**：易于添加新功能和模块
6. **最佳实践指南**：命名规范、文件组织、代码结构

适用于从小型到大型的各种 Flutter 应用开发项目。