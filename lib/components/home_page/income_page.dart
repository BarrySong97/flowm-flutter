import 'package:flowm/state/icome/income_providers.dart';
import 'package:flowm/state/expense/expense_providers.dart' as expense_providers;
import 'package:flowm/components/chart/fullscreen_chart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/chart/custom_pie_chart.dart';
import 'package:flowm/components/account/styled_account_item.dart';
import 'package:flowm/components/account/styled_account_list.dart';
import 'package:flowm/components/common/month_selector_header.dart';
import 'package:flowm/models/account_expense_node.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flowm/components/chart/barchart.dart' as barchart;
import 'package:flowm/components/chart/fl_bar_chart.dart' as fl_barchart;
import 'package:flowm/components/chart/fl_line_chart.dart' as fl_linechart;

class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with AutomaticKeepAliveClientMixin {
  bool _isAscending = true; // 默认升序排列
  bool _isLineChart = false; // false for bar chart, true for line chart

  DateTime? _getStartDateForChart() {
    final selectedMonth = ref.read(selectedMonthProvider);
    final timeRangeType = ref.read(expense_providers.selectedTimeRangeTypeProvider);
    
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
    final timeRangeType = ref.read(expense_providers.selectedTimeRangeTypeProvider);
    
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
    final timeRangeType = ref.read(expense_providers.selectedTimeRangeTypeProvider);
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
    final timeRangeType = ref.read(expense_providers.selectedTimeRangeTypeProvider);
    
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
    if (amount.abs() >= 100000) {
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
    final timeRangeType = ref.watch(expense_providers.selectedTimeRangeTypeProvider);

    // Current period total
    double currentTotal = data.chartData.fold(0.0, (sum, item) => sum + item.y);

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
        final daysInYear = DateTime(selectedMonth.year, 12, 31).difference(DateTime(selectedMonth.year, 1, 1)).inDays + 1;
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
        final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        dailyAverage = daysInMonth > 0 ? currentTotal / daysInMonth : 0.0;
        break;
    }

    // Change vs previous period
    double previousTotal = data.previousMonthChartData.fold(0.0, (sum, item) => sum + item.y);
    tooltipMessage = '上期收入: ¥ ${_formatCurrency(previousTotal)}';
    
    double changePercent = 0;
    if (previousTotal.abs() > 0.001) {
      changePercent = ((currentTotal - previousTotal) / previousTotal.abs()) * 100;
    } else if (currentTotal.abs() > 0.001) {
      changePercent = currentTotal > 0 ? 100.0 : -100.0;
    }
    final isPositive = changePercent > 0.001;
    final isNegative = changePercent < -0.001;

    return Row(
      children: [
        _buildStatsItem(
          periodTitle,
          '¥ ${_formatCurrency(currentTotal)}',
        ),
        const SizedBox(width: 10),
        _buildStatsItem(
          dailyTitle,
          '¥ ${_formatCurrency(dailyAverage)}',
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

  Widget _buildChart(List<barchart.ChartData> chartData) {
    // Calculate the correct number of days based on time range type
    int daysInPeriod = _getCurrentDaysInPeriod();
    
    return Container(
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const SizedBox(width: 8),
                    // 全屏按钮
                    GestureDetector(
                      onTap: () async {
                        if (!mounted) return;
                        
                        try {
                          final pageData = await ref.refresh(incomePageDataProvider.future);
                          
                          String title = _getCurrentTimeRangeTitle();
                          int daysInPeriod = _getCurrentDaysInPeriod();
                          
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullscreenChartPage(
                                  chartData: pageData.chartData,
                                  daysInPeriod: daysInPeriod,
                                  startDate: _getStartDateForChart(),
                                  endDate: _getEndDateForChart(),
                                  timeRangeTitle: title,
                                  isLineChart: _isLineChart,
                                  chartType: ChartType.income,
                                ),
                              ),
                            );
                          }
                        } catch (error) {
                          // Silently handle error in production
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
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
          _isLineChart
              ? fl_linechart.FlLineChart(
                  lineColor: Colors.green,
                  chartData: chartData
                      .map((e) => fl_linechart.ChartData(e.x, e.y, e.day))
                      .toList(),
                  daysInMonth: daysInPeriod,
                  startDate: _getStartDateForChart(),
                  endDate: _getEndDateForChart(),
                )
              : fl_barchart.FlBarChart(
                  barColor: Colors.green,
                  chartData: chartData
                      .map((e) => fl_barchart.ChartData(e.x, e.y, e.day))
                      .toList(),
                  daysInMonth: daysInPeriod,
                  startDate: _getStartDateForChart(),
                  endDate: _getEndDateForChart(),
                ),
        ],
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

    // 先为原始数据分配颜色，保持颜色映射关系
    final Map<String, Color> accountColorMap = {};
    final List<Map<String, dynamic>> pieChartExpenseData = [];
    
    for (int i = 0; i < accountTreeNodes.length; i++) {
      final node = accountTreeNodes[i];
      final color = pieColors[i % pieColors.length];
      accountColorMap[node.accountData.accountName] = color;
      pieChartExpenseData.add({
        'category': node.accountData.accountName,
        'amount': node.balance,
        'color': color,
      });
    }

    // 根据排序状态对accountTreeNodes进行排序，但保持原有颜色
    final sortedNodes = List<AccountExpenseNode>.from(accountTreeNodes);
    sortedNodes.sort((a, b) {
      if (_isAscending) {
        return a.balance.compareTo(b.balance);
      } else {
        return b.balance.compareTo(a.balance);
      }
    });

    final List<StyledAccount> styledAccounts = [];
    for (final node in sortedNodes) {
      final color = accountColorMap[node.accountData.accountName]!;
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
          Stack(
            children: [
              SizedBox(
                height: 260,
                child: CustomPieChart(expenseData: pieChartExpenseData),
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
                final routeName = selectedNode.children.isNotEmpty
                    ? 'topIncomeDetail'
                    : 'incomeDetail';
                GoRouter.of(context).pushNamed(
                  routeName,
                  extra: {'accountId': selectedNode.accountData.accountId},
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
    ref.watch(expense_providers.selectedTimeRangeTypeProvider); // Watch for state changes
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
                  onLongRangeSelected: () async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    try {
                      final pageData = await ref.refresh(incomePageDataProvider.future);
                      
                      String title = _getCurrentTimeRangeTitle();
                      int daysInPeriod = _getCurrentDaysInPeriod();
                      
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FullscreenChartPage(
                              chartData: pageData.chartData,
                              daysInPeriod: daysInPeriod,
                              startDate: _getStartDateForChart(),
                              endDate: _getEndDateForChart(),
                              timeRangeTitle: title,
                              isLineChart: _isLineChart,
                              chartType: ChartType.income,
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      // Silently handle error in production
                    }
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
                      _buildChart(data.chartData),
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
                    child: Text('加载支出分类失败: $error'),
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
