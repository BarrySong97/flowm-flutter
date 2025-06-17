import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../components/common/transaction_list_item.dart';
import '../db/app_database.dart'; // Assuming TransactionWithAmount is from here or a similar model
import '../state/transaction/transaction_repository.dart';
import '../db/dao/transaction_dao.dart'
    show TransactionWithAmount; // Import TransactionWithAmount explicitly
import 'package:intl/intl.dart'; // For date formatting

class FlowPage extends ConsumerStatefulWidget {
  const FlowPage({super.key});

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {
  final ScrollController _scrollController = ScrollController();
  List<TransactionWithAmount> _transactions = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _perPage = 15; // Number of items to fetch per page

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions({bool isLoadMore = false}) async {
    if (_isLoading || (!_hasMore && isLoadMore)) return;

    setState(() {
      _isLoading = true;
      if (!isLoadMore) {
        _transactions = []; // Clear list for initial fetch or refresh
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final repository = ref.read(transactionRepositoryProvider);
      final ledgerId = ref.read(selectedLedgerProvider).value?.ledgerId;
      final newTransactionsStream =
          repository.watchTransactionsWithAmountPaginated(
        limit: _perPage,
        offset: _currentPage * _perPage,
        ledgerId: ledgerId,
      );

      // Listen to the stream once for the current batch of data
      final newTransactions = await newTransactionsStream.first;

      setState(() {
        if (newTransactions.isNotEmpty) {
          _transactions.addAll(newTransactions);
          _currentPage++;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Handle error, e.g., show a snackbar or a message
      });
      print("Error fetching transactions: $e");
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                200 && // Trigger load more a bit before the end
        _hasMore &&
        !_isLoading) {
      _fetchTransactions(isLoadMore: true);
    }
  }

  String _formatDate(DateTime date) {
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
      return DateFormat('M月d日 EEEE', 'zh_CN').format(date); // 例如: 5月8日 星期四
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime); // e.g., 11:41
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Row(
              children: [
                const Text(
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
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading && _transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          'No transactions yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      itemCount: _transactions.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          return _hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        final transactionWithAmount = _transactions[index];
        final transaction = transactionWithAmount.transaction;
        final uiDate = _formatDate(transaction.transactionDate);
        final previousUiDate = index > 0
            ? _formatDate(_transactions[index - 1].transaction.transactionDate)
            : null;

        if (index == 0 || uiDate != previousUiDate) {
          final dailyOut = _transactions
              .where((twa) =>
                  _formatDate(twa.transaction.transactionDate) == uiDate &&
                  twa.nature == TransactionNature.OUTFLOW)
              .fold(0.0, (sum, twa) => sum + twa.amount.abs());
          final dailyIn = _transactions
              .where((twa) =>
                  _formatDate(twa.transaction.transactionDate) == uiDate &&
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
              _buildTransactionItem(transactionWithAmount),
            ],
          );
        }
        return _buildTransactionItem(transactionWithAmount);
      },
    );
  }

  Widget _buildTransactionItem(TransactionWithAmount transactionWithAmount) {
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
        onDelete: _onTransactionDeleted,
      ),
    );
  }

  // Keep _getCategoryColor or adapt it as needed
  Color _getCategoryColor(String category) {
    // This is a placeholder. You'll need a more robust way to map categories to colors
    // or have this information in your data models.
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('shop') || lowerCategory.contains('购')) {
      return const Color(0xFF4CAF50);
    } else if (lowerCategory.contains('service') ||
        lowerCategory.contains('服务')) {
      return const Color(0xFF2196F3);
    } else if (lowerCategory.contains('food') || lowerCategory.contains('餐')) {
      return const Color(0xFFFFC107);
    } else if (lowerCategory.contains('transport') ||
        lowerCategory.contains('交通')) {
      return const Color(0xFFFF5722);
    }
    return const Color(0xFF9E9E9E); // Default
  }

  // 刷新交易列表
  Future<void> _refreshTransactions() async {
    await _fetchTransactions(isLoadMore: false);
  }

  // 删除交易后的回调
  void _onTransactionDeleted() {
    _refreshTransactions();
  }
}

// Remove MockTransaction class and _generateMockTransactions method
// class MockTransaction { ... }
// List<MockTransaction> _generateMockTransactions() { ... }
