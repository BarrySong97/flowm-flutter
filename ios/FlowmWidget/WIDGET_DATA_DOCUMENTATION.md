# iOS Widget 数据接收文档

本文档描述了三个主要Widget如何从Flutter应用接收数据。

## 数据源配置

所有Widget都使用相同的数据源：
- **UserDefaults Suite**: `"group.flowm"`
- **刷新频率**: 15分钟自动刷新
- **数据格式**: 字符串格式存储，Widget内部转换为Double

## 1. FlowmWidget

### 描述
显示月度财务概览，支持小尺寸和中等尺寸。

### 支持的Widget尺寸
- **systemSmall**: 月份标题 + 垂直布局的收入/支出/结余
- **systemMedium**: 当月收支概览 + 每日支出柱状图（过去10天）

### 接收的数据键值

| 键名 | 数据类型 | 描述 | 示例值 |
|------|----------|------|--------|
| `expense` | String | 当月总支出 | "12345.67" |
| `income` | String | 当月总收入 | "23456.78" |
| `balance` | String | 当月结余 | "11111.11" |

### 数据结构
```swift
struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let expense: Double        // 从 UserDefaults["expense"] 转换
  let income: Double         // 从 UserDefaults["income"] 转换
  let balance: Double        // 从 UserDefaults["balance"] 转换
  let dailyExpenses: [DailyExpenseItem]  // 模拟数据（过去10天）
}
```

### 每日支出数据（模拟数据）
```swift
struct DailyExpenseItem: Identifiable {
  let id: Int
  let date: Date
  let dayName: String        // "周一", "周二"
  let dateString: String     // "9/1", "9/2"
  let amount: Double         // 200-2000随机值
}
```

### Flutter应用需要提供的数据
```dart
// 写入UserDefaults示例
final prefs = await SharedPreferences.getInstance();
await prefs.setString('expense', '12345.67');
await prefs.setString('income', '23456.78'); 
await prefs.setString('balance', '11111.11');

// 或使用home_widget插件
await HomeWidget.saveWidgetData<String>('expense', '12345.67');
await HomeWidget.saveWidgetData<String>('income', '23456.78');
await HomeWidget.saveWidgetData<String>('balance', '11111.11');
await HomeWidget.updateWidget(name: 'FlowmWidget');
```

---

## 2. ExpensePieChartWidget

### 描述
显示支出分类的饼图分布，仅支持中等尺寸。

### 支持的Widget尺寸
- **systemMedium**: 左侧饼图 + 右侧分类图例

### 接收的数据键值

| 键名 | 数据类型 | 描述 | 示例值 |
|------|----------|------|--------|
| 暂无 | - | 当前使用模拟数据 | - |

### 数据结构
```swift
struct ExpensePieChartEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let totalExpense: Double                    // 总支出（模拟数据）
  let categories: [ExpenseCategoryItem]       // 分类数据（模拟数据）
}

struct ExpenseCategoryItem: Identifiable {
  let id: Int
  let name: String           // "餐饮", "交通", "购物"等
  let amount: Double         // 该分类金额
  let percentage: Double     // 占比百分比
  let color: Color          // 显示颜色
}
```

### 当前模拟数据
- **餐饮**: ¥2,800 (红色)
- **交通**: ¥1,200 (蓝色)
- **购物**: ¥1,800 (绿色)
- **娱乐**: ¥800 (橙色)
- **医疗**: ¥600 (紫色)
- **教育**: ¥900 (青色)
- **其他**: ¥400 (灰色)

### 待实现的数据接收
```dart
// 未来需要Flutter提供的分类数据格式
final categoryData = {
  'food': 2800.0,      // 餐饮
  'transport': 1200.0, // 交通  
  'shopping': 1800.0,  // 购物
  'entertainment': 800.0, // 娱乐
  'medical': 600.0,    // 医疗
  'education': 900.0,  // 教育
  'other': 400.0       // 其他
};

// 可以考虑使用JSON格式存储
await HomeWidget.saveWidgetData<String>('expense_categories', 
  jsonEncode(categoryData));
```

---

## 3. AssetsOverviewWidget

### 描述
显示资产概览信息，支持中等和大尺寸。

### 支持的Widget尺寸
- **systemMedium**: 资产概览 + 2个主要资产卡片
- **systemLarge**: 完整资产概览 + 6个资产卡片（2x3网格）

### 接收的数据键值

| 键名 | 数据类型 | 描述 | 示例值 |
|------|----------|------|--------|
| 暂无 | - | 当前使用模拟数据 | - |

### 数据结构
```swift
struct AssetsOverviewEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let netAssets: Double                    // 净资产
  let totalAssets: Double                  // 总资产
  let totalLiabilities: Double             // 总负债
  let assets: [AssetOverviewItem]          // 资产明细
}

struct AssetOverviewItem {
  let id: Int
  let name: String              // "现金", "银行卡", "股票"等
  let amount: Double            // 资产金额
  let percentage: Double        // 占比百分比
  let backgroundColor: Color    // 背景颜色
}
```

### 当前模拟数据
- **净资产**: ¥150,000
- **总资产**: ¥200,000  
- **总负债**: ¥50,000

### 资产分类
- **现金**: ¥12,000 (4.0%)
- **银行卡**: ¥88,000 (29.3%)
- **股票**: ¥60,000 (20.0%)
- **基金**: ¥40,000 (13.3%)
- **债券**: ¥25,000 (8.3%)
- **定期存款**: ¥75,000 (25.0%)

### 待实现的数据接收
```dart
// 未来需要Flutter提供的资产数据格式
final assetData = {
  'net_assets': 150000.0,
  'total_assets': 200000.0,
  'total_liabilities': 50000.0,
  'asset_items': [
    {'name': '现金', 'amount': 12000.0},
    {'name': '银行卡', 'amount': 88000.0},
    {'name': '股票', 'amount': 60000.0},
    {'name': '基金', 'amount': 40000.0},
    {'name': '债券', 'amount': 25000.0},
    {'name': '定期存款', 'amount': 75000.0},
  ]
};

// JSON格式存储
await HomeWidget.saveWidgetData<String>('assets_overview', 
  jsonEncode(assetData));
```

---

## 数据更新流程

### 1. Flutter应用端
```dart
// 1. 计算或获取最新数据
final expense = calculateMonthlyExpense();
final income = calculateMonthlyIncome();
final balance = income - expense;

// 2. 保存到UserDefaults
await HomeWidget.saveWidgetData<String>('expense', expense.toString());
await HomeWidget.saveWidgetData<String>('income', income.toString());
await HomeWidget.saveWidgetData<String>('balance', balance.toString());

// 3. 通知Widget更新
await HomeWidget.updateWidget(name: 'FlowmWidget');
```

### 2. Widget端
```swift
// Provider中读取数据
let userDefaults = UserDefaults(suiteName: "group.flowm")
let expense = Double(userDefaults?.string(forKey: "expense") ?? "") ?? 0.0
let income = Double(userDefaults?.string(forKey: "income") ?? "") ?? 0.0
let balance = Double(userDefaults?.string(forKey: "balance") ?? "") ?? 0.0
```

## 注意事项

1. **数据类型转换**: UserDefaults存储字符串，Widget内部需要转换为Double
2. **默认值处理**: 如果读取失败，使用0.0作为默认值
3. **App Group**: 确保Flutter应用和Widget都配置了相同的App Group ID
4. **数据一致性**: 建议在数据更新时同时更新所有相关的键值
5. **模拟数据**: ExpensePieChartWidget和AssetsOverviewWidget当前使用模拟数据，需要后续接入真实数据源

## 未来改进

1. **实时数据**: ExpensePieChartWidget和AssetsOverviewWidget接入真实数据
2. **JSON格式**: 使用JSON格式传输复杂数据结构
3. **错误处理**: 增加数据校验和错误处理机制
4. **缓存策略**: 实现数据缓存和增量更新