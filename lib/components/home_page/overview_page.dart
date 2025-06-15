import 'package:flowm/components/overview/stat_card.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/components/overview/monthly_overview_card.dart';
import 'package:flowm/components/overview/assets_overview_grid.dart';
import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/transaction/transaction_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';

// Provider to fetch current month's expenses
final currentMonthExpenseProvider = FutureProvider<double>((ref) async {
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) return 0.0;

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final repository = ref.watch(accountRepositoryProvider);
  return repository.getExpenseInPeriod(
      selectedLedger.ledgerId, startOfMonth, endOfMonth);
});

// Provider to fetch current month's income
final currentMonthIncomeProvider = FutureProvider<double>((ref) async {
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) return 0.0;

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final repository = ref.watch(accountRepositoryProvider);
  return repository.getIncomeInPeriod(
      selectedLedger.ledgerId, startOfMonth, endOfMonth);
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
  final expense = await ref.watch(currentMonthExpenseProvider.future);
  final income = await ref.watch(currentMonthIncomeProvider.future);
  final balance = income - expense;
  return (expense: expense, income: income, balance: balance);
});

// Provider to fetch latest transactions
final latestTransactionsProvider = StreamProvider((ref) {
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
    FutureProvider<List<AccountWithBalance>>((ref) async {
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  if (selectedLedger == null) return [];

  final repository = ref.watch(accountRepositoryProvider);
  return repository.getTopAssetAccountsByLedger(
      ledgerId: selectedLedger.ledgerId);
});

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 使用共享的topAssetAccountsProvider
    final topAssetsAsync = ref.watch(topAssetAccountsProvider);
    final monthlyOverviewDataAsync = ref.watch(monthlyOverviewDataProvider);
    final latestTransactionsAsync = ref.watch(latestTransactionsProvider);
    final totalLiabilitiesAsync = ref.watch(totalLiabilitiesProvider);

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
            monthlyOverviewDataAsync.when(
                data: (data) {
                  final formatter =
                      NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
                  final formattedExpense = formatter.format(data.expense);
                  final formattedIncome = formatter.format(data.income);
                  final formattedBalance = formatter.format(data.balance);

                  return MonthlyOverviewCard(
                    month: '${DateTime.now().month}月', // Display current month
                    expense: formattedExpense,
                    income: formattedIncome,
                    balance: formattedBalance,
                  );
                },
                loading: () => const MonthlyOverviewCard(
                      month: '--月',
                      expense: '加载中...',
                      income: '加载中...',
                      balance: '加载中...',
                    ),
                error: (error, stackTrace) {
                  return const MonthlyOverviewCard(
                    month: '--月',
                    expense: '错误',
                    income: '错误',
                    balance: '错误',
                  );
                }),

            // Assets Overview
            topAssetsAsync.when(
              data: (allAccounts) {
                return totalLiabilitiesAsync.when(
                  data: (totalLiabilitiesValue) {
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

                      // 计算该账户余额占总资产的百分比
                      final percentValue = totalAssets > 0
                          ? (accountWithBalance.balance / totalAssets * 100)
                          : 0.0;

                      return AssetItem(
                        symbol: accountWithBalance.account.accountName,
                        amount: formattedBalance,
                        changePercentage: percentValue,
                        backgroundColor: const Color(0xFFE8F5E9),
                        percent: '${percentValue.toStringAsFixed(2)}%',
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
                          percent: '0.00%',
                        ),
                        AssetItem(
                          symbol: '支付宝',
                          amount: '¥0.00',
                          changePercentage: 0.0,
                          backgroundColor: const Color(0xFFE8F5E9),
                          percent: '0.00%',
                        ),
                        AssetItem(
                          symbol: '微信',
                          amount: '¥0.00',
                          changePercentage: 0.0,
                          backgroundColor: const Color(0xFFE8F5E9),
                          percent: '0.00%',
                        ),
                        AssetItem(
                          symbol: '银行卡',
                          amount: '¥0.00',
                          changePercentage: 0.0,
                          backgroundColor: const Color(0xFFE8F5E9),
                          percent: '0.00%',
                        ),
                      ];

                      for (int i = assetItems.length; i < 4; i++) {
                        if (i < defaultItems.length) {
                          assetItems.add(defaultItems[i]);
                        }
                      }
                    }

                    // 格式化总资产、总负债和净资产
                    final formatter =
                        NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
                    final formattedTotalAssets = formatter.format(totalAssets);
                    final formattedTotalLiabilities =
                        formatter.format(totalLiabilitiesValue.abs());
                    final netAssets = totalAssets + totalLiabilitiesValue;
                    final formattedNetAssets = formatter.format(netAssets);

                    return AssetsOverviewGrid(
                      assets: assetItems,
                      netAssets: formattedNetAssets,
                      totalAssets: formattedTotalAssets,
                      totalLiabilities: formattedTotalLiabilities,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('加载负债失败: $error'),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('加载资产失败: $error'),
                ),
              ),
            ),

            // Recent Transactions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 0.0),
                  child: Text(
                    '最近交易',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                latestTransactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: const Center(
                          child: Text('暂无交易记录'),
                        ),
                      );
                    }

                    // Group transactions by date
                    final groupedTransactions =
                        <DateTime, List<TransactionWithAmount>>{};
                    for (var transactionWithAmount in transactions) {
                      final transactionDate = DateTime(
                        transactionWithAmount.transaction.transactionDate.year,
                        transactionWithAmount.transaction.transactionDate.month,
                        transactionWithAmount.transaction.transactionDate.day,
                      );
                      if (groupedTransactions.containsKey(transactionDate)) {
                        groupedTransactions[transactionDate]!
                            .add(transactionWithAmount);
                      } else {
                        groupedTransactions[transactionDate] = [
                          transactionWithAmount
                        ];
                      }
                    }

                    // Sort dates in descending order
                    final sortedDates = groupedTransactions.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                    return Container(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) => const ColoredBox(
                            color: Colors.transparent,
                            child: SizedBox(height: 16)),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final transactionsOnDate = groupedTransactions[date]!;
                          final formattedDate =
                              DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN')
                                  .format(date);

                          // Calculate daily totals using the 'nature' field
                          double dailyIn = 0.0;
                          double dailyOut = 0.0;

                          for (var twa in transactionsOnDate) {
                            if (twa.nature == TransactionNature.INFLOW) {
                              dailyIn += twa.amount.abs();
                            } else if (twa.nature ==
                                TransactionNature.OUTFLOW) {
                              dailyOut += twa.amount.abs();
                            }
                          }

                          final formatter = NumberFormat.currency(
                              locale: 'zh_CN', symbol: '¥');
                          final formattedDailyIn = formatter.format(dailyIn);
                          final formattedDailyOut = formatter.format(dailyOut);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    // Changed to Row to accommodate totals
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Row(
                                        // Row for income and expense totals
                                        children: [
                                          Text(
                                            '出 $formattedDailyOut',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '入 $formattedDailyIn',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: transactionsOnDate.length,
                                  itemBuilder: (context, transactionIndex) {
                                    final transactionWithAmount =
                                        transactionsOnDate[transactionIndex];
                                    final transaction =
                                        transactionWithAmount.transaction;

                                    // Determine if it's an expense using the 'nature' field
                                    final bool isExpense =
                                        transactionWithAmount.nature ==
                                            TransactionNature.OUTFLOW;

                                    final formatter = NumberFormat.currency(
                                        locale: 'zh_CN', symbol: '¥');
                                    // Display the absolute amount, as nature handles inflow/outflow distinction
                                    final formattedAmount = formatter.format(
                                        transactionWithAmount.amount.abs());

                                    return TransactionListItem(
                                      title: transaction.description ?? '无描述',
                                      transactionId:
                                          transaction.transactionId.toString(),
                                      subtitle:
                                          '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}',
                                      amount: formattedAmount,
                                      type: getTransactionFlowType(
                                          transactionWithAmount
                                                  .fromAccount?.accountType ??
                                              AccountType.ASSET,
                                          transactionWithAmount
                                                  .toAccount?.accountType ??
                                              AccountType.ASSET),
                                      statusColor: isExpense
                                          ? const Color(
                                              0xFF007AFF) // Blue for expense
                                          : const Color(
                                              0xFF34C759), // Green for income
                                      isExpense: isExpense,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    print('Error loading latest transactions: $error\n$stack');
                    return const Center(child: Text('加载交易失败'));
                  },
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
