import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/data/cashflow/cashflow_query.dart';
import 'package:flowm/db/dao/posting_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/domain/finance/finance_types.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/database/database_provider.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final postingDao = ref.watch(postingDaoProvider);
  return IncomeRepository(postingDao);
});

class IncomeRepository {
  IncomeRepository(PostingDao postingDao)
      : _cashflowQuery = CashflowQuery(postingDao);

  final CashflowQuery _cashflowQuery;

  Future<List<barchart.ChartData>> getIncomeChartData({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
    int? accountId,
  }) {
    return _cashflowQuery.getChartData(
      type: CashflowType.income,
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
      accountId: accountId,
    );
  }

  Future<List<AccountExpenseNode>> getIncomeAccountTree({
    required DateTime startDate,
    required DateTime endDate,
    required int ledgerId,
  }) {
    return _cashflowQuery.getAccountTree(
      type: CashflowType.income,
      startDate: startDate,
      endDate: endDate,
      ledgerId: ledgerId,
    );
  }

  Future<double> getAccountIncomeBalance({
    required int accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _cashflowQuery.getAccountBalance(
      type: CashflowType.income,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<double> getAccountIncomeTotalBalance({
    required int accountId,
  }) {
    return _cashflowQuery.getAccountTotalBalance(
      type: CashflowType.income,
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

final accountIncomeTransactionsProvider = StreamProvider.family<
    List<TransactionWithAmount>,
    ({int accountId, DateTime startDate, DateTime endDate})>((ref, params) {
  final incomeRepository = ref.watch(incomeRepositoryProvider);
  return incomeRepository.watchAccountTransactions(
    accountId: params.accountId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});
