import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/fl_line_chart.dart' as fl_linechart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/expense/expense_repository.dart';
import 'package:flowm/state/expense/expense_providers.dart';
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/db/app_database.dart';
import 'package:flowm/state/account/account_info_provider.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/components/chart/fullscreen_chart_page.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Added for formatting
import 'package:flowm/components/common/account_update_bottom_sheet.dart';
import 'package:flowm/components/account/account_item.dart' as ui;

/// 上期支出数据提供者 (family)
final previousPeriodExpenseProviderFamily = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    return [];
  }

  DateTime startDate, endDate;

  switch (timeRangeType) {
    case '90days':
      endDate = DateTime.now().subtract(const Duration(days: 90));
      startDate = endDate.subtract(const Duration(days: 90));
      break;
    case '60days':
      endDate = DateTime.now().subtract(const Duration(days: 60));
      startDate = endDate.subtract(const Duration(days: 60));
      break;
    case 'year':
      final prevYear = selectedDate.year - 1;
      startDate = DateTime(prevYear, 1, 1);
      endDate = DateTime(prevYear, 12, 31);
      break;
    case 'all':
      return []; // No previous period for 'all'
    case 'month':
    default:
      startDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      endDate = DateTime(selectedDate.year, selectedDate.month, 0);
      break;
  }

  return repository.getExpenseChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 支出图表数据提供者
/// 修改为 .family 以接收 accountId (可以为 null)
final expenseChartDataProvider = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    return [];
  }

  DateTime startDate, endDate;

  switch (timeRangeType) {
    case '90days':
      startDate = DateTime.now().subtract(const Duration(days: 90));
      endDate = DateTime.now();
      break;
    case '60days':
      startDate = DateTime.now().subtract(const Duration(days: 60));
      endDate = DateTime.now();
      break;
    case 'year':
      startDate = DateTime(selectedDate.year, 1, 1);
      endDate = DateTime(selectedDate.year, 12, 31);
      break;
    case 'all':
      startDate = DateTime(2020, 1, 1);
      endDate = DateTime.now();
      break;
    case 'month':
    default:
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      break;
  }

  return repository.getExpenseChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 支出账户树数据提供者
final expenseAccountTreeDataProvider =
    FutureProvider.autoDispose<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

  if (selectedLedger == null) {
    return [];
  }

  DateTime startDate, endDate;

  switch (timeRangeType) {
    case '90days':
      startDate = DateTime.now().subtract(const Duration(days: 90));
      endDate = DateTime.now();
      break;
    case '60days':
      startDate = DateTime.now().subtract(const Duration(days: 60));
      endDate = DateTime.now();
      break;
    case 'year':
      startDate = DateTime(selectedDate.year, 1, 1);
      endDate = DateTime(selectedDate.year, 12, 31);
      break;
    case 'all':
      startDate = DateTime(2020, 1, 1);
      endDate = DateTime.now();
      break;
    case 'month':
    default:
      startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      break;
  }

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
  ConsumerState<TopExpensesDetailPage> createState() =>
      _TopExpensesDetailPageState();
}

class _TopExpensesDetailPageState extends ConsumerState<TopExpensesDetailPage> {
  bool _isAscending = false; // 默认升序排列
  bool _isLineChart = false; // false for bar chart, true for line chart

  DateTime? _getStartDateForChart() {
    final selectedMonth = ref.read(selectedMonthProvider);
    final timeRangeType = ref.read(selectedTimeRangeTypeProvider);

    switch (timeRangeType) {
      case '90days':
        return DateTime.now().subtract(const Duration(days: 90));
      case '60days':
        return DateTime.now().subtract(const Duration(days: 60));
      case 'year':
        return DateTime(selectedMonth.year, 1, 1);
      case 'all':
        return DateTime(2020, 1, 1);
      case 'month':
      default:
        return DateTime(selectedMonth.year, selectedMonth.month, 1);
    }
  }

  DateTime? _getEndDateForChart() {
    final selectedMonth = ref.read(selectedMonthProvider);
    final timeRangeType = ref.read(selectedTimeRangeTypeProvider);

    switch (timeRangeType) {
      case '90days':
      case '60days':
      case 'year':
      case 'all':
        return DateTime.now();
      case 'month':
      default:
        return DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    }
  }

  String _getCurrentTimeRangeTitle() {
    final timeRangeType = ref.read(selectedTimeRangeTypeProvider);
    switch (timeRangeType) {
      case '90days':
        return '最近90天';
      case '60days':
        return '最近60天';
      case 'year':
        return '全年';
      case 'all':
        return '全部';
      case 'month':
      default:
        return '当月';
    }
  }

  int _getCurrentDaysInPeriod() {
    final selectedMonth = ref.read(selectedMonthProvider);
    final timeRangeType = ref.read(selectedTimeRangeTypeProvider);

    switch (timeRangeType) {
      case '90days':
        return 90;
      case '60days':
        return 60;
      case 'year':
        final year = selectedMonth.year;
        final yearStart = DateTime(year, 1, 1);
        final yearEnd = DateTime(year, 12, 31);
        return yearEnd.difference(yearStart).inDays + 1;
      case 'all':
        final startDate = DateTime(2020, 1, 1);
        final endDate = DateTime.now();
        return endDate.difference(startDate).inDays + 1;
      case 'month':
      default:
        return DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    }
  }

  // 辅助方法格式化数字 (Copied from ExpensesPage)
  String _formatCurrency(double amount) {
    if (amount.abs() >= 1000000) {
      // 6位数及以上才格式化
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
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildStatsRow(List<barchart.ChartData> currentData,
      List<barchart.ChartData> previousData, Ledger? selectedLedger) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final timeRangeType = ref.watch(selectedTimeRangeTypeProvider);

    // Current period total
    double currentTotal = currentData.fold(0.0, (sum, item) => sum + item.y);

    // Calculate period info based on time range type
    String periodTitle;
    String dailyTitle;
    String comparisonTitle;
    String tooltipMessage;
    double dailyAverage = 0.0;

    switch (timeRangeType) {
      case '90days':
        periodTitle = '90天总支出';
        dailyTitle = '90天日均';
        comparisonTitle = '较前90天';
        dailyAverage = currentTotal / 90;
        break;
      case '60days':
        periodTitle = '60天总支出';
        dailyTitle = '60天日均';
        comparisonTitle = '较前60天';
        dailyAverage = currentTotal / 60;
        break;
      case 'year':
        periodTitle = '全年总支出';
        dailyTitle = '全年日均';
        comparisonTitle = '较去年同期';
        final daysInYear = DateTime(selectedMonth.year, 12, 31)
                .difference(DateTime(selectedMonth.year, 1, 1))
                .inDays +
            1;
        dailyAverage = currentTotal / daysInYear;
        break;
      case 'all':
        periodTitle = '累计总支出';
        dailyTitle = '全部日均';
        comparisonTitle = '较前期';
        final startDate = DateTime(2020, 1, 1);
        final daysSinceStart = DateTime.now().difference(startDate).inDays;
        dailyAverage = daysSinceStart > 0 ? currentTotal / daysSinceStart : 0.0;
        break;
      case 'month':
      default:
        periodTitle = '当月总支出';
        dailyTitle = '当月日均';
        comparisonTitle = '较上月支出';
        final daysInMonth =
            DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        dailyAverage = daysInMonth > 0 ? currentTotal / daysInMonth : 0.0;
        break;
    }

    // Change vs previous period
    double previousTotal = previousData.fold(0.0, (sum, item) => sum + item.y);
    tooltipMessage =
        '上期支出: ${selectedLedger?.currencySymbol ?? '¥'} ${_formatCurrency(previousTotal)}';

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
          periodTitle,
          '${selectedLedger?.currencySymbol ?? '¥'} ${_formatCurrency(currentTotal)}',
        ),
        const SizedBox(width: 10),
        _buildStatsItem(
          dailyTitle,
          '${selectedLedger?.currencySymbol ?? '¥'} ${_formatCurrency(dailyAverage)}',
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tooltip(
            message: tooltipMessage,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    comparisonTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPositive)
                        const Icon(Icons.arrow_upward,
                            color: Colors.red, size: 16),
                      if (isNegative)
                        const Icon(Icons.arrow_downward,
                            color: Colors.green, size: 16),
                      if (!isPositive && !isNegative) const SizedBox(width: 16),
                      Text(
                        '${changePercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? Colors.red
                              : (isNegative ? Colors.green : Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    // 动态获取账户信息
    final accountAsync =
        ref.watch(accountExpenseNodeProvider(widget.accountId));

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
    // Get selected ledger for currency symbol
    final selectedLedgerAsync = ref.watch(selectedLedgerProvider);

    return selectedLedgerAsync.when(
      data: (selectedLedger) =>
          _buildDetailPageWithLedger(context, account, selectedLedger),
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

  Widget _buildDetailPageWithLedger(BuildContext context,
      AccountExpenseNode account, Ledger? selectedLedger) {
    // Sample data for the pie chart - 这部分将被动态数据替代
    // final List<Map<String, dynamic>> expenseData = [...];
    // final double totalExpenseAmount = ...;
    // final List<StyledAccount> accountsFromExpenseData = ...;

    // 从 account 获取 accountId
    final int currentAccountId = account.accountData.accountId;

    // 使用 .family 传递 accountId
    final chartDataAsync =
        ref.watch(expenseChartDataProvider(currentAccountId));
    // Watch the new provider for previous period's data
    final previousPeriodDataAsync =
        ref.watch(previousPeriodExpenseProviderFamily(currentAccountId));
    // 添加对 expenseAccountTreeDataProvider 的 watch
    final accountTreeAsync = ref.watch(expenseAccountTreeDataProvider);

    final currentSelectedMonth = ref.watch(selectedMonthProvider);
    ref.watch(selectedTimeRangeTypeProvider); // Watch for state changes

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
                // Get current ledger for currency symbol
                final currentLedger = ref.read(selectedLedgerProvider).value;

                // Convert database Account to UI Account
                final uiAccount = ui.Account(
                  id: account.accountData.accountId,
                  name: account.accountData.accountName,
                  amount: account.balance,
                  type: account.accountData.accountType,
                  currencySymbol: currentLedger?.currencySymbol ?? '¥',
                );

                final isDeleted = await AccountUpdateBottomSheet.show(
                  context,
                  accountToUpdate: uiAccount,
                );

                // 如果账户被删除，退出详情页面
                if (!context.mounted) return;
                if (isDeleted == true) {
                  Navigator.of(context).pop();
                }
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
                  // 支出统计
                  child: Column(
                    children: [
                      MonthSelectorHeader(
                        initialDate: currentSelectedMonth,
                        onDateChanged: (newDate) {
                          ref.read(selectedMonthProvider.notifier).state =
                              newDate;
                        },
                        onLongRangeSelected: () async {
                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          try {
                            final chartDataValue = ref.read(
                                expenseChartDataProvider(currentAccountId));
                            if (!chartDataValue.hasValue) return;
                            final chartData = chartDataValue.value!;

                            String title = _getCurrentTimeRangeTitle();
                            int daysInPeriod = _getCurrentDaysInPeriod();

                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullscreenChartPage(
                                    chartData: chartData,
                                    daysInPeriod: daysInPeriod,
                                    startDate: _getStartDateForChart(),
                                    endDate: _getEndDateForChart(),
                                    timeRangeTitle: title,
                                    isLineChart: _isLineChart,
                                    chartType: ChartType.expense,
                                  ),
                                ),
                              );
                            }
                          } catch (error) {
                            // Silently handle error
                          }
                        },
                      ),
                      const SizedBox(
                        height: 12,
                        child: ColoredBox(color: Colors.transparent),
                      ),
                      // Statistics row
                      chartDataAsync.when(
                        data: (currentData) {
                          return previousPeriodDataAsync.when(
                            data: (previousData) => _buildStatsRow(
                                currentData, previousData, selectedLedger),
                            loading: () => Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            error: (error, stack) => Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text('统计数据加载失败'),
                              ),
                            ),
                          );
                        },
                        loading: () => Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (error, stack) => Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text('统计数据加载失败'),
                          ),
                        ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '支出统计图',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 图表类型切换按钮
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isLineChart = !_isLineChart;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isLineChart
                                                    ? Icons.show_chart
                                                    : Icons.bar_chart,
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
                                      const SizedBox(width: 8),
                                      // 全屏按钮
                                      GestureDetector(
                                        onTap: () async {
                                          if (!mounted) return;

                                          try {
                                            final chartDataValue = ref.read(
                                                expenseChartDataProvider(
                                                    currentAccountId));
                                            if (!chartDataValue.hasValue) {
                                              return;
                                            }
                                            final chartData =
                                                chartDataValue.value!;

                                            String title =
                                                _getCurrentTimeRangeTitle();
                                            int daysInPeriod =
                                                _getCurrentDaysInPeriod();

                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      FullscreenChartPage(
                                                    chartData: chartData,
                                                    ledger: selectedLedger,
                                                    daysInPeriod: daysInPeriod,
                                                    startDate:
                                                        _getStartDateForChart(),
                                                    endDate:
                                                        _getEndDateForChart(),
                                                    timeRangeTitle: title,
                                                    isLineChart: _isLineChart,
                                                    chartType:
                                                        ChartType.expense,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (error) {
                                            // Silently handle error
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Icon(
                                            Icons.fullscreen,
                                            size: 16,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Chart content
                            chartDataAsync.when(
                              data: (chartData) {
                                final daysInPeriod = _getCurrentDaysInPeriod();
                                return _isLineChart
                                    ? fl_linechart.FlLineChart(
                                        lineColor: Colors.red,
                                        currencySymbol:
                                            selectedLedger?.currencySymbol ??
                                                '¥',
                                        chartData: chartData
                                            .map((e) => fl_linechart.ChartData(
                                                e.x, e.y, e.day))
                                            .toList(),
                                        daysInMonth: daysInPeriod,
                                        startDate: _getStartDateForChart(),
                                        endDate: _getEndDateForChart(),
                                      )
                                    : fl_barchart.FlBarChart(
                                        barColor: Colors.red,
                                        currencySymbol:
                                            selectedLedger?.currencySymbol ??
                                                '¥',
                                        chartData: chartData
                                            .map((e) => fl_barchart.ChartData(
                                                e.x, e.y, e.day))
                                            .toList(),
                                        daysInMonth: daysInPeriod,
                                        startDate: _getStartDateForChart(),
                                        endDate: _getEndDateForChart(),
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

                    // 计算一级账户总金额（所有子账户余额之和）
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
                    final sortedNodes =
                        List<AccountExpenseNode>.from(childrenNodes);
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
                      final color =
                          accountColorMap[node.accountData.accountName]!;
                      final double percentageOfParent = parentAccountBalance > 0
                          ? (node.balance / parentAccountBalance) * 100
                          : 0.0;
                      styledAccounts.add(StyledAccount(
                        name: node.accountData.accountName,
                        rawAmount: node.balance,
                        currencySymbol: selectedLedger?.currencySymbol ?? '¥',
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
                              child: CustomPieChart(
                                expenseData: pieChartExpenseData,
                                currencySymbol:
                                    selectedLedger?.currencySymbol ?? '¥',
                              ),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
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
                                extra: {
                                  'accountId':
                                      selectedNode.accountData.accountId
                                },
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
