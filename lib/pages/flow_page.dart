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
    
    // 格式化时间为 HH:mm 格式，如果是 00:00 则不显示
    final timeFormatter = DateFormat('HH:mm');
    final formattedTime = timeFormatter.format(transaction.transactionDate);
    final timeDisplay = formattedTime == '00:00' ? '' : ' · $formattedTime';

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
            '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}$timeDisplay',
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

    // 按日期分组交易，并对每日内的交易按时间排序
    final Map<String, List<TransactionWithAmount>> groupedTransactions = {};
    for (var transaction in state.transactions) {
      final dateKey = formatDate(transaction.transaction.transactionDate);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    // 对每日内的交易按时间降序排序（最新的在前）
    groupedTransactions.forEach((date, transactions) {
      transactions.sort((a, b) => b.transaction.transactionDate.compareTo(a.transaction.transactionDate));
    });

    // 获取排序后的日期列表（最新的日期在前）
    final sortedDates = groupedTransactions.keys.toList();
    sortedDates.sort((a, b) {
      // 获取每个日期组中最新的交易时间进行比较
      final aLatest = groupedTransactions[a]!.first.transaction.transactionDate;
      final bLatest = groupedTransactions[b]!.first.transaction.transactionDate;
      return bLatest.compareTo(aLatest);
    });

    // 计算总的item数量（日期头 + 交易项 + 加载更多indicator）
    int totalItems = 0;
    for (String date in sortedDates) {
      totalItems += 1 + groupedTransactions[date]!.length; // 1个日期头 + N个交易项
    }
    if (state.hasMore) totalItems += 1; // 加载更多indicator

    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // 处理加载更多indicator
        if (index == totalItems - 1 && state.hasMore) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // 确定当前item属于哪个日期组和位置
        int currentIndex = 0;
        for (int dateIndex = 0; dateIndex < sortedDates.length; dateIndex++) {
          final date = sortedDates[dateIndex];
          final dayTransactions = groupedTransactions[date]!;

          // 检查是否是日期头
          if (currentIndex == index) {
            // 计算当日收支总额
            final dailyOut = dayTransactions
                .where((twa) => twa.nature == TransactionNature.OUTFLOW)
                .fold(0.0, (sum, twa) => sum + twa.amount.abs());
            final dailyIn = dayTransactions
                .where((twa) => twa.nature == TransactionNature.INFLOW)
                .fold(0.0, (sum, twa) => sum + twa.amount.abs());

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                dateIndex == 0 ? 0 : 16,
                16,
                8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
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
            );
          }
          currentIndex++;

          // 检查是否是当日的交易项
          for (int transactionIndex = 0; transactionIndex < dayTransactions.length; transactionIndex++) {
            if (currentIndex == index) {
              return buildTransactionItem(
                dayTransactions[transactionIndex], 
                _deleteTransaction
              );
            }
            currentIndex++;
          }
        }

        return const SizedBox.shrink(); // 不应该到达这里
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
