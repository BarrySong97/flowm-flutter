import 'package:flowm/components/overview/stat_card.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/components/overview/monthly_overview_card.dart';
import 'package:flowm/components/overview/assets_overview_grid.dart';
import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountRepository = ref.watch(accountRepositoryProvider);

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
            FutureBuilder<List<AccountWithBalance>>(
              // 获取所有资产账户，不限制数量
              future: accountRepository.getTopAssetAccounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('加载失败: ${snapshot.error}'));
                }

                final allAccounts = snapshot.data ?? [];

                // 计算所有账户的总资产
                double totalAssets = 0;
                for (var account in allAccounts) {
                  totalAssets += account.balance;
                }

                // 只取前4个用于显示
                final topAccounts = allAccounts.take(4).toList();

                // Create AssetItems from top accounts
                final assetItems = topAccounts.map((accountWithBalance) {
                  // 格式化余额
                  final formatter =
                      NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
                  final formattedBalance =
                      formatter.format(accountWithBalance.balance);

                  // 这里随机生成涨跌幅，实际应用中可能需要从其他地方获取
                  final change =
                      (accountWithBalance.balance > 1000) ? 2.5 : -1.2;

                  return AssetItem(
                    symbol: accountWithBalance.account.accountName,
                    amount: formattedBalance,
                    changePercentage: change,
                    backgroundColor: change >= 0
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                  );
                }).toList();

                // 如果获取到的账户少于4个，用默认值填充
                if (assetItems.length < 4) {
                  final defaultItems = [
                    AssetItem(
                      symbol: '现金',
                      amount: '¥0.00',
                      changePercentage: 0.0,
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                    AssetItem(
                      symbol: '支付宝',
                      amount: '¥0.00',
                      changePercentage: 0.0,
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                    AssetItem(
                      symbol: '微信',
                      amount: '¥0.00',
                      changePercentage: 0.0,
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                    AssetItem(
                      symbol: '银行卡',
                      amount: '¥0.00',
                      changePercentage: 0.0,
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                  ];

                  for (int i = assetItems.length; i < 4; i++) {
                    if (i < defaultItems.length) {
                      assetItems.add(defaultItems[i]);
                    }
                  }
                }

                // 格式化总资产
                final formatter =
                    NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
                final formattedTotalAssets = formatter.format(totalAssets);
                const formattedLiabilities = '¥0.00'; // 示例，实际应用需要计算
                final netAssets = totalAssets; // 这里简化处理，实际应用需要计算资产-负债
                final formattedNetAssets = formatter.format(netAssets);

                return AssetsOverviewGrid(
                  assets: assetItems,
                  netAssets: formattedNetAssets,
                  totalAssets: formattedTotalAssets,
                  totalLiabilities: formattedLiabilities,
                );
              },
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
