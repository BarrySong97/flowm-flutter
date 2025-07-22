import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/fl_line_chart.dart' as fl_linechart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/account/account_info_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flowm/components/common/account_update_bottom_sheet.dart';
import 'package:flowm/components/account/account_item.dart' as ui;

/// 当前选中的月份提供者
final incomeSelectedMonthProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

/// 上个月收入数据提供者 (family)
final previousMonthIncomeProviderFamily = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(incomeSelectedMonthProvider);

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
final incomeChartDataProviderFamily = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(incomeSelectedMonthProvider);

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
    FutureProvider.autoDispose<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(incomeSelectedMonthProvider);

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

class TopIncomeDetailPage extends ConsumerStatefulWidget {
  final int accountId;

  const TopIncomeDetailPage({super.key, required this.accountId});
  
  @override
  ConsumerState<TopIncomeDetailPage> createState() => _TopIncomeDetailPageState();
}

class _TopIncomeDetailPageState extends ConsumerState<TopIncomeDetailPage> {
  bool _isLineChart = false; // false for bar chart, true for line chart

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
            final selectedMonth = ref.watch(incomeSelectedMonthProvider);
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
  Widget build(BuildContext context) {
    // 动态获取账户信息
    final accountAsync = ref.watch(accountExpenseNodeProvider(widget.accountId));
    
    return accountAsync.when(
      data: (account) => _buildDetailPage(context, ref, account),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildDetailPage(BuildContext context, WidgetRef ref, AccountExpenseNode account) {
    final int currentAccountId = account.accountData.accountId;

    final chartDataAsync =
        ref.watch(incomeChartDataProviderFamily(currentAccountId));
    final previousMonthDataAsync =
        ref.watch(previousMonthIncomeProviderFamily(currentAccountId));
    // 添加对 incomeAccountTreeDataProvider 的 watch
    final accountTreeAsync = ref.watch(incomeAccountTreeDataProvider);

    final currentSelectedMonth = ref.watch(incomeSelectedMonthProvider);

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
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () async {
                // Convert database Account to UI Account
                final uiAccount = ui.Account(
                  id: account.accountData.accountId,
                  name: account.accountData.accountName,
                  amount: account.balance,
                  type: account.accountData.accountType,
                  currencySymbol: '¥',
                );
                
                await AccountUpdateBottomSheet.show(
                  context,
                  accountToUpdate: uiAccount,
                );
              },
            ),
          ],
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
                          ref.read(incomeSelectedMonthProvider.notifier).state =
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
                        child: Column(
                          children: [
                            // Chart title and switch button
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '收入统计图',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLineChart = !_isLineChart;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isLineChart ? Icons.show_chart : Icons.bar_chart,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isLineChart ? '折线图' : '柱状图',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Chart content
                            chartDataAsync.when(
                              data: (chartData) {
                                final daysInMonth = DateTime(
                                        currentSelectedMonth.year,
                                        currentSelectedMonth.month + 1,
                                        0)
                                    .day;
                                return _isLineChart
                                    ? fl_linechart.FlLineChart(
                                        lineColor: Colors.green,
                                        chartData: chartData
                                            .map((e) => fl_linechart.ChartData(e.x, e.y, e.day))
                                            .toList(),
                                        daysInMonth: daysInMonth,
                                      )
                                    : fl_barchart.FlBarChart(
                                        barColor: Colors.green,
                                        chartData: chartData
                                            .map((e) => fl_barchart.ChartData(e.x, e.y, e.day))
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
                          ],
                        ),
                      )
                    ],
                  )),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: accountTreeAsync.when(
                  data: (accountTreeNodes) {
                    // 过滤出当前账户的子账户

                    final List<AccountExpenseNode> childrenNodes =
                        accountTreeNodes
                            .where((node) => node.children.any((childnode) =>
                                childnode.accountData.parentAccountId ==
                                currentAccountId))
                            .toList()
                            .map((v) => v.children)
                            .expand((v) => v)
                            .toList();
                    if (childrenNodes.isEmpty) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('此分类下无子分类数据'),
                      ));
                    }

                    // 计算父账户总金额（所有子账户余额之和）
                    final double parentAccountBalance = childrenNodes.fold(
                        0.0, (sum, node) => sum + node.balance);

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
                          child:
                              CustomPieChart(expenseData: pieChartIncomeData),
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
                                extra: {'accountId': selectedNode.accountData.accountId},
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('加载失败: $error'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ))));
  }
}
