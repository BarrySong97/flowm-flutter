# 版本信息生成指南

## 概述

本文档说明如何为 Flowm 应用生成版本更新信息，以便在应用的版本页面中显示。

## 文件结构

版本信息文件存储在以下位置：
```
lib/version/
├── version_1.1.0.json
├── version_1.2.0.json
└── version_x.x.x.json  # 新版本文件
```

## JSON 文件格式

每个版本信息文件应遵循以下格式：

```json
{
  "version": "1.2.0",
  "date": "2025-07-20",
  "title": "版本描述标题",
  "features": [
    {
      "type": "新功能",
      "description": "功能描述",
      "icon": "🔄"
    }
  ],
  "improvements": [
    {
      "type": "修复|优化|重构",
      "description": "改进描述",
      "icon": "🐛"
    }
  ]
}
```

### 字段说明

- **version**: 版本号（格式：x.x.x）
- **date**: 发布日期（格式：YYYY-MM-DD）
- **title**: 版本更新的简短描述
- **features**: 新功能列表
- **improvements**: 改进和修复列表

每个功能/改进项包含：
- **type**: 类型（新功能、修复、优化、重构等）
- **description**: 详细描述
- **icon**: 显示图标（emoji）

### 推荐图标

| 类型 | 图标 | 说明 |
|------|------|------|
| 新功能 | 🔄 ✨ ➕ 📝 💰 ✏️ | 根据功能性质选择 |
| 修复 | 🐛 🔧 | Bug修复和问题解决 |
| 优化 | 📊 ⚡ 🎨 | 性能优化和UI改进 |
| 重构 | 🔄 🧩 🎯 | 代码重构和架构调整 |

## 生成步骤

### 1. 分析 Git 提交记录

使用以下命令获取最近的提交信息：

```bash
# 获取最近两天的提交
git log --since="2 days ago" --oneline --pretty=format:"%h|%ad|%s" --date=short

# 获取特定时间范围的提交
git log --since="2025-07-19" --until="2025-07-20" --oneline --pretty=format:"%h|%ad|%s" --date=short
```

### 2. 创建版本文件

1. 在 `lib/version/` 目录下创建新的 JSON 文件
2. 文件名格式：`version_x.x.x.json`
3. 根据提交记录填写版本信息

### 3. 分类提交内容

根据提交信息的前缀进行分类：

- `feat(xxx):` → **新功能**
- `fix(xxx):` → **修复**
- `refactor(xxx):` → **重构**
- `style(xxx):` → **优化**
- `perf(xxx):` → **优化**

### 4. 更新代码引用

如果添加新版本，需要更新以下文件：

#### `lib/pages/version_page.dart`
在 `_loadVersionHistory()` 方法中添加新版本：

```dart
final versions = ['1.3.0', '1.2.0', '1.1.0']; // 新增版本号
```

### 5. 验证配置

确保 `pubspec.yaml` 中包含版本目录：

```yaml
flutter:
  assets:
    - lib/version/
```

## 示例工作流程

### 发布新版本 1.3.0

1. **收集提交信息**
   ```bash
   git log --since="1 week ago" --oneline
   ```

2. **创建版本文件**
   ```bash
   touch lib/version/version_1.3.0.json
   ```

3. **填写版本信息**
   根据提交记录整理功能和改进

4. **更新版本列表**
   在 `version_page.dart` 中添加 `'1.3.0'`

5. **测试验证**
   ```bash
   flutter run
   ```

## 注意事项

1. **版本号格式**: 必须遵循语义化版本控制（Semantic Versioning）
2. **日期格式**: 统一使用 YYYY-MM-DD 格式
3. **描述语言**: 使用简洁明了的中文描述
4. **图标选择**: 选择与功能匹配的emoji图标
5. **文件编码**: 确保文件使用 UTF-8 编码

## 自动化建议

可以考虑创建脚本来自动化版本信息生成：

1. 解析 Git 提交记录
2. 根据提交信息分类
3. 生成 JSON 文件模板
4. 自动更新版本列表

这样可以减少手动工作，提高版本发布效率。