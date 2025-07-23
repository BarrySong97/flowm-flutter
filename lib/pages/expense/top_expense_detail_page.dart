import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/state/account/account_info_provider.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Added for formatting
import 'package:flowm/components/common/account_update_bottom_sheet.dart';
import 'package:flowm/components/account/account_item.dart' as ui;

/// 当前选中的月份提供者
final expenseSelectedMonthProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

/// 上个月支出数据提供者 (family)
final previousMonthExpenseProviderFamily = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(expenseSelectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  // 计算上个月的开始和结束时间
  final DateTime prevMonthStartDate =
      DateTime(selectedDate.year, selectedDate.month - 1, 1);
  final DateTime prevMonthEndDate =
      DateTime(selectedDate.year, selectedDate.month, 0);

  return repository.getExpenseChartData(
    startDate: prevMonthStartDate,
    endDate: prevMonthEndDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId, // 传递 accountId
  );
});

/// 支出图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final expenseChartDataProvider = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(expenseSelectedMonthProvider);
  print(selectedDate);
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
    FutureProvider.autoDispose<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(expenseSelectedMonthProvider);

  if (selectedLedger == null) {
    return [];
  }

  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);
  print('startDate: $startDate');
  print('endDate: $endDate');
  return repository.getExpenseAccountTree(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
  );
});

class TopExpensesDetailPage extends ConsumerStatefulWidget {
  final int accountId; // 接收 accountId 参数

  const TopExpensesDetailPage({super.key, required this.accountId}); // 修改构造函数

  @override
  ConsumerState<TopExpensesDetailPage> createState() => _TopExpensesDetailPageState();
}

class _TopExpensesDetailPageState extends ConsumerState<TopExpensesDetailPage> {
  bool _isAscending = true; // 默认升序排列

  // 辅助方法格式化数字 (Copied from ExpensesPage)
  String _formatCurrency(double amount) {
    if (amount.abs() >= 1000000) {
      // 6位数及以上才格式化
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return NumberFormat('#,##0.00', 'zh_CN').format(amount);
    }
  }

  // 构建统计项的通用方法 (Copied and adapted from ExpensesPage)
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
            final selectedMonth = ref.watch(expenseSelectedMonthProvider);
            final value = calculateValue(data, selectedMonth);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center content
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
              width: 24, // Specify size for CircularProgressIndicator
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
      data: (account) => _buildDetailPage(context, account),
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

  Widget _buildDetailPage(BuildContext context, AccountExpenseNode account) {
    // Sample data for the pie chart - 这部分将被动态数据替代
    // final List<Map<String, dynamic>> expenseData = [...];
    // final double totalExpenseAmount = ...;
    // final List<StyledAccount> accountsFromExpenseData = ...;

    // 从 account 获取 accountId
    final int currentAccountId = account.accountData.accountId;

    // 使用 .family 传递 accountId
    final chartDataAsync =
        ref.watch(expenseChartDataProvider(currentAccountId));
    // Watch the new provider for previous month's data
    final previousMonthDataAsync =
        ref.watch(previousMonthExpenseProviderFamily(currentAccountId));
    // 添加对 expenseAccountTreeDataProvider 的 watch
    final accountTreeAsync = ref.watch(expenseAccountTreeDataProvider);

    final currentSelectedMonth = ref.watch(expenseSelectedMonthProvider);

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
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.black),
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
                          ref.read(expenseSelectedMonthProvider.notifier).state =
                              newDate;
                        },
                      ),
                      const SizedBox(
                        height: 12,
                        child: ColoredBox(color: Colors.transparent),
                      ),
                      // START: Added Statistics Row (Copied and adapted from ExpensesPage)
                      Row(
                        children: [
                          // 当月总支出
                          _buildStatsItem(
                            ref,
                            '当月总支出',
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
                          // 当月日均支出
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
                          // 较上月支出
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
                                            '上月支出: ¥ ${_formatCurrency(previousTotal)}',
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center, // Center content
                                          children: [
                                            const Text(
                                              '较上月支出',
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
                                                      color: Colors.red,
                                                      size: 16),
                                                if (isNegative)
                                                  Icon(Icons.arrow_downward,
                                                      color: Colors.green,
                                                      size: 16),
                                                if (!isPositive && !isNegative)
                                                  const SizedBox(width: 16),
                                                Text(
                                                  '${changePercent.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPositive
                                                        ? Colors.red
                                                        : (isNegative
                                                            ? Colors.green
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
                                        width:
                                            24, // Specify size for CircularProgressIndicator
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
                                    width:
                                        24, // Specify size for CircularProgressIndicator
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
                              barColor: Colors.red,
                              chartData: chartData
                                  .map((e) =>
                                      fl_barchart.ChartData(e.x, e.y, e.day))
                                  .toList(),
                              daysInMonth: daysInMonth,
                            );
                          },
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

                    // 先为原始数据分配颜色，保持颜色映射关系
                    final Map<String, Color> accountColorMap = {};
                    final List<Map<String, dynamic>> pieChartExpenseData = [];
                    
                    for (int i = 0; i < childrenNodes.length; i++) {
                      final node = childrenNodes[i];
                      final color = pieColors[i % pieColors.length];
                      accountColorMap[node.accountData.accountName] = color;
                      pieChartExpenseData.add({
                        'category': node.accountData.accountName,
                        'amount': node.balance,
                        'color': color,
                      });
                    }

                    // 根据排序状态对childrenNodes进行排序，但保持原有颜色
                    final sortedNodes = List<AccountExpenseNode>.from(childrenNodes);
                    sortedNodes.sort((a, b) {
                      if (_isAscending) {
                        return a.balance.compareTo(b.balance);
                      } else {
                        return b.balance.compareTo(a.balance);
                      }
                    });

                    // 2. 转换数据给 StyledAccountList
                    final List<StyledAccount> styledAccounts = [];
                    for (final node in sortedNodes) {
                      final color = accountColorMap[node.accountData.accountName]!;
                      final double percentageOfParent = parentAccountBalance > 0
                          ? (node.balance / parentAccountBalance) * 100
                          : 0.0;
                      styledAccounts.add(StyledAccount(
                        name: node.accountData.accountName,
                        rawAmount: node.balance,
                        currencySymbol: '¥',
                        iconData: Icons.label_outline,
                        leadingColor: color,
                        percentageText:
                            '${percentageOfParent.toStringAsFixed(0)}%',
                      ));
                    }

                    return Column(
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 260,
                              child:
                                  CustomPieChart(expenseData: pieChartExpenseData),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAscending = !_isAscending;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _isAscending ? '升序' : '降序',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: StyledAccountList(
                            accounts: styledAccounts,
                            onItemTap: (index) {
                              final selectedNode = sortedNodes[index];
                              GoRouter.of(context).pushNamed(
                                'expensesDetail',
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
              // Add a title for the accounts section

              // END: Added Statistics Row
              const SizedBox(
                height: 12,
                child: ColoredBox(color: Colors.transparent),
              ),
            ],
          ),
        ))));
  }
}
