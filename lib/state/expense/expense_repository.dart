import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/data/cashflow/cashflow_query.dart';
import 'package:flowm/db/dao/posting_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/domain/finance/finance_types.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/database/database_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final postingDao = ref.watch(postingDaoProvider);
  return ExpenseRepository(postingDao);
});

class ExpenseRepository {
  ExpenseRepository(PostingDao postingDao)
      : _cashflowQuery = CashflowQuery(postingDao);

  final CashflowQuery _cashflowQuery;

  Future<List<barchart.ChartData>> getExpenseChartData({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) {
    return _cashflowQuery.getChartData(
      type: CashflowType.expense,
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
      accountId: accountId,
    );
  }

  Future<List<AccountExpenseNode>> getExpenseAccountTree({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
  }) {
    return _cashflowQuery.getAccountTree(
      type: CashflowType.expense,
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    );
  }

  Future<double> getAccountExpenseBalance({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _cashflowQuery.getAccountBalance(
      type: CashflowType.expense,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> getAccountExpenseTotalBalance({
    required int accountId,
  }) {
    return _cashflowQuery.getAccountTotalBalance(
      type: CashflowType.expense,
      accountId: accountId,
    );
  }

  Stream<List<TransactionWithAmount>> watchAccountTransactions({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _cashflowQuery.watchAccountTransactions(
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

final accountExpenseTransactionsProvider = StreamProvider.family<
    List<TransactionWithAmount>,
    ({int accountId, DateTime startDate, DateTime endDate})>((ref, params) {
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  return expenseRepository.watchAccountTransactions(
    accountId: params.accountId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
