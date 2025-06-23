import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/state/transaction/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch current month's expenses
final currentMonthExpenseProvider = StreamProvider<double>((ref) {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) {
      if (ledger == null) return Stream.value(0.0);

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final repository = ref.watch(accountRepositoryProvider);
      return repository.watchExpenseInPeriod(
          ledger.ledgerId, startOfMonth, endOfMonth);
    },
    loading: () => Stream.value(0.0),
    error: (_, __) => Stream.value(0.0),
  );
});

// Provider to fetch current month's income
final currentMonthIncomeProvider = StreamProvider<double>((ref) {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) {
      if (ledger == null) return Stream.value(0.0);

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final repository = ref.watch(accountRepositoryProvider);
      return repository.watchIncomeInPeriod(
          ledger.ledgerId, startOfMonth, endOfMonth);
    },
    loading: () => Stream.value(0.0),
    error: (_, __) => Stream.value(0.0),
  );
});

// Provider to fetch total liabilities
final totalLiabilitiesProvider = StreamProvider<double>((ref) {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) {
      if (ledger == null) return Stream.value(0.0);

      final repository = ref.watch(accountRepositoryProvider);
      return repository.watchTotalLiabilitiesByLedger(ledger.ledgerId);
    },
    loading: () => Stream.value(0.0),
    error: (_, __) => Stream.value(0.0),
  );
});

// Provider for combined monthly overview data (expense, income, balance)
final monthlyOverviewDataProvider =
    StreamProvider<({double expense, double income, double balance})>((ref) {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) {
      if (ledger == null) {
        return Stream.value((expense: 0.0, income: 0.0, balance: 0.0));
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final repository = ref.watch(accountRepositoryProvider);
      final expenseStream = repository.watchExpenseInPeriod(
          ledger.ledgerId, startOfMonth, endOfMonth);
      final incomeStream = repository.watchIncomeInPeriod(
          ledger.ledgerId, startOfMonth, endOfMonth);

      // 使用 combineLatest 合并两个 Stream
      return expenseStream.asyncMap((expense) async {
        final income = await incomeStream.first;
        final balance = income - expense;
        return (expense: expense, income: income, balance: balance);
      });
    },
    loading: () => Stream.value((expense: 0.0, income: 0.0, balance: 0.0)),
    error: (_, __) => Stream.value((expense: 0.0, income: 0.0, balance: 0.0)),
  );
});

// Provider to fetch latest transactions
final latestTransactionsProvider =
    StreamProvider<List<TransactionWithAmount>>((ref) {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) {
      if (ledger == null) return Stream.value(<TransactionWithAmount>[]);

      final transactionRepository = ref.watch(transactionRepositoryProvider);
      return transactionRepository.watchLatestTransactions(
          ledgerId: ledger.ledgerId, limit: 50);
    },
    loading: () => Stream.value(<TransactionWithAmount>[]),
    error: (_, __) => Stream.value(<TransactionWithAmount>[]),
  );
});

// 为当前页面提供账户资产信息
final topAssetAccountsProvider =
    StreamProvider<List<AccountWithBalance>>((ref) {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) {
      if (ledger == null) return Stream.value(<AccountWithBalance>[]);

      final repository = ref.watch(accountRepositoryProvider);
      return repository.watchTopAssetAccountsByLedger(
          ledgerId: ledger.ledgerId);
    },
    loading: () => Stream.value(<AccountWithBalance>[]),
    error: (_, __) => Stream.value(<AccountWithBalance>[]),
  );
});
