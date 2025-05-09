import 'package:flutter/material.dart';
import 'dart:math';
import '../components/common/transaction_list_item.dart';

class FlowPage extends StatelessWidget {
  const FlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = _generateMockTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: const Color(0xFF4CAF50),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                color: const Color(0xFF4CAF50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '全部类型',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.grid_view, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '2025年5月',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                          ],
                        ),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '总支出¥368.83 ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              TextSpan(
                                text: '总入账¥0.00',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];

              // Add date header
              if (index == 0 ||
                  transactions[index].date != transactions[index - 1].date) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            transaction.date,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '出 ${transaction.totalOut}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '入 ${transaction.totalIn}',
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
                    _buildTransactionItem(transaction),
                  ],
                );
              }

              return _buildTransactionItem(transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(MockTransaction transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TransactionListItem(
        title: transaction.title,
        subtitle: '${transaction.time} · ${transaction.location}',
        amount: transaction.isExpense
            ? '-${transaction.amount}'
            : '+${transaction.amount}',
        type: transaction.category,
        statusColor: _getCategoryColor(transaction.category),
        isExpense: transaction.isExpense,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '购物':
        return const Color(0xFF4CAF50);
      case '服务':
        return const Color(0xFF2196F3);
      case '餐饮':
        return const Color(0xFFFFC107);
      case '交通':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  List<MockTransaction> _generateMockTransactions() {
    final random = Random();
    final List<MockTransaction> transactions = [];

    final List<String> categories = ['购物', '服务', '餐饮', '交通'];
    final List<String> locations = [
      '合力超市',
      '泽祥超市',
      '洋祥风尚科技',
      '美团',
      '饿了么',
      '滴滴出行'
    ];
    final List<String> titles = ['日用品', '水果', '服务费', '技术支持', '午餐', '晚餐', '打车'];

    // May 8 transactions
    transactions.add(
      MockTransaction(
        title: '购物',
        category: '购物',
        amount: '37.20',
        date: '5月8日 昨天',
        time: '11:41',
        location: '合力超市',
        isExpense: true,
        totalOut: '37.20',
        totalIn: '0.00',
      ),
    );

    // May 6 transactions
    transactions.add(
      MockTransaction(
        title: '购物',
        category: '购物',
        amount: '64.05',
        date: '5月6日 星期二',
        time: '11:38',
        location: '合力超市',
        isExpense: true,
        totalOut: '74.17',
        totalIn: '0.00',
      ),
    );

    transactions.add(
      MockTransaction(
        title: '服务',
        category: '服务',
        amount: '10.12',
        date: '5月6日 星期二',
        time: '09:56',
        location: '洋祥风尚科技',
        isExpense: true,
        totalOut: '74.17',
        totalIn: '0.00',
      ),
    );

    // Generate 97 more random transactions
    final List<String> days = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

    for (int i = 3; i < 100; i++) {
      final day = random.nextInt(30) + 1;
      final dayOfWeek = days[random.nextInt(days.length)];
      final category = categories[random.nextInt(categories.length)];
      final location = locations[random.nextInt(locations.length)];
      final title = category == '购物' || category == '餐饮'
          ? titles[random.nextInt(3)]
          : titles[3 + random.nextInt(4)];
      final isExpense = random.nextDouble() < 0.9; // 90% chance of expense
      final hour = random.nextInt(12) + 8; // 8 AM to 8 PM
      final minute = random.nextInt(60);
      final amount = (random.nextDouble() * 100).toStringAsFixed(2);
      final totalOut = (random.nextDouble() * 200).toStringAsFixed(2);
      final totalIn = (random.nextDouble() * 50).toStringAsFixed(2);

      transactions.add(
        MockTransaction(
          title: title,
          category: category,
          amount: amount,
          date: '5月${day}日 ${dayOfWeek}',
          time:
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          location: location,
          isExpense: isExpense,
          totalOut: totalOut,
          totalIn: totalIn,
        ),
      );
    }

    // Sort by date (just for demonstration - this is a simple sort)
    transactions.sort((a, b) {
      final aDay = int.parse(a.date.split('月')[1].split('日')[0]);
      final bDay = int.parse(b.date.split('月')[1].split('日')[0]);
      return bDay.compareTo(aDay); // Descending order
    });

    return transactions;
  }
}

class MockTransaction {
  final String title;
  final String category;
  final String amount;
  final String date;
  final String time;
  final String location;
  final bool isExpense;
  final String totalOut;
  final String totalIn;

  MockTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.time,
    required this.location,
    required this.isExpense,
    required this.totalOut,
    required this.totalIn,
  });
}
