import 'package:flowm/components/account/account_item.dart' as ui;
import 'package:flowm/utils/provider_invalidator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/fl_line_chart.dart' as fl_linechart;
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/account/account_info_provider.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/components/common/transaction_list_item.dart';
import 'package:flowm/components/common/time_range_selector.dart';
import 'package:flowm/db/tables/account_table.dart';
import 'package:flowm/db/dao/transaction_dao.dart';
import 'package:flowm/utils/transaction_type_map.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:flowm/components/common/account_update_bottom_sheet.dart';

/// 当前选中的月份提供者
final expenseSelectedMonthProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());

/// 支出图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final expenseChartDataProvider = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(expenseSelectedMonthProvider);

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

/// 指定账户当月总支出提供者
final accountMonthlyExpenseProvider =
    FutureProvider.autoDispose.family<double, int>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedDate = ref.watch(expenseSelectedMonthProvider);
  final DateTime startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final DateTime endDate =
      DateTime(selectedDate.year, selectedDate.month + 1, 0);

  return repository.getAccountExpenseBalance(
    accountId: accountId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// 指定账户累计总支出提供者 (不区分时间)
final accountOverallExpenseProvider =
    FutureProvider.autoDispose.family<double, int>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getAccountExpenseTotalBalance(accountId: accountId);
});

class ExpensesDetailPage extends ConsumerStatefulWidget {
  final int accountId;

  const ExpensesDetailPage({super.key, required this.accountId});

  @override
  ConsumerState<ExpensesDetailPage> createState() =>
      _ExpensesIncomeDetailPageState();
}

class _ExpensesIncomeDetailPageState extends ConsumerState<ExpensesDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  bool _isLineChart = false; // false for bar chart, true for line chart

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset >
            (200 - kToolbarHeight); // 200 is expandedHeight
    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStatisticItem(String label, Widget valueWidget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        valueWidget,
      ],
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
    final chartDataAsync = ref
        .watch(expenseChartDataProvider(account.accountData.accountId));
    final currentSelectedMonth = ref.watch(expenseSelectedMonthProvider);
    final monthlyExpenseAsync = ref.watch(
        accountMonthlyExpenseProvider(account.accountData.accountId));
    final overallExpenseAsync = ref.watch(
        accountOverallExpenseProvider(account.accountData.accountId));
    final currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

    Widget buildValueText(double value) {
      return Text(
        currencyFormat.format(value),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    Widget buildLoadingIndicator() {
      return const SizedBox(
        height: 16, // Match text height
        width: 16, // Match text height
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    Widget buildErrorText() {
      return const Text(
        '加载失败',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent, // To show the gradient
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              // Using colors from assets_liability_detail_page for similarity
                              Color(0xFF0ba360),
                              Color(0xFF3cba92),
                            ],
                          ),
                        ),
                      ),
                      FlexibleSpaceBar(
                        background: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                const SizedBox(
                                    height: kToolbarHeight), // Adjusted padding
                                AnimatedOpacity(
                                  opacity: _isCollapsed ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    account.accountData.accountName,
                                    style: const TextStyle(
                                      fontSize: 24, // Larger when expanded
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 20,
                                  children: [
                                    monthlyExpenseAsync.when(
                                      data: (total) => _buildStatisticItem(
                                          '当月总支出', buildValueText(total)),
                                      loading: () => _buildStatisticItem(
                                          '当月总支出', buildLoadingIndicator()),
                                      error: (err, stack) =>
                                          _buildStatisticItem(
                                              '当月总支出', buildErrorText()),
                                    ),
                                    overallExpenseAsync.when(
                                      data: (total) => _buildStatisticItem(
                                          '累计总支出', buildValueText(total)),
                                      loading: () => _buildStatisticItem(
                                          '累计总支出', buildLoadingIndicator()),
                                      error: (err, stack) =>
                                          _buildStatisticItem(
                                              '累计总支出', buildErrorText()),
                                    ),
                                  ],
                                ),
                                // You can add more info here if needed, like total amount, etc.
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    size: 22, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
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
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  account.accountData.accountName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          // Container to apply background color for the body part
          color: const Color(0xFFF5F6FB), // Original Scaffold background
          child: SafeArea(
            top:
                false, // SafeArea for top is handled by SliverAppBar's background
            bottom: true, // Keep bottom SafeArea
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                    top: 16.0), // Added top padding
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
                                          '支出统计图',
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
                                              lineColor: Colors.red,
                                              chartData: chartData
                                                  .map((e) => fl_linechart.ChartData(e.x, e.y, e.day))
                                                  .toList(),
                                              daysInMonth: daysInMonth,
                                            )
                                          : fl_barchart.FlBarChart(
                                              barColor: Colors.red,
                                              chartData: chartData
                                                  .map((e) => fl_barchart.ChartData(e.x, e.y, e.day))
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
                                ],
                              ),
                            )
                          ],
                        )),

                    // 添加交易列表
                    AccountTransactionList(
                      account: account,
                      startDate: DateTime(currentSelectedMonth.year,
                          currentSelectedMonth.month, 1),
                      endDate: DateTime(currentSelectedMonth.year,
                          currentSelectedMonth.month + 1, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 账户交易列表组件
class AccountTransactionList extends ConsumerWidget {
  final AccountExpenseNode account;
  final DateTime startDate;
  final DateTime endDate;

  const AccountTransactionList({
    Key? key,
    required this.account,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(accountExpenseTransactionsProvider((
      accountId: account.accountData.accountId,
      startDate: startDate,
      endDate: endDate,
    )));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, bottom: 0),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '相关交易',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '暂无交易记录',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '该时间段内没有相关交易',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }

              // 按日期分组交易
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
                  groupedTransactions[transactionDate] = [
                    transactionWithAmount
                  ];
                }
              }

              // 按日期降序排列
              final sortedDates = groupedTransactions.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: sortedDates.length,
                itemBuilder: (context, dateIndex) {
                  final date = sortedDates[dateIndex];
                  final transactionsOnDate = groupedTransactions[date]!;
                  final formattedDate =
                      DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(date);

                  // 计算当日收支总额
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 12, bottom: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding: EdgeInsets.zero,
                        itemCount: transactionsOnDate.length,
                        itemBuilder: (context, transactionIndex) {
                          final transactionWithAmount =
                              transactionsOnDate[transactionIndex];
                          final transaction = transactionWithAmount.transaction;

                          // 判断是否为支出
                          final bool isExpense = transactionWithAmount.nature ==
                              TransactionNature.OUTFLOW;

                          final formatter = NumberFormat.currency(
                              locale: 'zh_CN', symbol: '¥');
                          final formattedAmount = formatter
                              .format(transactionWithAmount.amount.abs());

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            child: TransactionListItem(
                                title: transaction.description ?? '无描述',
                                transactionId:
                                    transaction.transactionId.toString(),
                                subtitle:
                                    '${transactionWithAmount.fromAccount?.accountName} -> ${transactionWithAmount.toAccount?.accountName}',
                                amount: formattedAmount,
                                fromAccountType: transactionWithAmount
                                    .fromAccount?.accountType,
                                toAccountType: transactionWithAmount
                                    .toAccount?.accountType,
                                type: getTransactionFlowType(
                                  transactionWithAmount
                                          .fromAccount?.accountType ??
                                      AccountType.ASSET,
                                  transactionWithAmount
                                          .toAccount?.accountType ??
                                      AccountType.ASSET,
                                ),
                                statusColor: isExpense
                                    ? const Color(0xFF007AFF) // 蓝色表示支出
                                    : const Color(0xFF34C759), // 绿色表示收入
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
                                            fromAccountType:
                                                transactionWithAmount
                                                        .fromAccount
                                                        ?.accountType ??
                                                    AccountType.ASSET,
                                            toAccountType: transactionWithAmount
                                                    .toAccount?.accountType ??
                                                AccountType.ASSET,
                                          )
                                        }
                                    }),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey.shade400,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '加载失败',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$error',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
