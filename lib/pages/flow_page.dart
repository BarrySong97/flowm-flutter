import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/common/transaction_list_item.dart';
import '../state/transaction/flow_transactions_provider.dart';
import '../db/dao/transaction_dao.dart'
    show TransactionWithAmount; // Import TransactionWithAmount explicitly
import 'package:intl/intl.dart'; // For date formatting

class FlowPage extends ConsumerStatefulWidget {
  const FlowPage({super.key});

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flowTransactionsProvider.notifier).fetchTransactions();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(flowTransactionsProvider);
      if (state.hasMore && !state.isLoading) {
        ref.read(flowTransactionsProvider.notifier).loadMoreTransactions();
      }
    }
  }

  Future<void> _refreshTransactions() async {
    await ref.read(flowTransactionsProvider.notifier).refresh();
  }

  Future<void> _deleteTransaction(int transactionId) async {
    await ref
        .read(flowTransactionsProvider.notifier)
        .deleteTransaction(transactionId);
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return '今天';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天';
    } else {
      return DateFormat('yyyy年 M月d日', 'zh_CN').format(date); // 例如: 2024年 5月8日
    }
  }

  Widget buildTransactionItem(
      TransactionWithAmount transactionWithAmount, Function(int) onDelete) {
    final transaction = transactionWithAmount.transaction;
    final totalAmount = transactionWithAmount.amount;

    final bool isExpense = totalAmount < 0;
    final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
    final formattedAmount = formatter.format(totalAmount.abs());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TransactionListItem(
        transactionId: transaction.transactionId.toString(),
        title: transaction.description ?? '无描述',
        subtitle:
            '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}',
        amount: formattedAmount,
        type: getTransactionFlowType(
            transactionWithAmount.fromAccount?.accountType ?? AccountType.ASSET,
            transactionWithAmount.toAccount?.accountType ?? AccountType.ASSET),
        statusColor: isExpense
            ? const Color(0xFF007AFF) // Blue for expense
            : const Color(0xFF34C759), // Green for income
        isExpense: isExpense,
        transactionDate: transaction.transactionDate,
        fromAccountType: transactionWithAmount.fromAccount?.accountType,
        toAccountType: transactionWithAmount.toAccount?.accountType,
        transactionAmount: totalAmount.abs(),
        onDelete: () => onDelete(transaction.transactionId),
      ),
    );
  }

  Widget buildTransactionList(FlowTransactionsState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.transactions.isEmpty && !state.isLoading) {
      return Center(
        child: Text(
          '暂无流水数据',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${state.error}',
              style: TextStyle(fontSize: 16, color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshTransactions,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          return state.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final transactionWithAmount = state.transactions[index];
        final transaction = transactionWithAmount.transaction;
        final uiDate = formatDate(transaction.transactionDate);
        final previousUiDate = index > 0
            ? formatDate(
                state.transactions[index - 1].transaction.transactionDate)
            : null;

        if (index == 0 || uiDate != previousUiDate) {
          final dailyOut = state.transactions
              .where((twa) =>
                  formatDate(twa.transaction.transactionDate) == uiDate &&
                  twa.nature == TransactionNature.OUTFLOW)
              .fold(0.0, (sum, twa) => sum + twa.amount.abs());
          final dailyIn = state.transactions
              .where((twa) =>
                  formatDate(twa.transaction.transactionDate) == uiDate &&
                  twa.nature == TransactionNature.INFLOW)
              .fold(0.0, (sum, twa) => sum + twa.amount.abs());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  index == 0 ? 0 : 16,
                  16,
                  8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      uiDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '出 ¥${dailyOut.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '入 ¥${dailyIn.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              buildTransactionItem(transactionWithAmount, _deleteTransaction),
            ],
          );
        }
        return buildTransactionItem(transactionWithAmount, _deleteTransaction);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flowTransactionsProvider);

    // 当provider被invalidate后，如果数据为空且不在加载中，主动获取数据
    if (state.transactions.isEmpty && !state.isLoading && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(flowTransactionsProvider.notifier).fetchTransactions();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: const Row(
              children: [
                Text(
                  '流水列表',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: buildTransactionList(state),
          ),
        ],
      ),
    );
  }
}
