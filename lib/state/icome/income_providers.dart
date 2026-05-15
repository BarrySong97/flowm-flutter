import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/state/expense/expense_providers.dart'
    as expense_providers;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

class IncomePageData {
  final List<barchart.ChartData> chartData;
  final List<barchart.ChartData> previousMonthChartData;
  final List<AccountExpenseNode> accountTree;

  IncomePageData({
    required this.chartData,
    required this.previousMonthChartData,
    required this.accountTree,
  });
}

final incomePageDataProvider = FutureProvider<IncomePageData>((ref) async {
  final repository = ref.watch(incomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType =
      ref.watch(expense_providers.selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    return IncomePageData(
      chartData: [],
      previousMonthChartData: [],
      accountTree: [],
    );
  }

  final ledgerId = selectedLedger.ledgerId;

  // Current period date range
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

  // Previous period date range
  DateTime prevStartDate, prevEndDate;

  switch (timeRangeType) {
    case '90days':
      prevEndDate = DateTime.now().subtract(const Duration(days: 90));
      prevStartDate = prevEndDate.subtract(const Duration(days: 90));
      break;
    case '60days':
      prevEndDate = DateTime.now().subtract(const Duration(days: 60));
      prevStartDate = prevEndDate.subtract(const Duration(days: 60));
      break;
    case 'year':
      final prevYear = selectedDate.year - 1;
      prevStartDate = DateTime(prevYear, 1, 1);
      prevEndDate = DateTime(prevYear, 12, 31);
      break;
    case 'all':
      // No previous period for 'all'
      prevStartDate = DateTime(2020, 1, 1);
      prevEndDate = DateTime(2020, 1, 1);
      break;
    case 'month':
    default:
      prevStartDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      prevEndDate = DateTime(selectedDate.year, selectedDate.month, 0);
      break;
  }

  final results = await Future.wait([
    repository.getIncomeChartData(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    ),
    repository.getIncomeChartData(
      startDate: prevStartDate,
      endDate: prevEndDate,
      ledgerId: ledgerId,
    ),
    repository.getIncomeAccountTree(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    ),
  ]);

  return IncomePageData(
    chartData: results[0] as List<barchart.ChartData>,
    previousMonthChartData: results[1] as List<barchart.ChartData>,
    accountTree: results[2] as List<AccountExpenseNode>,
  );
});

/// 上个月收入数据提供者 (family)
final previousMonthIncomeProviderFamily =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(incomeRepositoryProvider);
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
    accountId: accountId,
  );
});

/// 收入图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final incomeChartDataProviderFamily =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(incomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 指定账户当月总收入提供者
final accountMonthlyIncomeProvider =
    FutureProvider.family<double, int>((ref, accountId) async {
  final repository = ref.watch(incomeRepositoryProvider);
  final selectedDate = ref.watch(selectedMonthProvider);
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getAccountIncomeBalance(
    accountId: accountId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// 指定账户累计总收入提供者 (不区分时间)
final accountOverallIncomeProvider =
    FutureProvider.family<double, int>((ref, accountId) async {
  final repository = ref.watch(incomeRepositoryProvider);
  return repository.getAccountIncomeTotalBalance(accountId: accountId);
});
