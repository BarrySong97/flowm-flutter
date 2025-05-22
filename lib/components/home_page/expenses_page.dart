import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';

/// 当前选中的月份提供者
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 支出图表数据提供者
final expenseChartDataProvider =
    FutureProvider<List<barchart.ChartData>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 根据选择的月份计算开始和结束时间
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate = DateTime(
      selectedDate.year, selectedDate.month + 1, 0); // Last day of the month

  return repository.getExpenseChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

/// 支出账户树数据提供者
final expenseAccountTreeDataProvider =
    FutureProvider<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getExpenseAccountTree(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample data for the pie chart - 这部分将被动态数据替代
    // final List<Map<String, dynamic>> expenseData = [...];
    // final double totalExpenseAmount = ...;
    // final List<StyledAccount> accountsFromExpenseData = ...;

    final chartDataAsync = ref.watch(expenseChartDataProvider); // 用于条形图
    final accountTreeDataAsync =
        ref.watch(expenseAccountTreeDataProvider); // 用于饼图和列表
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
              // 支出统计
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
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: chartDataAsync.when(
                      data: (chartData) => barchart.MyBarChart(
                        barColor: Colors.red,
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
                    child: Text('当月无支出分类数据'),
                  ));
                }

                // 1. 转换数据给 CustomPieChart
                final List<Map<String, dynamic>> pieChartExpenseData = [];
                for (int i = 0; i < accountTreeNodes.length; i++) {
                  final node = accountTreeNodes[i];
                  pieChartExpenseData.add({
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
                          if (selectedNode.children.isNotEmpty) {
                            GoRouter.of(context).pushNamed(
                              'topExpensesDetail',
                              extra: {'account': selectedNode},
                            );
                          } else {
                            final selectedNode = accountTreeNodes[index];
                            GoRouter.of(context).pushNamed(
                              'expensesDetail',
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
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )),
              error: (error, stack) => Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('加载支出分类失败: $error'),
              )),
            ),
          ),
          // Add a title for the accounts section
        ],
      ),
    ));
  }
}
