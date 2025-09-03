import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/components/overview/assets_overview_grid.dart';
import 'package:flowm/components/overview/monthly_overview_card.dart';
import 'package:flowm/db/app_database.dart';
import 'package:flowm/db/dao/account_dao.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/state/account/account_repository.dart';
import 'package:flowm/state/home_page/overview_page_providers.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/utils/number_format_utils.dart';
import 'package:flowm/utils/provider_invalidator.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
      _updateAllWidgets();
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

  Future<void> _updateAllWidgets() async {
    if (kIsWeb) {
      return;
    }

    try {
      final selectedLedger = await ref.read(selectedLedgerProvider.future);
      if (selectedLedger == null) return;

      debugPrint('[HomeWidget] 🔴 Starting _updateAllWidgets()');
      HomeWidget.setAppGroupId('group.flowm');

      // Update FlowmWidget data (existing functionality)
      final monthlyData = await ref.read(monthlyOverviewDataProvider.future);
      debugPrint(
          '[HomeWidget] 🔴 Updating FlowmWidget data: expense=${monthlyData.expense}, income=${monthlyData.income}, balance=${monthlyData.balance}');

      HomeWidget.saveWidgetData<String>(
          'expense', monthlyData.expense.toString());
      HomeWidget.saveWidgetData<String>(
          'income', monthlyData.income.toString());
      HomeWidget.saveWidgetData<String>(
          'balance', monthlyData.balance.toString());

      // Update daily expense data for FlowmWidget chart
      await _updateDailyExpenseData(selectedLedger);

      debugPrint('[HomeWidget] 🔴 FlowmWidget data saved to UserDefaults');

      // Update ExpensePieChartWidget data
      await _updateExpensePieChartData(selectedLedger);

      // Update AssetsOverviewWidget data
      await _updateAssetsOverviewData(selectedLedger);

      // Update the widget extension (all widget types within FlowmWidget target will be refreshed)
      debugPrint('[HomeWidget] 🔴 Calling HomeWidget.updateWidget...');
      final result = await HomeWidget.updateWidget(
          name: 'FlowmWidget', iOSName: 'FlowmWidget');

      debugPrint('[HomeWidget] 🔴 Update result: $result');
    } catch (e) {
      debugPrint('[HomeWidget] Error updating widgets: $e');
    }
  }

  Future<void> _updateDailyExpenseData(Ledger selectedLedger) async {
    try {
      final now = DateTime.now();

      // 计算最近10天的开始日期和结束日期
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDateTime = now.subtract(const Duration(days: 9));
      final startDate = DateTime(startDateTime.year, startDateTime.month,
          startDateTime.day, 0, 0, 0); // 开始日期的00:00:00

      debugPrint(
          '[HomeWidget] 🔴 Getting daily expense data from $startDate to $endDate');

      // 直接调用repository获取最近10天的数据
      final expenseRepository = ref.read(expenseRepositoryProvider);
      final chartData = await expenseRepository.getExpenseChartData(
        startDate: startDate,
        endDate: endDate,
        ledgerId: selectedLedger.ledgerId,
      );
      print('chartData: ${chartData.length}');
      // 确保只取前10天的数据
      final limitedChartData = chartData.take(10).toList();

      // Format daily expense data for widget
      final List<Map<String, dynamic>> dailyExpenseData = [];
      for (final chartItem in limitedChartData) {
        // chartItem.x 是索引，chartItem.day 是格式化的日期字符串 "M/d"
        final dateParts = chartItem.day.split('/');
        if (dateParts.length == 2) {
          final dayNumber = int.tryParse(dateParts[1]) ?? 1;

          dailyExpenseData.add({
            'day': dayNumber,
            'amount': chartItem.y,
            'dateString': chartItem.day, // 直接使用已经格式化好的日期字符串
          });
        }
      }

      // Save as JSON string
      final dailyExpenseJson = jsonEncode(dailyExpenseData);
      HomeWidget.saveWidgetData<String>('dailyExpenseData', dailyExpenseJson);

      debugPrint(
          '[HomeWidget] 🔴 Updated daily expense data: ${dailyExpenseData.length} days');
      debugPrint('[HomeWidget] 🔴 Daily expense JSON: $dailyExpenseJson');
    } catch (e) {
      debugPrint('[HomeWidget] Error updating daily expense data: $e');
    }
  }

  Future<void> _updateExpensePieChartData(Ledger selectedLedger) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final expenseRepository = ref.read(expenseRepositoryProvider);
      final expenseAccountTree = await expenseRepository.getExpenseAccountTree(
        startDate: startOfMonth,
        endDate: endOfMonth,
        ledgerId: selectedLedger.ledgerId,
      );

      // Format expense data for pie chart widget
      final List<Map<String, dynamic>> expenseCategoryData = [];
      for (final node in expenseAccountTree) {
        if (node.balance > 0) {
          // Only include categories with expenses
          expenseCategoryData.add({
            'category': node.accountData.accountName,
            'amount': node.balance,
            'percentage': node.percentage,
          });
        }
      }

      // Save as JSON string
      final expenseDataJson = jsonEncode(expenseCategoryData);
      HomeWidget.saveWidgetData<String>('expensePieChartData', expenseDataJson);

      debugPrint(
          '[HomeWidget] 🔴 Updated ExpensePieChartWidget data: ${expenseCategoryData.length} categories');
      debugPrint(
          '[HomeWidget] 🔴 ExpensePieChartWidget JSON: $expenseDataJson');
    } catch (e) {
      debugPrint('[HomeWidget] Error updating expense pie chart data: $e');
    }
  }

  Future<void> _updateAssetsOverviewData(Ledger selectedLedger) async {
    try {
      final topAssets = await ref.read(topAssetAccountsProvider.future);
      final totalLiabilities = await ref.read(totalLiabilitiesProvider.future);

      // Calculate total assets
      double totalAssetsValue = 0;
      for (var account in topAssets) {
        totalAssetsValue += account.balance;
      }

      // Only take top 4 accounts for widget display
      final topAccounts = topAssets.take(4).toList();

      // Format asset items
      final List<Map<String, dynamic>> assetItems = [];
      for (final accountWithBalance in topAccounts) {
        final percentValue = totalAssetsValue > 0
            ? (accountWithBalance.balance / totalAssetsValue * 100)
            : 0.0;

        assetItems.add({
          'id': accountWithBalance.account.accountId,
          'name': accountWithBalance.account.accountName,
          'amount': accountWithBalance.balance,
          'percentage': percentValue,
        });
      }

      // Calculate net assets
      final netAssets = totalAssetsValue + totalLiabilities;

      // Create assets overview data
      final assetsOverviewData = {
        'assetItems': assetItems,
        'totalAssets': totalAssetsValue,
        'totalLiabilities': totalLiabilities.abs(),
        'netAssets': netAssets,
        'currencySymbol': selectedLedger.currencySymbol ?? '¥',
      };

      // Save as JSON string
      final assetsDataJson = jsonEncode(assetsOverviewData);
      HomeWidget.saveWidgetData<String>('assetsOverviewData', assetsDataJson);

      debugPrint(
          '[HomeWidget] 🔴 Updated AssetsOverviewWidget data: ${assetItems.length} assets, total: $totalAssetsValue');
      debugPrint('[HomeWidget] 🔴 AssetsOverviewWidget JSON: $assetsDataJson');
    } catch (e) {
      debugPrint('[HomeWidget] Error updating assets overview data: $e');
    }
  }

  void _updateWidget(
      AsyncValue<({double balance, double expense, double income})> data) {
    if (kIsWeb) {
      return;
    }
    data.whenData((value) {
      // Trigger comprehensive widget update
      _updateAllWidgets();
    });
  }

  // 构建月度总览卡片
  Widget _buildMonthlyOverviewCard(
      AsyncValue<({double expense, double income, double balance})>
          monthlyOverviewDataAsync,
      Ledger? selectedLedger) {
    return monthlyOverviewDataAsync.when(
        data: (data) {
          double fixNegativeZero(double value) {
            // 如果接近 0，就返回正 0
            return value.abs() < 0.00001 ? 0.0 : value;
          }

          final formatter = NumberFormat.currency(
              locale: 'zh_CN', symbol: selectedLedger?.currencySymbol ?? '¥');
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
      AsyncValue<double> totalLiabilitiesAsync,
      Ledger? selectedLedger) {
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
                  amount: '${selectedLedger?.currencySymbol ?? '¥'}--',
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
                    symbol: selectedLedger?.currencySymbol ?? "¥",
                    minFormatThreshold: 10000000);

                // 计算该账户余额占总资产的百分比
                final percentValue = totalAssets > 0
                    ? (accountWithBalance.balance / totalAssets * 100)
                    : 0.0;

                return AssetItem(
                  id: accountWithBalance.account.accountId,
                  name: accountWithBalance.account.accountName,
                  symbol: selectedLedger?.currencySymbol ?? '¥',
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
                symbol: selectedLedger?.currencySymbol ?? "¥",
                minFormatThreshold: 100000);
            final formattedTotalLiabilities =
                NumberFormatUtils.smartFormatCurrency(
                    totalLiabilitiesValue.abs(),
                    symbol: selectedLedger?.currencySymbol ?? "¥",
                    useWan: true,
                    minFormatThreshold: 100000);
            final netAssets = totalAssets + totalLiabilitiesValue;
            final formattedNetAssets = NumberFormatUtils.smartFormatCurrency(
                netAssets,
                useWan: true,
                symbol: selectedLedger?.currencySymbol ?? "¥",
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
      AsyncValue<List<TransactionWithAmount>> latestTransactionsAsync,
      Ledger? selectedLedger) {
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

            // Sort dates in descending order and sort transactions within each date
            final sortedDates = groupedTransactions.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            // Sort transactions within each date by time (newest first)
            groupedTransactions.forEach((date, transactions) {
              transactions.sort((a, b) => b.transaction.transactionDate
                  .compareTo(a.transaction.transactionDate));
            });

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

                  final formatter = NumberFormat.currency(
                      locale: 'zh_CN',
                      symbol: selectedLedger?.currencySymbol ?? '¥');
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
                                locale: 'zh_CN',
                                symbol: selectedLedger?.currencySymbol ?? '¥');
                            // Display the absolute amount, as nature handles inflow/outflow distinction
                            final formattedAmount = formatter
                                .format(transactionWithAmount.amount.abs());

                            // 格式化时间为 HH:mm 格式，如果是 00:00 则不显示
                            final timeFormatter = DateFormat('HH:mm');
                            final formattedTime = timeFormatter
                                .format(transaction.transactionDate);
                            final timeDisplay = formattedTime == '00:00'
                                ? ''
                                : ' · $formattedTime';

                            return TransactionListItem(
                              title: transaction.description ?? '无描述',
                              transactionId:
                                  transaction.transactionId.toString(),
                              subtitle:
                                  '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}$timeDisplay',
                              amount: formattedAmount,
                              fromAccountType: transactionWithAmount
                                  .fromAccount?.accountType,
                              toAccountType:
                                  transactionWithAmount.toAccount?.accountType,
                              transactionDate: transaction.transactionDate,
                              createDate: transaction.createdAt,
                              transactionAmount: transactionWithAmount.amount,
                              fullDescription: transaction.description,
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
    final selectedLedger = ref.watch(selectedLedgerProvider).value;

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
            _buildMonthlyOverviewCard(monthlyOverviewDataAsync, selectedLedger),

            // Assets Overview
            _buildAssetsOverview(
                topAssetsAsync, totalLiabilitiesAsync, selectedLedger),

            // Recent Transactions
            _buildRecentTransactions(latestTransactionsAsync, selectedLedger),
          ],
        ),
      ),
    );
  }
}
