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
final totalLiabilitiesProvider = FutureProvider<double>((ref) async {
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) return 0.0;

  final repository = ref.watch(accountRepositoryProvider);
  return repository.getTotalLiabilitiesByLedger(selectedLedger.ledgerId);
});

// Provider for combined monthly overview data (expense, income, balance)
final monthlyOverviewDataProvider =
    FutureProvider<({double expense, double income, double balance})>(
        (ref) async {
  final selectedLedger = ref.watch(selectedLedgerProvider);
  return selectedLedger.when(
    data: (ledger) async {
      if (ledger == null) {
        return (expense: 0.0, income: 0.0, balance: 0.0);
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final repository = ref.watch(accountRepositoryProvider);

      final expenseFuture = repository.getExpenseInPeriod(
          ledger.ledgerId, startOfMonth, endOfMonth);
      final incomeFuture = repository.getIncomeInPeriod(
          ledger.ledgerId, startOfMonth, endOfMonth);

      final results = await Future.wait([expenseFuture, incomeFuture]);
      final expense = results[0];
      final income = results[1];
      final balance = income - expense;

      return (expense: expense, income: income, balance: balance);
    },
    loading: () => (expense: 0.0, income: 0.0, balance: 0.0),
    error: (_, __) => (expense: 0.0, income: 0.0, balance: 0.0),
  );
});

// Provider to fetch latest transactions
final latestTransactionsProvider =
    FutureProvider<List<TransactionWithAmount>>((ref) async {
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) return <TransactionWithAmount>[];

  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getLatestTransactions(
      ledgerId: selectedLedger.ledgerId, limit: 50);
});

// 为当前页面提供账户资产信息
final topAssetAccountsProvider =
    FutureProvider<List<AccountWithBalance>>((ref) async {
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) return [];

  final repository = ref.watch(accountRepositoryProvider);
  return repository.getTopAssetAccountsByLedger(
      ledgerId: selectedLedger.ledgerId);
});
