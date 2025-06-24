import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
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
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return IncomePageData(
      chartData: [],
      previousMonthChartData: [],
      accountTree: [],
    );
  }

  final ledgerId = selectedLedger.ledgerId;

  // Current month date range
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  // Previous month date range
  final DateTime prevMonthStartDate =
      DateTime(selectedDate.year, selectedDate.month - 1, 1);
  final DateTime prevMonthEndDate =
      DateTime(selectedDate.year, selectedDate.month, 0);

  final results = await Future.wait([
    repository.getIncomeChartData(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    ),
    repository.getIncomeChartData(
      startDate: prevMonthStartDate,
      endDate: prevMonthEndDate,
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
    accountId: accountId,
  );
});

/// 收入图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final incomeChartDataProviderFamily =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  print(
      '[incomeChartDataProviderFamily] Fetching chart data with accountId: $accountId');

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
  final repository = ref.watch(IncomeRepositoryProvider);
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
  final repository = ref.watch(IncomeRepositoryProvider);
  return repository.getAccountIncomeTotalBalance(accountId: accountId);
});
