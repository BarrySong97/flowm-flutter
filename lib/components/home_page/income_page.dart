import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 上个月收入数据提供者
final previousMonthIncomeProvider =
    FutureProvider<List<barchart.ChartData>>((ref) async {
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
  );
});

/// 收入图表数据提供者
final incomeChartDataProvider =
    FutureProvider<List<barchart.ChartData>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 根据选择的月份计算开始和结束时间
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate = DateTime(
      selectedDate.year, selectedDate.month + 1, 0); // Last day of the month

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

/// 收入账户树数据提供者
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

class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with AutomaticKeepAliveClientMixin {
  // 辅助方法格式化数字
  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return NumberFormat('#,##0.00', 'zh_CN').format(amount);
    }
  }

  // 构建统计项的通用方法
  Widget _buildStatsItem(
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
              height: 54,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, stack) => const Text('加载失败'),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Sample data for the pie chart - 这部分将被动态数据替代
    // final List<Map<String, dynamic>> incomeData = [...];
    // final double totalIncomeAmount = ...;
    // final List<StyledAccount> accountsFromIncomeData = ...;

    final chartDataAsync = ref.watch(incomeChartDataProvider); // 用于条形图
    final previousMonthDataAsync =
        ref.watch(previousMonthIncomeProvider); // 上个月数据
    final accountTreeDataAsync =
        ref.watch(incomeAccountTreeDataProvider); // 用于饼图和列表
    final currentSelectedMonth = ref.watch(selectedMonthProvider);

    // 定义一组颜色供饼图使用
    final List<Color> pieColors = [
      Colors.red.shade800,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.blue,
      Colors.blue.shade300,
      Colors.purple,
      Colors.purple.shade300,
      Colors.amber,
      Colors.indigo,
      Colors.deepOrange,
      Colors.brown,
      Colors.red.shade400
    ];

    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        spacing: 12,
        children: [
          Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              // 收入统计
              child: Column(
                children: [
                  MonthSelectorHeader(
                    initialDate: currentSelectedMonth,
                    onDateChanged: (newDate) {
                      ref.read(selectedMonthProvider.notifier).state = newDate;
                    },
                  ),
                  const SizedBox(
                    height: 12,
                    child: ColoredBox(color: Colors.transparent),
                  ),
                  // 添加三个数据统计
                  Row(
                    children: [
                      // 当月总收入
                      _buildStatsItem(
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
                      // 当月日均收入
                      _buildStatsItem(
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
                      // 较上月变化
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                  if (previousTotal != 0) {
                                    changePercent =
                                        ((currentTotal - previousTotal) /
                                                previousTotal.abs()) *
                                            100;
                                  } else if (currentTotal > 0) {
                                    changePercent = 100.0;
                                  } else {
                                    changePercent = 0.0;
                                  }

                                  final isPositive = changePercent > 0;
                                  final isNegative = changePercent < 0;

                                  return Tooltip(
                                    message:
                                        '上月收入: ¥ ${_formatCurrency(previousTotal)}',
                                    child: Column(
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
                                                  color: Colors.red, size: 16),
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
                                    height: 54,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                error: (error, stack) => const Text('加载失败'),
                              );
                            },
                            loading: () => const Center(
                              child: SizedBox(
                                height: 54,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: chartDataAsync.when(
                      data: (chartData) => barchart.MyBarChart(
                        barColor: Colors.green,
                        chartData: chartData,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('加载失败: $error'),
                      ),
                    ),
                  )
                ],
              )),

          Container(
            // height: 320, // 高度由内容决定
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: accountTreeDataAsync.when(
              data: (accountTreeNodes) {
                if (accountTreeNodes.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('当月无收入分类数据'),
                  ));
                }

                // 1. 转换数据给 CustomPieChart
                final List<Map<String, dynamic>> pieChartIncomeData = [];
                for (int i = 0; i < accountTreeNodes.length; i++) {
                  final node = accountTreeNodes[i];
                  pieChartIncomeData.add({
                    'category': node.accountData.accountName,
                    'amount': node.balance,
                    'color': pieColors[i % pieColors.length], // 循环使用颜色
                  });
                }

                // 2. 转换数据给 StyledAccountList
                final List<StyledAccount> styledAccounts = [];
                for (int i = 0; i < accountTreeNodes.length; i++) {
                  final node = accountTreeNodes[i];
                  styledAccounts.add(StyledAccount(
                    name: node.accountData.accountName,
                    rawAmount: node.balance,
                    currencySymbol: '¥', // 或者从其他地方获取货币符号
                    iconData: Icons.label_outline, // 可根据账户类型自定义
                    leadingColor: pieColors[i % pieColors.length],
                    percentageText: '${node.percentage.toStringAsFixed(0)}%',
                  ));
                }

                return Column(
                  children: [
                    Container(
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
                          final selectedNode = accountTreeNodes[index];
                          if (selectedNode.children.isNotEmpty) {
                            GoRouter.of(context).pushNamed(
                              'topIncomeDetail',
                              extra: {'account': selectedNode},
                            );
                          } else {
                            final selectedNode = accountTreeNodes[index];
                            GoRouter.of(context).pushNamed(
                              'incomeDetail',
                              extra: {'account': selectedNode},
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: SizedBox(
                height: 660,
                child: CircularProgressIndicator(strokeWidth: 2),
              )),
              error: (error, stack) => Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('加载收入分类失败: $error'),
              )),
            ),
          ),
          // Add a title for the accounts section
        ],
      ),
    ));
  }
}
