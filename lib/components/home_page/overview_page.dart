import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/components/overview/assets_overview_grid.dart';
import 'package:flowm/components/overview/monthly_overview_card.dart';
import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/home_page/overview_page_providers.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/utils/number_format_utils.dart';
import 'package:flowm/utils/provider_invalidator.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../pages/main_screen.dart';

class OverviewPage extends ConsumerStatefulWidget {
  final Function(int)? onPageTap;
  
  const OverviewPage({super.key, this.onPageTap});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 第一次加载时主动更新
    if (!kIsWeb) {
      print('update widget');
      _updateWidget(ref.read(monthlyOverviewDataProvider));
      _updateAccountDataWidget();
    }
  }

  void _updateAccountDataWidget() async {
    try {
      final selectedLedger = await ref.read(selectedLedgerProvider.future);
      if (selectedLedger == null) return;
      debugPrint('save account data');

      final accountRepository = ref.read(accountRepositoryProvider);
      await accountRepository
          .updateHomeWidgetAccountData(selectedLedger.ledgerId);
    } catch (e) {
      debugPrint('[HomeWidget] Error updating initial account data: $e');
    }
  }

  void _updateWidget(
      AsyncValue<({double balance, double expense, double income})> data) {
    if (kIsWeb) {
      return;
    }
    data.whenData((value) {
      debugPrint(
          '[HomeWidget] Updating data: expense=${value.expense}, income=${value.income}, balance=${value.balance}');
      HomeWidget.setAppGroupId('group.flowm');
      HomeWidget.saveWidgetData<String>('expense', value.expense.toString());
      HomeWidget.saveWidgetData<String>('income', value.income.toString());
      HomeWidget.saveWidgetData<String>('balance', value.balance.toString());
      final result =
          HomeWidget.updateWidget(name: 'FlowmWidget', iOSName: 'FlowmWidget');
      result.then((value) => debugPrint('[HomeWidget] Update result: $value'));
    });
  }

  // 构建月度总览卡片
  Widget _buildMonthlyOverviewCard(
      AsyncValue<({double expense, double income, double balance})>
          monthlyOverviewDataAsync) {
    return monthlyOverviewDataAsync.when(
        data: (data) {
          double fixNegativeZero(double value) {
            // 如果接近 0，就返回正 0
            return value.abs() < 0.00001 ? 0.0 : value;
          }

          final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
          final formattedExpense =
              formatter.format(fixNegativeZero(data.expense));
          final formattedIncome =
              formatter.format(fixNegativeZero(data.income));
          final formattedBalance =
              formatter.format(fixNegativeZero(data.balance));

          return MonthlyOverviewCard(
            month: '${DateTime.now().month}月', // Display current month
            expense: formattedExpense,
            income: formattedIncome,
            balance: formattedBalance,
            onTap: () {
              context.pushNamed('monthlyDetails', extra: {
                'month': '${DateTime.now().month}月',
              });
            },
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
        });
  }

  // 构建资产总览网格
  Widget _buildAssetsOverview(
      AsyncValue<List<AccountWithBalance>> topAssetsAsync,
      AsyncValue<double> totalLiabilitiesAsync) {
    return topAssetsAsync.when(
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

            List<AssetItem> assetItems;
            if (topAccounts.isEmpty) {
              assetItems = List.generate(4, (index) {
                return AssetItem(
                  id: 0,
                  amountNumber: 0,
                  name: '',
                  symbol: '资产账户 ${index + 1}',
                  amount: '¥--',
                  changePercentage: 0.0,
                  backgroundColor: const Color(0xFFF5F5F5),
                  percent: '--%',
                );
              });
            } else {
              // Create AssetItems from top accounts
              assetItems = topAccounts.map((accountWithBalance) {
                // 格式化余额 - 小于6位数(100,000)时不格式化
                final formattedBalance = NumberFormatUtils.smartFormatCurrency(
                    accountWithBalance.balance,
                    useWan: true,
                    minFormatThreshold: 10000000);

                // 计算该账户余额占总资产的百分比
                final percentValue = totalAssets > 0
                    ? (accountWithBalance.balance / totalAssets * 100)
                    : 0.0;

                return AssetItem(
                  id: accountWithBalance.account.accountId,
                  name: accountWithBalance.account.accountName,
                  symbol: "¥",
                  amountNumber: accountWithBalance.balance,
                  amount: formattedBalance,
                  changePercentage: percentValue,
                  backgroundColor: const Color(0xFFE8F5E9),
                  percent: '${percentValue.toStringAsFixed(2)}%',
                );
              }).toList();
            }

            // 格式化总资产、总负债和净资产 - 小于6位数时不格式化
            final formattedTotalAssets = NumberFormatUtils.smartFormatCurrency(
                totalAssets,
                useWan: true,
                minFormatThreshold: 100000);
            final formattedTotalLiabilities =
                NumberFormatUtils.smartFormatCurrency(
                    totalLiabilitiesValue.abs(),
                    useWan: true,
                    minFormatThreshold: 100000);
            final netAssets = totalAssets + totalLiabilitiesValue;
            final formattedNetAssets = NumberFormatUtils.smartFormatCurrency(
                netAssets,
                useWan: true,
                minFormatThreshold: 100000);

            return AssetsOverviewGrid(
              assets: assetItems,
              netAssets: formattedNetAssets,
              totalAssets: formattedTotalAssets,
              totalLiabilities: formattedTotalLiabilities,
              onViewMoreTap: () {
                print('onViewMoreTap called'); // Debug log
                widget.onPageTap?.call(1); // Navigate to assets page (index 1)
              },
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
    );
  }

  // 构建最近交易列表
  Widget _buildRecentTransactions(
      AsyncValue<List<TransactionWithAmount>> latestTransactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
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
                  borderRadius: BorderRadius.circular(6.0),
                ),
                margin: const EdgeInsets.only(top: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
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
                groupedTransactions[transactionDate] = [transactionWithAmount];
              }
            }

            // Sort dates in descending order
            final sortedDates = groupedTransactions.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Container(
              padding: const EdgeInsets.only(top: 0),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16),
                separatorBuilder: (context, index) => const ColoredBox(
                    color: Colors.transparent, child: SizedBox(height: 16)),
                itemCount: sortedDates.length,
                itemBuilder: (context, dateIndex) {
                  final date = sortedDates[dateIndex];
                  final transactionsOnDate = groupedTransactions[date]!;
                  final formattedDate =
                      DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(date);

                  // Calculate daily totals using the 'nature' field
                  double dailyIn = 0.0;
                  double dailyOut = 0.0;

                  for (var twa in transactionsOnDate) {
                    if (twa.nature == TransactionNature.INFLOW) {
                      dailyIn += twa.amount.abs();
                    } else if (twa.nature == TransactionNature.OUTFLOW) {
                      dailyOut += twa.amount.abs();
                    }
                  }

                  final formatter =
                      NumberFormat.currency(locale: 'zh_CN', symbol: '¥');
                  final formattedDailyIn = formatter.format(dailyIn);
                  final formattedDailyOut = formatter.format(dailyOut);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
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
                                mainAxisSize: MainAxisSize.min,
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
                          padding: const EdgeInsets.only(top: 0),
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
                            final formattedAmount = formatter
                                .format(transactionWithAmount.amount.abs());

                            return TransactionListItem(
                              title: transaction.description ?? '无描述',
                              transactionId:
                                  transaction.transactionId.toString(),
                              subtitle:
                                  '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}',
                              amount: formattedAmount,
                              fromAccountType: transactionWithAmount
                                  .fromAccount?.accountType,
                              toAccountType:
                                  transactionWithAmount.toAccount?.accountType,
                              type: getTransactionFlowType(
                                  transactionWithAmount
                                          .fromAccount?.accountType ??
                                      AccountType.ASSET,
                                  transactionWithAmount
                                          .toAccount?.accountType ??
                                      AccountType.ASSET),
                              statusColor: isExpense
                                  ? const Color(0xFF007AFF) // Blue for expense
                                  : const Color(0xFF34C759), // Green for income
                              isExpense: isExpense,
                              onDelete: () => {
                                if (transactionWithAmount
                                            .fromAccount?.accountType !=
                                        null &&
                                    transactionWithAmount
                                            .toAccount?.accountType !=
                                        null)
                                  {
                                    invalidateProvidersForTransaction(
                                      ref,
                                      fromAccountType: transactionWithAmount
                                              .fromAccount?.accountType ??
                                          AccountType.ASSET,
                                      toAccountType: transactionWithAmount
                                              .toAccount?.accountType ??
                                          AccountType.ASSET,
                                    )
                                  }
                              },
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            print('Error loading latest transactions: $error\n$stack');
            return const Center(child: Text('加载交易失败'));
          },
        ),
        const SizedBox(height: 24.0),
        TextButton(
          onPressed: () {
            ref.read(mainScreenIndexProvider.notifier).state = 3;
          },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Listen to the monthly overview data and update the home widget
    ref.listen(monthlyOverviewDataProvider, (previous, next) {
      _updateWidget(next);
    });

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
            _buildMonthlyOverviewCard(monthlyOverviewDataAsync),

            // Assets Overview
            _buildAssetsOverview(topAssetsAsync, totalLiabilitiesAsync),

            // Recent Transactions
            _buildRecentTransactions(latestTransactionsAsync),
          ],
        ),
      ),
    );
  }
}
