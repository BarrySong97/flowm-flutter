import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'transaction_repository.dart';
import '../../db/dao/transaction_dao.dart';

/// Provider to get daily income and expense summary for a specific month
final monthlyCalendarSummaryProvider = FutureProvider.autoDispose
    .family<Map<int, ({double income, double expenses})>, DateTime>(
        (ref, dayForMonth) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final ledgerId = ref.read(selectedLedgerProvider).value?.ledgerId;

  return await transactionRepository.getMonthlyCalendarSummary(
    dayForMonth,
    ledgerId,
  );
});

/// Provider to get transactions for a specific day
final selectedDayTransactionsProvider = FutureProvider.autoDispose
    .family<List<TransactionWithAmount>, DateTime>((ref, selectedDay) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final ledgerId = ref.read(selectedLedgerProvider).value?.ledgerId;

  return await transactionRepository.getTransactionsByDay(
      selectedDay, ledgerId);
});
