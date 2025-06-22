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
