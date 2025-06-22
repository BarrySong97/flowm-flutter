import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的月份提供者
final selectedMonthProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

/// 上个月收入数据提供者
/// 移除autoDispose以启用缓存，提升性能
final previousMonthIncomeProvider =
    FutureProvider<List<barchart.ChartData>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 计算上个月的开始和结束时间
  final DateTime prevMonthStartDate =
      DateTime(selectedDate.year, selectedDate.month - 1, 1);
  final DateTime prevMonthEndDate =
      DateTime(selectedDate.year, selectedDate.month, 0);

  return repository.getIncomeChartData(
    startDate: prevMonthStartDate,
    endDate: prevMonthEndDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

/// 收入图表数据提供者
/// 移除autoDispose以启用缓存，提升性能
final incomeChartDataProvider =
    FutureProvider<List<barchart.ChartData>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 根据选择的月份计算开始和结束时间
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate = DateTime(
      selectedDate.year, selectedDate.month + 1, 0); // Last day of the month

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

/// 收入账户树数据提供者
/// 移除autoDispose以启用缓存，提升性能
final incomeAccountTreeDataProvider =
    FutureProvider<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getIncomeAccountTree(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

class IncomePageData {
  final List<barchart.ChartData> currentMonthChartData;
  final List<barchart.ChartData> previousMonthChartData;
  final List<AccountExpenseNode> accountTree;
  final double currentMonthTotal;
  final double previousMonthTotal;
  final double dailyAverage;
  final double changePercentage;

  IncomePageData({
    required this.currentMonthChartData,
    required this.previousMonthChartData,
    required this.accountTree,
    required this.currentMonthTotal,
    required this.previousMonthTotal,
    required this.dailyAverage,
    required this.changePercentage,
  });
}

final incomePageDataProvider =
    FutureProvider.autoDispose<IncomePageData>((ref) async {
  final selectedDate = ref.watch(selectedMonthProvider);

  try {
    // 并行加载三个数据源，而不是串行等待
    final results = await Future.wait([
      ref.watch(incomeChartDataProvider.future),
      ref.watch(previousMonthIncomeProvider.future),
      ref.watch(incomeAccountTreeDataProvider.future),
    ]);

    final currentMonthChartData = results[0] as List<barchart.ChartData>;
    final previousMonthChartData = results[1] as List<barchart.ChartData>;
    final accountTree = results[2] as List<AccountExpenseNode>;

    final currentMonthTotal =
        currentMonthChartData.fold<double>(0.0, (sum, item) => sum + item.y);

    final previousMonthTotal =
        previousMonthChartData.fold<double>(0.0, (sum, item) => sum + item.y);

    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final dailyAverage =
        daysInMonth > 0 ? currentMonthTotal / daysInMonth : 0.0;

    double changePercentage;
    if (previousMonthTotal != 0) {
      changePercentage = ((currentMonthTotal - previousMonthTotal) /
              previousMonthTotal.abs()) *
          100;
    } else if (currentMonthTotal > 0) {
      changePercentage = 100.0;
    } else {
      changePercentage = 0.0;
    }

    return IncomePageData(
      currentMonthChartData: currentMonthChartData,
      previousMonthChartData: previousMonthChartData,
      accountTree: accountTree,
      currentMonthTotal: currentMonthTotal,
      previousMonthTotal: previousMonthTotal,
      dailyAverage: dailyAverage,
      changePercentage: changePercentage,
    );
  } catch (e, stackTrace) {
    // 记录错误以便调试
    print('[IncomePageDataProvider] Error loading data: $e');
    print('[IncomePageDataProvider] StackTrace: $stackTrace');

    // 重新抛出错误，让UI层处理
    rethrow;
  }
});
