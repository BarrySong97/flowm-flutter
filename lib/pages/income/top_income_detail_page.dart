import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 上个月收入数据提供者 (family)
final previousMonthIncomeProviderFamily =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 计算上个月的开始和结束时间
  final DateTime prevMonthStartDate =
      DateTime(selectedDate.year, selectedDate.month - 1, 1);
  final DateTime prevMonthEndDate =
      DateTime(selectedDate.year, selectedDate.month, 0);

  return repository.getIncomeChartData(
    startDate: prevMonthStartDate,
    endDate: prevMonthEndDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 收入图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final incomeChartDataProviderFamily =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  print(
      '[incomeChartDataProviderFamily] Fetching chart data with accountId: $accountId');

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 收入账户树数据提供者 - This might not be directly used for the stats but kept for consistency if page structure is similar
final incomeAccountTreeDataProvider =
    FutureProvider<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getIncomeAccountTree(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

class TopIncomeDetailPage extends ConsumerWidget {
  final AccountExpenseNode account;

  const TopIncomeDetailPage({super.key, required this.account});

  // 辅助方法格式化数字
  String _formatCurrency(double amount) {
    if (amount.abs() >= 100000) {
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return NumberFormat('#,##0.00', 'zh_CN').format(amount);
    }
  }

  // 构建统计项的通用方法
  Widget _buildStatsItem(
      WidgetRef ref,
      String title,
      AsyncValue<List<barchart.ChartData>> asyncData,
      double Function(List<barchart.ChartData> data, DateTime selectedMonth)
          calculateValue) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: asyncData.when(
          data: (data) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final value = calculateValue(data, selectedMonth);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '¥ ${_formatCurrency(value)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, stack) => const Text('加载失败'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentAccountId = account.accountData.accountId;

    final chartDataAsync =
        ref.watch(incomeChartDataProviderFamily(currentAccountId));
    final previousMonthDataAsync =
        ref.watch(previousMonthIncomeProviderFamily(currentAccountId));

    final currentSelectedMonth = ref.watch(selectedMonthProvider);

    final List<Color> pieColors = [
      Colors.green.shade800,
      Colors.teal,
      Colors.blue,
      Colors.lightGreen,
      Colors.cyan,
      Colors.cyan.shade300,
      Colors.indigo,
      Colors.indigo.shade300,
      Colors.lime,
      Colors.blueGrey,
      Colors.lightBlue,
      Colors.brown,
      Colors.green.shade400
    ];

    final List<AccountExpenseNode> childrenNodes = account.children;
    final double parentAccountBalance = account.balance;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F6FB),
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, size: 22, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            account.accountData.accountName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFFF5F6FB),
        body: SafeArea(
            child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: Column(
            spacing: 12,
            children: [
              Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      MonthSelectorHeader(
                        initialDate: currentSelectedMonth,
                        onDateChanged: (newDate) {
                          ref.read(selectedMonthProvider.notifier).state =
                              newDate;
                        },
                      ),
                      const SizedBox(
                        height: 12,
                        child: ColoredBox(color: Colors.transparent),
                      ),
                      Row(
                        children: [
                          _buildStatsItem(
                            ref,
                            '当月总收入',
                            chartDataAsync,
                            (data, selectedMonth) {
                              double total = 0;
                              for (var item in data) {
                                total += item.y;
                              }
                              return total;
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildStatsItem(
                            ref,
                            '当月日均',
                            chartDataAsync,
                            (data, selectedMonth) {
                              double total = 0;
                              for (var item in data) {
                                total += item.y;
                              }
                              final daysInMonth = DateTime(
                                selectedMonth.year,
                                selectedMonth.month + 1,
                                0,
                              ).day;
                              return daysInMonth > 0 ? total / daysInMonth : 0;
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: chartDataAsync.when(
                                data: (currentData) {
                                  return previousMonthDataAsync.when(
                                    data: (previousData) {
                                      double currentTotal = 0;
                                      for (var item in currentData) {
                                        currentTotal += item.y;
                                      }

                                      double previousTotal = 0;
                                      for (var item in previousData) {
                                        previousTotal += item.y;
                                      }

                                      double changePercent = 0;
                                      if (previousTotal.abs() > 0.001) {
                                        changePercent =
                                            ((currentTotal - previousTotal) /
                                                    previousTotal.abs()) *
                                                100;
                                      } else if (currentTotal.abs() > 0.001) {
                                        changePercent =
                                            currentTotal > 0 ? 100.0 : -100.0;
                                      }

                                      final isPositive = changePercent > 0.001;
                                      final isNegative = changePercent < -0.001;

                                      return Tooltip(
                                        message:
                                            '上月收入: ¥ ${_formatCurrency(previousTotal)}',
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              '较上月收入',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (isPositive)
                                                  Icon(Icons.arrow_upward,
                                                      color: Colors.green,
                                                      size: 16),
                                                if (isNegative)
                                                  Icon(Icons.arrow_downward,
                                                      color: Colors.red,
                                                      size: 16),
                                                if (!isPositive && !isNegative)
                                                  const SizedBox(width: 16),
                                                Text(
                                                  '${changePercent.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPositive
                                                        ? Colors.green
                                                        : (isNegative
                                                            ? Colors.red
                                                            : Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    loading: () => const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                    error: (error, stack) => const Text('加载失败'),
                                  );
                                },
                                loading: () => const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                error: (error, stack) => const Text('加载失败'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                        child: ColoredBox(color: Colors.transparent),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: chartDataAsync.when(
                          data: (chartData) {
                            final daysInMonth = DateTime(
                                    currentSelectedMonth.year,
                                    currentSelectedMonth.month + 1,
                                    0)
                                .day;
                            return fl_barchart.FlBarChart(
                              barColor: Colors.green,
                              chartData: chartData
                                  .map((e) =>
                                      fl_barchart.ChartData(e.x, e.y, e.day))
                                  .toList(),
                              daysInMonth: daysInMonth,
                            );
                          },
                          loading: () => const Center(
                            child: SizedBox(
                              height: 240,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          error: (error, stack) => Center(
                            child: Text('加载失败: $error'),
                          ),
                        ),
                      )
                    ],
                  )),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Builder(builder: (context) {
                  if (childrenNodes.isEmpty) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('此分类下无子分类数据'),
                    ));
                  }

                  final List<Map<String, dynamic>> pieChartIncomeData = [];
                  for (int i = 0; i < childrenNodes.length; i++) {
                    final node = childrenNodes[i];
                    pieChartIncomeData.add({
                      'category': node.accountData.accountName,
                      'amount': node.balance,
                      'color': pieColors[i % pieColors.length],
                    });
                  }

                  final List<StyledAccount> styledAccounts = [];
                  for (int i = 0; i < childrenNodes.length; i++) {
                    final node = childrenNodes[i];
                    final double percentageOfParent = parentAccountBalance > 0
                        ? (node.balance / parentAccountBalance) * 100
                        : 0.0;
                    styledAccounts.add(StyledAccount(
                      name: node.accountData.accountName,
                      rawAmount: node.balance,
                      currencySymbol: '¥',
                      iconData: Icons.label_outline,
                      leadingColor: pieColors[i % pieColors.length],
                      percentageText:
                          '${percentageOfParent.toStringAsFixed(0)}%',
                    ));
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: 260,
                        child: CustomPieChart(expenseData: pieChartIncomeData),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: StyledAccountList(
                          accounts: styledAccounts,
                          onItemTap: (index) {
                            final selectedNode = childrenNodes[index];
                            GoRouter.of(context).pushNamed(
                              'incomeDetail',
                              extra: {'account': selectedNode},
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ))));
  }
}
