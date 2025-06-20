import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

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

  if (selectedLedger == null) {
    // Return empty data if no ledger is selected.
    return ExpensePageData(
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

  // Fetch all data in parallel using Future.wait for efficiency
  final results = await Future.wait([
    repository.getExpenseChartData(
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    ),
    repository.getExpenseChartData(
      startDate: prevMonthStartDate,
      endDate: prevMonthEndDate,
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
