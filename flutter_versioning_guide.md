# Flutter 版本定义指南

## 版本号格式

在 Flutter 项目的 `pubspec.yaml` 文件中，版本定义遵循以下格式：

```yaml
version: 1.0.0+1
```

## 版本号组成部分

### 1. 语义化版本号 (Semantic Version)
格式：`MAJOR.MINOR.PATCH`

- **MAJOR (主版本号)**：不兼容的 API 修改
- **MINOR (次版本号)**：向下兼容的功能性新增
- **PATCH (修订号)**：向下兼容的问题修正

### 2. 构建号 (Build Number)
位于 `+` 号后面的数字，用于区分同一版本的不同构建

```yaml
version: 1.2.3+42
#        ↑   ↑ ↑ ↑
#        |   | | └── 构建号 (Build Number)
#        |   | └──── 修订号 (Patch)
#        |   └────── 次版本号 (Minor)
#        └────────── 主版本号 (Major)
```

## 平台特定映射

### Android
- `version name` = `1.2.3` (语义化版本部分)
- `version code` = `42` (构建号部分)

在 `android/app/build.gradle` 中：
```gradle
android {
    defaultConfig {
        versionName "1.2.3"  // 对应 pubspec.yaml 中的 1.2.3
        versionCode 42       // 对应 pubspec.yaml 中的 +42
    }
}
```

### iOS
- `CFBundleShortVersionString` = `1.2.3` (显示给用户的版本)
- `CFBundleVersion` = `42` (内部构建号)

在 `ios/Runner/Info.plist` 中：
```xml
<key>CFBundleShortVersionString</key>
<string>1.2.3</string>
<key>CFBundleVersion</key>
<string>42</string>
```

## 版本管理最佳实践

### 1. 语义化版本示例
```yaml
# 初始版本
version: 1.0.0+1

# Bug 修复
version: 1.0.1+2

# 新功能添加
version: 1.1.0+3

# 重大更改（不向下兼容）
version: 2.0.0+4
```

### 2. 构建号管理
- 每次构建都应该递增构建号
- 构建号必须是整数
- 即使版本号不变，构建号也要递增

```yaml
# 同一版本的不同构建
version: 1.0.0+1   # 第一次构建
version: 1.0.0+2   # 修复后重新构建
version: 1.0.0+3   # 再次构建
```

### 3. 发布流程建议
```yaml
# 开发阶段
version: 1.0.0-dev+1
version: 1.0.0-dev+2

# 测试阶段
version: 1.0.0-beta+3
version: 1.0.0-beta+4

# 发布候选
version: 1.0.0-rc+5

# 正式发布
version: 1.0.0+6
```

## 命令行覆盖

可以在构建时覆盖版本信息：

```bash
# 覆盖版本名称
flutter build apk --build-name=1.0.2

# 覆盖构建号
flutter build apk --build-number=42

# 同时覆盖两者
flutter build apk --build-name=1.0.2 --build-number=42
```

## 获取版本信息

### 在代码中获取
```dart
import 'package:package_info_plus/package_info_plus.dart';

Future<void> getVersionInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  
  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;      // 1.0.0
  String buildNumber = packageInfo.buildNumber; // 1
}
```

### 注意事项
1. **构建号必须递增**：应用商店要求每次上传的构建号都必须大于之前的版本
2. **版本号规范**：遵循语义化版本规范有助于用户理解更新内容
3. **平台一致性**：确保 Android 和 iOS 平台使用相同的版本逻辑
4. **自动化**：考虑使用 CI/CD 自动管理版本号递增

## 常见错误

### 1. 构建号重复
```yaml
# ❌ 错误：重复使用构建号
version: 1.0.0+1
# 修改后仍使用相同构建号
version: 1.0.1+1  # 应该是 +2
```

### 2. 版本号格式错误
```yaml
# ❌ 错误格式
version: v1.0.0+1    # 不要加前缀
version: 1.0+1       # 缺少修订号
version: 1.0.0.1     # 使用点而不是加号

# ✅ 正确格式
version: 1.0.0+1
```

### 3. 构建号非数字
```yaml
# ❌ 错误：构建号必须是数字
version: 1.0.0+beta1

# ✅ 正确：使用预发布标识符
version: 1.0.0-beta+1
```