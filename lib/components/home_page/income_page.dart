import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with AutomaticKeepAliveClientMixin {
  final List<Color> _pieColors = [
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

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return NumberFormat('#,##0.00', 'zh_CN').format(amount);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final asyncData = ref.watch(incomePageDataProvider);
    final currentSelectedMonth = ref.watch(selectedMonthProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          spacing: 12,
          children: [
            _buildHeader(currentSelectedMonth, ref),
            asyncData.when(
              data: (data) => Column(
                spacing: 12,
                children: [
                  _buildStatistics(data),
                  _buildBarChart(data),
                  _buildPieChartAndAccountList(data, context),
                ],
              ),
              loading: () => const Center(
                child: SizedBox(
                  height: 660,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('加载失败: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime currentSelectedMonth, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
      child: MonthSelectorHeader(
        initialDate: currentSelectedMonth,
        onDateChanged: (newDate) {
          ref.read(selectedMonthProvider.notifier).state = newDate;
        },
      ),
    );
  }

  Widget _buildStatistics(IncomePageData data) {
    return Row(
      children: [
        _buildStatsItem('当月总收入', data.currentMonthTotal),
        const SizedBox(width: 10),
        _buildStatsItem('当月日均', data.dailyAverage),
        const SizedBox(width: 10),
        _buildChangeStatsItem(data),
      ],
    );
  }

  Widget _buildStatsItem(String title, double value) {
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
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('¥ ${_formatCurrency(value)}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeStatsItem(IncomePageData data) {
    final isPositive = data.changePercentage > 0;
    final isNegative = data.changePercentage < 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Tooltip(
          message: '上月收入: ¥ ${_formatCurrency(data.previousMonthTotal)}',
          child: Column(
            children: [
              const Text('较上月收入',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    '${data.changePercentage.toStringAsFixed(0)}%',
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
    );
  }

  Widget _buildBarChart(IncomePageData data) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: barchart.MyBarChart(
        barColor: Colors.green,
        chartData: data.currentMonthChartData,
      ),
    );
  }

  Widget _buildPieChartAndAccountList(
      IncomePageData data, BuildContext context) {
    if (data.accountTree.isEmpty) {
      return Container(
        width: double.infinity,
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

    final pieChartIncomeData = data.accountTree
        .asMap()
        .entries
        .map((entry) => {
              'category': entry.value.accountData.accountName,
              'amount': entry.value.balance,
              'color': _pieColors[entry.key % _pieColors.length],
            })
        .toList();

    final styledAccounts = data.accountTree
        .asMap()
        .entries
        .map((entry) => StyledAccount(
              name: entry.value.accountData.accountName,
              rawAmount: entry.value.balance,
              currencySymbol: '¥',
              iconData: Icons.label_outline,
              leadingColor: _pieColors[entry.key % _pieColors.length],
              percentageText: '${entry.value.percentage.toStringAsFixed(0)}%',
            ))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: CustomPieChart(expenseData: pieChartIncomeData),
          ),
          StyledAccountList(
            accounts: styledAccounts,
            onItemTap: (index) {
              final selectedNode = data.accountTree[index];
              if (selectedNode.children.isNotEmpty) {
                GoRouter.of(context).pushNamed(
                  'topIncomeDetail',
                  extra: {'account': selectedNode},
                );
              } else {
                GoRouter.of(context).pushNamed(
                  'incomeDetail',
                  extra: {'account': selectedNode},
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
