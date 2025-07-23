import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/common/time_range_selector.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 当前选中的时间范围类型提供者
final selectedTimeRangeTypeProvider = StateProvider<String>((ref) => 'month');

/// 将时间范围类型字符串转换为 TimeRange 枚举
TimeRange _getTimeRangeFromString(String rangeType) {
  switch (rangeType) {
    case '90days':
      return TimeRange.this90Days;
    case '60days':
      return TimeRange.this3Months;
    case 'year':
      return TimeRange.thisYear;
    case 'all':
      return TimeRange.all;
    case 'month':
    default:
      return TimeRange.thisMonth;
  }
}

/// 根据TimeRange获取开始日期
DateTime _getStartDateFromTimeRange(TimeRange timeRange, DateTime selectedDate) {
  final now = DateTime.now();
  switch (timeRange) {
    case TimeRange.thisMonth:
      return DateTime(selectedDate.year, selectedDate.month, 1);
    case TimeRange.this3Months:
      return now.subtract(const Duration(days: 60)); // this3Months 标签是 '60天'
    case TimeRange.this90Days:
      return now.subtract(const Duration(days: 90)); // this90Days 标签是 '90天'
    case TimeRange.thisYear:
      return DateTime(selectedDate.year, 1, 1);
    case TimeRange.all:
      return DateTime(2020, 1, 1); // 设置为2020年作为"全部"的开始
  }
}

/// 根据TimeRange获取结束日期
DateTime _getEndDateFromTimeRange(TimeRange timeRange, DateTime selectedDate) {
  switch (timeRange) {
    case TimeRange.thisMonth:
      return DateTime(selectedDate.year, selectedDate.month + 1, 0);
    case TimeRange.this3Months:
    case TimeRange.this90Days:
    case TimeRange.thisYear:
    case TimeRange.all:
      return DateTime.now();
  }
}

/// 获取上一时期的开始日期用于比较
DateTime _getPreviousStartDate(TimeRange timeRange, DateTime selectedDate) {
  switch (timeRange) {
    case TimeRange.thisMonth:
      return DateTime(selectedDate.year, selectedDate.month - 1, 1);
    case TimeRange.this3Months:
      return DateTime.now().subtract(const Duration(days: 120)); // 前60天，所以总共120天
    case TimeRange.this90Days:
      return DateTime.now().subtract(const Duration(days: 180)); // 前90天，所以总共180天
    case TimeRange.thisYear:
      return DateTime(selectedDate.year - 1, 1, 1);
    case TimeRange.all:
      return DateTime(2019, 1, 1); // 更早的日期用于比较
  }
}

/// 获取上一时期的结束日期用于比较
DateTime _getPreviousEndDate(TimeRange timeRange, DateTime selectedDate) {
  switch (timeRange) {
    case TimeRange.thisMonth:
      return DateTime(selectedDate.year, selectedDate.month, 0);
    case TimeRange.this3Months:
      return DateTime.now().subtract(const Duration(days: 60)); // 结束于60天前
    case TimeRange.this90Days:
      return DateTime.now().subtract(const Duration(days: 90)); // 结束于90天前
    case TimeRange.thisYear:
      return DateTime(selectedDate.year - 1, 12, 31);
    case TimeRange.all:
      return DateTime(2020, 12, 31); // 用2020年数据作为比较
  }
}

class ExpensePageData {
  final List<barchart.ChartData> chartData;
  final List<barchart.ChartData> previousMonthChartData;
  final List<AccountExpenseNode> accountTree;

  ExpensePageData({
    required this.chartData,
    required this.previousMonthChartData,
    required this.accountTree,
  });
}

final expensePageDataProvider = FutureProvider<ExpensePageData>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    // Return empty data if no ledger is selected.
    return ExpensePageData(
      chartData: [],
      previousMonthChartData: [],
      accountTree: [],
    );
  }

  final ledgerId = selectedLedger.ledgerId;
  final timeRange = _getTimeRangeFromString(timeRangeType);

  // Current period date range
  final DateTime startDate = _getStartDateFromTimeRange(timeRange, selectedDate);
  final DateTime endDate = _getEndDateFromTimeRange(timeRange, selectedDate);

  // Previous period date range for comparison
  final DateTime prevStartDate = _getPreviousStartDate(timeRange, selectedDate);
  final DateTime prevEndDate = _getPreviousEndDate(timeRange, selectedDate);


  // Fetch all data in parallel using Future.wait for efficiency
  final results = await Future.wait([
    repository.getExpenseChartData(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    ),
    repository.getExpenseChartData(
      startDate: prevStartDate,
      endDate: prevEndDate,
      ledgerId: ledgerId,
    ),
    repository.getExpenseAccountTree(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    ),
  ]);

  return ExpensePageData(
    chartData: results[0] as List<barchart.ChartData>,
    previousMonthChartData: results[1] as List<barchart.ChartData>,
    accountTree: results[2] as List<AccountExpenseNode>,
  );
});

/// 上一时期支出数据提供者 (family)
final previousMonthExpenseProviderFamily =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    return [];
  }

  final timeRange = _getTimeRangeFromString(timeRangeType);
  // 计算上一时期的开始和结束时间
  final DateTime prevStartDate = _getPreviousStartDate(timeRange, selectedDate);
  final DateTime prevEndDate = _getPreviousEndDate(timeRange, selectedDate);

  return repository.getExpenseChartData(
    startDate: prevStartDate,
    endDate: prevEndDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId, // 传递 accountId
  );
});

/// 支出图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final expenseChartDataProvider =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    return [];
  }

  final timeRange = _getTimeRangeFromString(timeRangeType);
  final DateTime startDate = _getStartDateFromTimeRange(timeRange, selectedDate);
  final DateTime endDate = _getEndDateFromTimeRange(timeRange, selectedDate);

  return repository.getExpenseChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId, // 传递 accountId
  );
});

/// 指定账户当前时间范围总支出提供者
final accountMonthlyExpenseProvider =
    FutureProvider.family<double, int>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  final timeRange = _getTimeRangeFromString(timeRangeType);
  final DateTime startDate = _getStartDateFromTimeRange(timeRange, selectedDate);
  final DateTime endDate = _getEndDateFromTimeRange(timeRange, selectedDate);

  return repository.getAccountExpenseBalance(
    accountId: accountId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// 指定账户累计总支出提供者 (不区分时间)
final accountOverallExpenseProvider =
    FutureProvider.family<double, int>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getAccountExpenseTotalBalance(accountId: accountId);
});
