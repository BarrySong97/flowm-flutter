import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with AutomaticKeepAliveClientMixin {
  // 辅助方法格式化数字
  String _formatCurrency(double amount) {
    if (amount.abs() >= 100000) {
      // Use abs() for negative numbers too
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return NumberFormat('#,##0.00', 'zh_CN').format(amount);
    }
  }

  // 构建统计项的通用方法
  Widget _buildStatsItem(
    String title,
    String value, {
    Widget? trailing,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (trailing != null) trailing,
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(IncomePageData data) {
    final selectedMonth = ref.watch(selectedMonthProvider);

    // Current month total
    double currentTotal = data.chartData.fold(0.0, (sum, item) => sum + item.y);

    // Daily average
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyAverage = daysInMonth > 0 ? currentTotal / daysInMonth : 0.0;

    // Change vs previous month
    double previousTotal =
        data.previousMonthChartData.fold(0.0, (sum, item) => sum + item.y);
    double changePercent = 0;
    if (previousTotal.abs() > 0.001) {
      changePercent =
          ((currentTotal - previousTotal) / previousTotal.abs()) * 100;
    } else if (currentTotal.abs() > 0.001) {
      changePercent = currentTotal > 0 ? 100.0 : -100.0;
    }
    final isPositive = changePercent > 0.001;
    final isNegative = changePercent < -0.001;

    return Row(
      children: [
        _buildStatsItem(
          '当月总收入',
          '¥ ${_formatCurrency(currentTotal)}',
        ),
        const SizedBox(width: 10),
        _buildStatsItem(
          '当月日均',
          '¥ ${_formatCurrency(dailyAverage)}',
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tooltip(
            message: '上月收入: ¥ ${_formatCurrency(previousTotal)}',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  const Text(
                    '较上月收入',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPositive)
                        const Icon(Icons.arrow_upward,
                            color: Colors.green, size: 16),
                      if (isNegative)
                        const Icon(Icons.arrow_downward,
                            color: Colors.red, size: 16),
                      if (!isPositive && !isNegative) const SizedBox(width: 16),
                      Text(
                        '${changePercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? Colors.green
                              : (isNegative ? Colors.red : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<barchart.ChartData> chartData) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: barchart.MyBarChart(
        barColor: Colors.green,
        chartData: chartData,
      ),
    );
  }

  Widget _buildPieChartAndList(List<AccountExpenseNode> accountTreeNodes) {
    if (accountTreeNodes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('当月无收入分类数据'),
          ),
        ),
      );
    }

    final List<Color> pieColors = [
      Colors.green.shade800,
      Colors.blue,
      Colors.orange,
      Colors.pink,
      Colors.green.shade300,
      Colors.blue.shade300,
      Colors.purple,
      Colors.purple.shade300,
      Colors.amber,
      Colors.indigo,
      Colors.deepOrange,
      Colors.brown,
      Colors.green.shade400
    ];

    final List<Map<String, dynamic>> pieChartExpenseData = [];
    final List<StyledAccount> styledAccounts = [];

    for (int i = 0; i < accountTreeNodes.length; i++) {
      final node = accountTreeNodes[i];
      final color = pieColors[i % pieColors.length];
      pieChartExpenseData.add({
        'category': node.accountData.accountName,
        'amount': node.balance,
        'color': color,
      });
      styledAccounts.add(StyledAccount(
        name: node.accountData.accountName,
        rawAmount: node.balance,
        currencySymbol: '¥',
        iconData: Icons.label_outline,
        leadingColor: color,
        percentageText: '${node.percentage.toStringAsFixed(0)}%',
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: CustomPieChart(expenseData: pieChartExpenseData),
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
                final routeName = selectedNode.children.isNotEmpty
                    ? 'topIncomesDetail'
                    : 'incomeDetail';
                GoRouter.of(context).pushNamed(
                  routeName,
                  extra: {'account': selectedNode},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentSelectedMonth = ref.watch(selectedMonthProvider);
    final pageDataAsync = ref.watch(incomePageDataProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          spacing: 12,
          children: [
            Column(
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
                pageDataAsync.when(
                  data: (data) => Column(
                    spacing: 12,
                    children: [
                      _buildStatsRow(data),
                      _buildBarChart(data.chartData),
                    ],
                  ),
                  loading: () => Column(
                    children: [
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  ),
                  error: (error, stack) => Center(
                    child: Text('加载图表失败: $error'),
                  ),
                ),
              ],
            ),
            pageDataAsync.when(
              data: (data) => _buildPieChartAndList(data.accountTree),
              loading: () => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 660,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (error, stack) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('加载收入分类失败: $error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
