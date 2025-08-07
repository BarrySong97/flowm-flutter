import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/fl_line_chart.dart' as fl_linechart;
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/state/icome/income_repository.dart';
import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/state/expense/expense_providers.dart'
    as expense_providers;
import 'package:flowm/state/ledger/ledger_repository.dart';
import 'package:flowm/db/app_database.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/components/chart/fullscreen_chart_page.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:flowm/state/account/account_info_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flowm/components/common/account_update_bottom_sheet.dart';
import 'package:flowm/components/account/account_item.dart' as ui;

/// 上期收入数据提供者 (family)
final previousPeriodIncomeProviderFamily = FutureProvider.autoDispose
    .family<List<barchart.ChartData>, int?>((ref, accountId) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType =
      ref.watch(expense_providers.selectedTimeRangeTypeProvider);

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

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
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
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType =
      ref.watch(expense_providers.selectedTimeRangeTypeProvider);

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

  return repository.getIncomeChartData(
    startDate: startDate,
    endDate: endDate,
    ledgerId: selectedLedger.ledgerId,
    accountId: accountId,
  );
});

/// 收入账户树数据提供者
final incomeAccountTreeDataProvider =
    FutureProvider.autoDispose<List<AccountExpenseNode>>((ref) async {
  final repository = ref.watch(IncomeRepositoryProvider);
  final selectedLedger = await ref.watch(selectedLedgerProvider.future);
  final selectedDate = ref.watch(selectedMonthProvider);
  final timeRangeType =
      ref.watch(expense_providers.selectedTimeRangeTypeProvider);

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
  ConsumerState<TopIncomeDetailPage> createState() =>
      _TopIncomeDetailPageState();
}

class _TopIncomeDetailPageState extends ConsumerState<TopIncomeDetailPage> {
  bool _isAscending = false; // 默认升序排列
  bool _isLineChart = false; // false for bar chart, true for line chart

  DateTime? _getStartDateForChart() {
    final selectedMonth = ref.read(selectedMonthProvider);
    final timeRangeType =
        ref.read(expense_providers.selectedTimeRangeTypeProvider);

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
    final timeRangeType =
        ref.read(expense_providers.selectedTimeRangeTypeProvider);

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
    final timeRangeType =
        ref.read(expense_providers.selectedTimeRangeTypeProvider);
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
    final timeRangeType =
        ref.read(expense_providers.selectedTimeRangeTypeProvider);

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

  // 辅助方法格式化数字
  String _formatCurrency(double amount) {
    if (amount.abs() >= 1000000) {
      // 6位数及以上才格式化
      return '${(amount / 1000).toStringAsFixed(2)}k';
    } else {
      return NumberFormat('#,##0.00', 'zh_CN').format(amount);
    }
  }

  Widget _buildStatsRow(List<barchart.ChartData> currentData,
      List<barchart.ChartData> previousData, Ledger? selectedLedger) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final timeRangeType =
        ref.watch(expense_providers.selectedTimeRangeTypeProvider);

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
        periodTitle = '90天总收入';
        dailyTitle = '90天日均';
        comparisonTitle = '较前90天';
        dailyAverage = currentTotal / 90;
        break;
      case '60days':
        periodTitle = '60天总收入';
        dailyTitle = '60天日均';
        comparisonTitle = '较前60天';
        dailyAverage = currentTotal / 60;
        break;
      case 'year':
        periodTitle = '全年总收入';
        dailyTitle = '全年日均';
        comparisonTitle = '较去年同期';
        final daysInYear = DateTime(selectedMonth.year, 12, 31)
                .difference(DateTime(selectedMonth.year, 1, 1))
                .inDays +
            1;
        dailyAverage = currentTotal / daysInYear;
        break;
      case 'all':
        periodTitle = '累计总收入';
        dailyTitle = '全部日均';
        comparisonTitle = '较前期';
        final startDate = DateTime(2020, 1, 1);
        final daysSinceStart = DateTime.now().difference(startDate).inDays;
        dailyAverage = daysSinceStart > 0 ? currentTotal / daysSinceStart : 0.0;
        break;
      case 'month':
      default:
        periodTitle = '当月总收入';
        dailyTitle = '当月日均';
        comparisonTitle = '较上月收入';
        final daysInMonth =
            DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        dailyAverage = daysInMonth > 0 ? currentTotal / daysInMonth : 0.0;
        break;
    }

    // Change vs previous period
    double previousTotal = previousData.fold(0.0, (sum, item) => sum + item.y);
    tooltipMessage =
        '上期收入: ${selectedLedger?.currencySymbol ?? '¥'} ${_formatCurrency(previousTotal)}';

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
        Expanded(
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
                  periodTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${selectedLedger?.currencySymbol ?? '¥'} ${_formatCurrency(currentTotal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
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
                  dailyTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${selectedLedger?.currencySymbol ?? '¥'} ${_formatCurrency(dailyAverage)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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
    final int currentAccountId = account.accountData.accountId;

    final chartDataAsync =
        ref.watch(incomeChartDataProviderFamily(currentAccountId));
    final previousPeriodDataAsync =
        ref.watch(previousPeriodIncomeProviderFamily(currentAccountId));
    // 添加对 incomeAccountTreeDataProvider 的 watch
    final accountTreeAsync = ref.watch(incomeAccountTreeDataProvider);

    final currentSelectedMonth = ref.watch(selectedMonthProvider);
    ref.watch(expense_providers
        .selectedTimeRangeTypeProvider); // Watch for state changes

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
                // Get current ledger for currency symbol
                final currentLedger =
                    await ref.read(selectedLedgerProvider.future);

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
                if (isDeleted == true && mounted) {
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
                                incomeChartDataProviderFamily(
                                    currentAccountId));
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
                                    chartType: ChartType.income,
                                    isLineChart: _isLineChart,
                                  ),
                                ),
                              );
                            }
                          } catch (error) {
                            // Handle error silently
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
                            // Chart title and buttons
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '收入统计图',
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
                                                incomeChartDataProviderFamily(
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
                                                    chartType: ChartType.income,
                                                    isLineChart: _isLineChart,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (error) {
                                            // Handle error silently
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
                                        lineColor: Colors.green,
                                        currencySymbol:
                                            selectedLedger?.currencySymbol ??
                                                "",
                                        chartData: chartData
                                            .map((e) => fl_linechart.ChartData(
                                                e.x, e.y, e.day))
                                            .toList(),
                                        daysInMonth: daysInPeriod,
                                        startDate: _getStartDateForChart(),
                                        endDate: _getEndDateForChart(),
                                      )
                                    : fl_barchart.FlBarChart(
                                        barColor: Colors.green,
                                        currencySymbol:
                                            selectedLedger?.currencySymbol ??
                                                "",
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

                    // 计算一级账户总金额（所有子账户余额之和）
                    final double parentAccountBalance = childrenNodes.fold(
                        0.0, (sum, node) => sum + node.balance);

                    // 先为原始数据分配颜色，保持颜色映射关系
                    final Map<String, Color> accountColorMap = {};
                    final List<Map<String, dynamic>> pieChartIncomeData = [];

                    for (int i = 0; i < childrenNodes.length; i++) {
                      final node = childrenNodes[i];
                      final color = pieColors[i % pieColors.length];
                      accountColorMap[node.accountData.accountName] = color;
                      pieChartIncomeData.add({
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
                                expenseData: pieChartIncomeData,
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
                                'incomeDetail',
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
            ],
          ),
        ))));
  }
}
