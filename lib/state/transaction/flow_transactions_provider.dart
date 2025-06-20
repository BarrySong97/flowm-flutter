import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/dao/transaction_dao.dart';
import 'transaction_repository.dart';
import '../ledger/ledger_repository.dart';

/// Flow页面交易状态类
class FlowTransactionsState {
  final List<TransactionWithAmount> transactions;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const FlowTransactionsState({
    this.transactions = const [],
    this.currentPage = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  FlowTransactionsState copyWith({
    List<TransactionWithAmount>? transactions,
    int? currentPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return FlowTransactionsState(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

/// Flow页面交易数据管理
class FlowTransactionsNotifier extends StateNotifier<FlowTransactionsState> {
  final TransactionRepository _transactionRepository;
  final Ref _ref;
  static const int _perPage = 15;

  FlowTransactionsNotifier(this._transactionRepository, this._ref)
      : super(const FlowTransactionsState());

  /// 初始化或刷新数据
  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final ledgerId = _ref.read(selectedLedgerProvider).value?.ledgerId;
      final newTransactions =
          await _transactionRepository.getTransactionsWithAmountPaginated(
        limit: _perPage,
        offset: 0,
        ledgerId: ledgerId,
      );

      state = state.copyWith(
        transactions: newTransactions,
        currentPage: 1,
        isLoading: false,
        hasMore: newTransactions.length >= _perPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 加载更多数据
  Future<void> loadMoreTransactions() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final ledgerId = _ref.read(selectedLedgerProvider).value?.ledgerId;
      final newTransactions =
          await _transactionRepository.getTransactionsWithAmountPaginated(
        limit: _perPage,
        offset: state.currentPage * _perPage,
        ledgerId: ledgerId,
      );

      if (newTransactions.isNotEmpty) {
        state = state.copyWith(
          transactions: [...state.transactions, ...newTransactions],
          currentPage: state.currentPage + 1,
          isLoading: false,
          hasMore: newTransactions.length >= _perPage,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    state = const FlowTransactionsState(); // Reset state
    await fetchTransactions();
  }

  /// 删除指定的交易
  Future<void> deleteTransaction(int transactionId) async {
    try {
      // 调用repository删除交易
      await _transactionRepository.deleteTransactionWithPostings(transactionId);

      // 从本地状态中移除已删除的交易
      final updatedTransactions = state.transactions
          .where((twa) => twa.transaction.transactionId != transactionId)
          .toList();

      state = state.copyWith(
        transactions: updatedTransactions,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }
}

/// Flow页面交易数据Provider
final flowTransactionsProvider =
    StateNotifierProvider<FlowTransactionsNotifier, FlowTransactionsState>(
  (ref) {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    return FlowTransactionsNotifier(transactionRepository, ref);
  },
);
