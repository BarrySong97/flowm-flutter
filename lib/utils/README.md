# 状态栏样式使用指南

## 概述

本项目已统一管理状态栏样式，避免在路由切换时被覆盖的问题。

## 默认配置

- 全局状态栏样式在 `main.dart` 中设置
- 主题中的 AppBar 状态栏样式在 `config/theme.dart` 中配置
- 状态栏颜色：透明
- 状态栏图标颜色：深色（适合浅色背景）

## StatusBarUtils 工具类

### 预定义样式

- `StatusBarUtils.standardStyle`: 标准样式（深色图标，适合浅色背景）
- `StatusBarUtils.lightStyle`: 浅色样式（深色图标，适合浅色背景）
- `StatusBarUtils.darkStyle`: 深色样式（浅色图标，适合深色背景）

### 使用方法

#### 1. 全局设置（推荐）

```dart
// 在 main.dart 中已设置，无需额外操作
StatusBarUtils.setStandardStyle();
```

#### 2. 为特定页面临时更改

```dart
// 仅在特定页面需要不同状态栏样式时使用
@override
void initState() {
  super.initState();
  StatusBarUtils.setDarkStyle(); // 例如：深色背景页面
}

@override
void dispose() {
  StatusBarUtils.setStandardStyle(); // 恢复标准样式
  super.dispose();
}
```

#### 3. 使用 AnnotatedRegion 包装（推荐）

```dart
// 更优雅的方式，不会影响其他页面
@override
Widget build(BuildContext context) {
  return StatusBarUtils.wrapWithStatusBarStyle(
    Scaffold(
      // 页面内容
    ),
    style: StatusBarUtils.darkStyle, // 可选，默认使用标准样式
  );
}
```

## 注意事项

1. **避免在页面中直接使用** `SystemChrome.setSystemUIOverlayStyle()`
2. **避免在 AppBar 中设置** `systemOverlayStyle` 属性
3. 如需特殊样式，优先使用 `StatusBarUtils.wrapWithStatusBarStyle()`
4. 确保页面销毁时恢复标准样式（如使用方法 2）

## 迁移指南

如果发现某个页面的状态栏样式不正确：

1. 检查该页面是否有独立的状态栏设置
2. 移除页面中的 `SystemChrome.setSystemUIOverlayStyle()` 调用
3. 移除 AppBar 中的 `systemOverlayStyle` 属性
4. 如需特殊样式，使用 `StatusBarUtils` 提供的方法
