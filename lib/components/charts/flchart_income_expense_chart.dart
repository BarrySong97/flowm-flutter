import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyComparisonData {
  MonthlyComparisonData(this.month, this.expense, this.income);
  final String month;
  final double expense;
  final double income;
}


class FlchartIncomeExpenseChart extends StatefulWidget {
  const FlchartIncomeExpenseChart({
    super.key,
    required this.monthlyData,
    this.periodRange,
  });

  final List<MonthlyComparisonData> monthlyData;
  final String? periodRange; // 用于调整条形图宽度

  @override
  State<FlchartIncomeExpenseChart> createState() =>
      _FlchartIncomeExpenseChartState();
}

class _FlchartIncomeExpenseChartState extends State<FlchartIncomeExpenseChart> {
  final Color expenseColor = const Color(0xfff85544);
  final Color incomeColor = const Color(0xff34C759);
  int touchedGroupIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyData.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final double expenseMaxY = widget.monthlyData
        .map((e) => e.expense)
        .reduce((a, b) => a > b ? a : b);
    final double incomeMaxY =
        widget.monthlyData.map((e) => e.income).reduce((a, b) => a > b ? a : b);
    final double dataMaxY = expenseMaxY > incomeMaxY ? expenseMaxY : incomeMaxY;
    final double maxY = dataMaxY * 1.2;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Stack(
          children: [
            BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: -maxY,
                barTouchData: BarTouchData(
                  handleBuiltInTouches: false,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      setState(() {
                        touchedGroupIndex = -1;
                      });
                      return;
                    }
                    setState(() {
                      touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _bottomTitles,
                      reservedSize: 42,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY / 2,
                      getTitlesWidget: _leftTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildVerticalBarGroups(),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (value) {
                    if (value == 0) {
                      return FlLine(
                        color: Colors.grey[400]!,
                        strokeWidth: 0.5,
                        dashArray: [3, 2],
                      );
                    }
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 0.5,
                    );
                  },
                  drawVerticalLine: false,
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0,
                      color: Colors.grey[600]!,
                      strokeWidth: 0.5,
                      dashArray: [3, 2],
                    ),
                  ],
                ),
              ),
            ),
            // 右上角信息显示
            if (touchedGroupIndex >= 0 && touchedGroupIndex < widget.monthlyData.length)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _buildTouchedInfo(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildVerticalBarGroups() {
    final List<BarChartGroupData> groups = [];

    // 根据数据量调整条形图宽度
    double barWidth = _getBarWidth();

    for (int i = 0; i < widget.monthlyData.length; i++) {
      final data = widget.monthlyData[i];
      final isTouched = i == touchedGroupIndex;

      // 每个月份创建一个组，只有一个 rod，包含收入和支出
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data.income,
            fromY: -data.expense,
            color: isTouched ? incomeColor.withValues(alpha: 0.8) : incomeColor,
            width: barWidth,
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(
              color: Colors.white,
              width: isTouched ? 2 : 0,
            ),
            rodStackItems: [
              BarChartRodStackItem(
                -data.expense,
                0,
                isTouched ? expenseColor.withValues(alpha: 0.8) : expenseColor,
              ),
              BarChartRodStackItem(
                0,
                data.income,
                isTouched ? incomeColor.withValues(alpha: 0.8) : incomeColor,
              ),
            ],
          ),
        ],
      ));
    }

    return groups;
  }

  double _getBarWidth() {
    final dataCount = widget.monthlyData.length;

    // 根据数据点数量动态调整条形图宽度
    if (dataCount <= 7) {
      // 周视图（7天）
      return 8.0;
    } else if (dataCount <= 12) {
      // 年视图（12个月）
      return 6.0;
    } else if (dataCount <= 24) {
      // 全部视图（24个月）
      return 4.0;
    } else {
      // 月视图（30天）或更多数据
      return 3.0;
    }
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == 0) {
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: const Text(
          '0',
          style: TextStyle(
            color: Color(0xff7589a2),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        NumberFormat.compact().format(value.abs()),
        style: const TextStyle(
          color: Color(0xff7589a2),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= widget.monthlyData.length) {
      return const SizedBox();
    }

    final dataCount = widget.monthlyData.length;
    final index = value.toInt();

    // 根据数据量决定显示标签的间隔
    int interval = _getLabelInterval();

    // 只在指定间隔显示标签
    if (index % interval != 0 && index != dataCount - 1) {
      return const SizedBox();
    }

    final month = widget.monthlyData[index].month;
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text(
        month,
        style: const TextStyle(
          color: Color(0xff7589a2),
          fontSize: 10,
        ),
      ),
    );
  }

  int _getLabelInterval() {
    final dataCount = widget.monthlyData.length;

    if (dataCount <= 7) {
      // 周视图：显示所有标签
      return 1;
    } else if (dataCount <= 12) {
      // 年视图：显示所有标签
      return 1;
    } else if (dataCount <= 24) {
      // 全部视图：每3个显示一个
      return 3;
    } else {
      // 月视图：每5个显示一个
      return 5;
    }
  }

  Widget _buildTouchedInfo() {
    final data = widget.monthlyData[touchedGroupIndex];
    final expense = data.expense;
    final income = data.income;
    final balance = income - expense;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.month,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '收入: ¥${_formatTooltipAmount(income)}',
          style: TextStyle(
            color: Colors.green[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '支出: ¥${_formatTooltipAmount(expense)}',
          style: TextStyle(
            color: Colors.red[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '结余: ¥${_formatTooltipAmount(balance)}',
          style: TextStyle(
            color: balance >= 0 ? Colors.blue[300] : Colors.orange[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTooltipAmount(double amount) {
    return amount.toStringAsFixed(2);
  }
}

// 生成示例数据的独立函数
List<MonthlyComparisonData> generateSampleMonthlyData() {
  return List.generate(12, (index) {
    final expense = (index + 1) * 1000.0 + (index % 3) * 500;
    final income = (index + 1) * 800.0 + (index % 4) * 300;
    return MonthlyComparisonData('${index + 1}月', expense, income);
  });
}