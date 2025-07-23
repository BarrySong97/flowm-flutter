# Time Range Feature Integration Guide

当需要给详情页面添加时间范围选择功能时（参考 expenses_page.dart），请按照以下步骤操作：

## Step 1: 导入必要的依赖项

```dart
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/components/chart/fullscreen_chart_page.dart';
```

## Step 2: 移除本地状态提供者

移除任何局部的providers，改用全局的：
- 移除本地的 `selectedMonthProvider` → 使用全局的 `selectedMonthProvider`  
- 移除本地的 `selectedTimeRangeTypeProvider` → 使用全局的 `selectedTimeRangeTypeProvider`

```dart
// 删除类似这样的本地provider定义：
final localSelectedMonthProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final localSelectedTimeRangeTypeProvider = StateProvider.autoDispose<String>((ref) => 'month');
```

## Step 3: 更新数据提供者

修改现有的数据提供者以支持多种时间范围：

```dart
// 修改前：仅支持月份
final dataProvider = FutureProvider.autoDispose((ref) async {
  final selectedDate = ref.watch(selectedMonthProvider);
  final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  // ... 获取数据
});

// 修改后：支持多种时间范围
final dataProvider = FutureProvider.autoDispose((ref) async {
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);
  
  DateTime startDate, endDate;
  
  switch (timeRangeType) {
    case '90days':
      startDate = DateTime.now().subtract(const Duration(days: 90));
      endDate = DateTime.now();
      break;
    case '60days':
      startDate = DateTime.now().subtract(const Duration(days: 60));
      endDate = DateTime.now();
      break;
    case 'year':
      startDate = DateTime(selectedDate.year, 1, 1);
      endDate = DateTime(selectedDate.year, 12, 31);
      break;
    case 'all':
      startDate = DateTime(2020, 1, 1);
      endDate = DateTime.now();
      break;
    case 'month':
    default:
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      break;
  }
  
  // ... 使用 startDate 和 endDate 获取数据
});
```

## Step 4: 添加辅助方法

在你的 StatefulWidget 中添加这些辅助方法：

```dart
DateTime? _getStartDateForChart() {
  final selectedMonth = ref.read(selectedMonthProvider);
  final timeRangeType = ref.read(selectedTimeRangeTypeProvider);
  
  switch (timeRangeType) {
    case '90days':
      return DateTime.now().subtract(const Duration(days: 90));
    case '60days':
      return DateTime.now().subtract(const Duration(days: 60));
    case 'year':
      return DateTime(selectedMonth.year, 1, 1);
    case 'all':
      return DateTime(2020, 1, 1);
    case 'month':
    default:
      return DateTime(selectedMonth.year, selectedMonth.month, 1);
  }
}

DateTime? _getEndDateForChart() {
  final selectedMonth = ref.read(selectedMonthProvider);
  final timeRangeType = ref.read(selectedTimeRangeTypeProvider);
  
  switch (timeRangeType) {
    case '90days':
    case '60days':
    case 'year':
    case 'all':
      return DateTime.now();
    case 'month':
    default:
      return DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
  }
}

String _getCurrentTimeRangeTitle() {
  final timeRangeType = ref.read(selectedTimeRangeTypeProvider);
  switch (timeRangeType) {
    case '90days':
      return '最近90天';
    case '60days':
      return '最近60天';
    case 'year':
      return '全年';
    case 'all':
      return '全部';
    case 'month':
    default:
      return '当月';
  }
}

int _getCurrentDaysInPeriod() {
  final selectedMonth = ref.read(selectedMonthProvider);
  final timeRangeType = ref.read(selectedTimeRangeTypeProvider);
  
  switch (timeRangeType) {
    case '90days':
      return 90;
    case '60days':
      return 60;
    case 'year':
      final year = selectedMonth.year;
      final yearStart = DateTime(year, 1, 1);
      final yearEnd = DateTime(year, 12, 31);
      return yearEnd.difference(yearStart).inDays + 1;
    case 'all':
      final startDate = DateTime(2020, 1, 1);
      final endDate = DateTime.now();
      return endDate.difference(startDate).inDays + 1;
    case 'month':
    default:
      return DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  }
}
```

## Step 5: 更新统计数据计算

将静态统计替换为动态统计：

```dart
// 修改前：简单静态方法
Widget _buildStatsItem(String title, String value) { ... }

// 修改后：基于时间范围的动态统计
Widget _buildStatsRow(List<ChartData> currentData, List<ChartData> previousData) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  // 当前期间总计
  double currentTotal = currentData.fold(0.0, (sum, item) => sum + item.y);

  // 根据时间范围类型计算期间信息
  String periodTitle;
  String dailyTitle;
  String comparisonTitle;
  double dailyAverage = 0.0;

  switch (timeRangeType) {
    case '90days':
      periodTitle = '90天总支出';
      dailyTitle = '90天日均';
      comparisonTitle = '较前90天';
      dailyAverage = currentTotal / 90;
      break;
    case '60days':
      periodTitle = '60天总支出';
      dailyTitle = '60天日均';
      comparisonTitle = '较前60天';
      dailyAverage = currentTotal / 60;
      break;
    case 'year':
      periodTitle = '全年总支出';
      dailyTitle = '全年日均';
      comparisonTitle = '较去年同期';
      final daysInYear = DateTime(selectedMonth.year, 12, 31).difference(DateTime(selectedMonth.year, 1, 1)).inDays + 1;
      dailyAverage = currentTotal / daysInYear;
      break;
    case 'all':
      periodTitle = '累计总支出';
      dailyTitle = '全部日均';
      comparisonTitle = '较前期';
      final startDate = DateTime(2020, 1, 1);
      final daysSinceStart = DateTime.now().difference(startDate).inDays;
      dailyAverage = daysSinceStart > 0 ? currentTotal / daysSinceStart : 0.0;
      break;
    case 'month':
    default:
      periodTitle = '当月总支出';
      dailyTitle = '当月日均';
      comparisonTitle = '较上月支出';
      final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      dailyAverage = daysInMonth > 0 ? currentTotal / daysInMonth : 0.0;
      break;
  }
  
  // ... 使用计算出的值构建UI
}
```

## Step 6: 添加状态监听

在 build 方法中，确保状态变化时触发重新构建：

```dart
@override
Widget build(BuildContext context) {
  final currentSelectedMonth = ref.watch(selectedMonthProvider);
  ref.watch(selectedTimeRangeTypeProvider); // 监听状态变化
  
  // ... build方法的其余部分
}
```

## Step 7: 更新 MonthSelectorHeader

```dart
MonthSelectorHeader(
  initialDate: currentSelectedMonth,
  onDateChanged: (newDate) {
    ref.read(selectedMonthProvider.notifier).state = newDate;
  },
  onLongRangeSelected: () async {
    // 处理全屏图表导航
    try {
      final chartDataValue = ref.read(chartDataProvider);
      if (!chartDataValue.hasValue) return;
      final chartData = chartDataValue.value!;
      
      String title = _getCurrentTimeRangeTitle();
      int daysInPeriod = _getCurrentDaysInPeriod();
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullscreenChartPage(
            chartData: chartData,
            daysInPeriod: daysInPeriod,
            startDate: _getStartDateForChart(),
            endDate: _getEndDateForChart(),
            timeRangeTitle: title,
            isLineChart: _isLineChart,
          ),
        ),
      );
    } catch (error) {
      // 处理错误
    }
  },
),
```

## Step 8: 更新图表组件

```dart
// 更新图表渲染以使用动态期间计算
final daysInPeriod = _getCurrentDaysInPeriod();

return _isLineChart
    ? fl_linechart.FlLineChart(
        lineColor: Colors.red,
        chartData: chartData.map((e) => fl_linechart.ChartData(e.x, e.y, e.day)).toList(),
        daysInMonth: daysInPeriod,  // 使用计算出的天数
        startDate: _getStartDateForChart(),
        endDate: _getEndDateForChart(),
      )
    : fl_barchart.FlBarChart(
        barColor: Colors.red,
        chartData: chartData.map((e) => fl_barchart.ChartData(e.x, e.y, e.day)).toList(),
        daysInMonth: daysInPeriod,  // 使用计算出的天数
        startDate: _getStartDateForChart(),
        endDate: _getEndDateForChart(),
      );
```

## 关键要点

1. **始终使用全局providers** (`selectedMonthProvider`, `selectedTimeRangeTypeProvider`)
2. **添加状态监听** 确保时间范围变化时重新构建
3. **更新所有数据提供者** 以处理多种时间范围
4. **添加辅助方法** 保持日期/期间计算的一致性
5. **更新统计数据** 基于选择的时间范围动态计算
6. **彻底测试** 实现后确保所有时间范围的数据都能正确加载

## 常见问题解决

### 问题1：切换时间范围时数据没有更新
**解决方案**：确保在 build 方法中添加了 `ref.watch(selectedTimeRangeTypeProvider)`

### 问题2：统计数据显示错误
**解决方案**：检查 `_buildStatsRow` 方法中的时间范围计算逻辑

### 问题3：全屏图表导航失败
**解决方案**：确保正确处理了 AsyncValue 的状态检查（`chartDataValue.hasValue`）

这个模式确保了应用中所有详情页面的时间范围功能保持一致性。