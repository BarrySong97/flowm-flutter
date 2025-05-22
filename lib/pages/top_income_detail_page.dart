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
/// 修改为 .family 以接收 accountId (可以为 null)
final expenseChartDataProvider =
    FutureProvider.family<List<barchart.ChartData>, int?>(
        (ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  print(
      '[expenseChartDataProvider] Fetching chart data with accountId: $accountId');

  return repository.getExpenseChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId, // 传递 accountId
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

class TopIncomeDetailPage extends ConsumerWidget {
  final AccountExpenseNode account; // 接收 account 参数

  const TopIncomeDetailPage({super.key, required this.account}); // 修改构造函数
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample data for the pie chart - 这部分将被动态数据替代
    // final List<Map<String, dynamic>> expenseData = [...];
    // final double totalExpenseAmount = ...;
    // final List<StyledAccount> accountsFromExpenseData = ...;

    // 从 widget.account 获取 accountId
    final int currentAccountId = account.accountData.accountId;

    // 使用 .family 传递 accountId
    final chartDataAsync =
        ref.watch(expenseChartDataProvider(currentAccountId));

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

    // Use children of the passed account for PieChart and List
    final List<AccountExpenseNode> childrenNodes = account.children;
    final double parentAccountBalance =
        account.balance; // Parent total for new percentage calculation

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F6FB),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 22, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            account.accountData.accountName,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: Color(0xFFF5F6FB),
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
                  // 支出统计
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
                child: Builder(
                    // Using Builder to handle cases where childrenNodes might be empty
                    builder: (context) {
                  if (childrenNodes.isEmpty) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('此分类下无子分类数据'), // Updated message
                    ));
                  }

                  // 1. 转换数据给 CustomPieChart using childrenNodes
                  final List<Map<String, dynamic>> pieChartExpenseData = [];
                  for (int i = 0; i < childrenNodes.length; i++) {
                    final node = childrenNodes[i];
                    pieChartExpenseData.add({
                      'category': node.accountData.accountName,
                      'amount': node.balance,
                      'color': pieColors[i % pieColors.length],
                    });
                  }

                  // 2. 转换数据给 StyledAccountList using childrenNodes
                  // Percentages will be recalculated relative to the parent account's balance
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
                      // Use the newly calculated percentage relative to parent
                      percentageText:
                          '${percentageOfParent.toStringAsFixed(0)}%',
                    ));
                  }

                  return Column(
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
              // Add a title for the accounts section
            ],
          ),
        ))));
  }
}
