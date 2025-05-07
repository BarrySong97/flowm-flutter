import 'package:flowm/components/overview/stat_card.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/components/overview/monthly_overview_card.dart';
import 'package:flowm/components/overview/assets_overview_grid.dart';
import 'package:flutter/material.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final assetItems = [
      AssetItem(
        symbol: 'BTC',
        amount: '\$1,876,641.68',
        changePercentage: 2.68,
        backgroundColor: const Color(0xFFE8F5E9),
      ),
      AssetItem(
        symbol: 'MATIC',
        amount: '\$42.04',
        changePercentage: 8.68,
        backgroundColor: const Color(0xFFE8F5E9),
      ),
      AssetItem(
        symbol: 'DOT',
        amount: '\$423.05',
        changePercentage: -1.08,
        backgroundColor: const Color(0xFFFFEBEE),
      ),
      AssetItem(
        symbol: 'ETH',
        amount: '\$32,784.0',
        changePercentage: -0.31,
        backgroundColor: const Color(0xFFFFEBEE),
      ),
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            // Monthly Overview Card
            const MonthlyOverviewCard(
              month: '5月',
              expense: '¥0.00',
              income: '¥0.00',
              balance: '¥0.00',
            ),

            // Assets Overview
            AssetsOverviewGrid(
              assets: assetItems,
              netAssets: '¥150,000.00',
              totalAssets: '¥200,000.00',
              totalLiabilities: '¥50,000.00',
            ),

            // Recent Transactions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
                  child: Text(
                    '今日交易',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      TransactionListItem(
                        title: '星巴克',
                        subtitle: '微信 -> 餐饮',
                        amount: '¥35.00',
                        type: '支出',
                        statusColor: const Color(0xFF34C759),
                        isExpense: true,
                      ),
                      TransactionListItem(
                        title: '地铁',
                        subtitle: '支付宝 -> 交通',
                        amount: '¥4.00',
                        type: '支出',
                        statusColor: const Color(0xFF34C759),
                        isExpense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 16.0),
                  child: Text(
                    '昨日交易',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    children: [
                      TransactionListItem(
                        title: '工资收入',
                        subtitle: '工商银行 -> 收入',
                        amount: '¥8,000.00',
                        type: '收入',
                        statusColor: const Color(0xFF007AFF),
                        isExpense: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('查看更多交易'),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
