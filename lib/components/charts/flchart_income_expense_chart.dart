import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_constants.dart';

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
    this.dateRange,
    this.currencySymbol = AppConstants.currencySymbol,
  });

  final List<MonthlyComparisonData> monthlyData;
  final String? periodRange; // 用于调整条形图宽度
  final DateTimeRange? dateRange; // 用于确定正确的时间标签
  final String currencySymbol;

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
    // For empty data, create placeholder data based on the expected period type
    List<MonthlyComparisonData> displayData = widget.monthlyData;
    
    if (widget.monthlyData.isEmpty) {
      // Try to determine the period type and create appropriate placeholder data
      displayData = _createPlaceholderData();
    }

    final double expenseMaxY = displayData.isEmpty 
        ? 0.0 
        : displayData.map((e) => e.expense).reduce((a, b) => a > b ? a : b);
    final double incomeMaxY = displayData.isEmpty 
        ? 0.0 
        : displayData.map((e) => e.income).reduce((a, b) => a > b ? a : b);
    final double dataMaxY = expenseMaxY > incomeMaxY ? expenseMaxY : incomeMaxY;
    final double maxY = dataMaxY == 0 ? 100.0 : dataMaxY * 1.2;

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
                      getTitlesWidget: (value, meta) => _bottomTitles(value, meta, displayData),
                      reservedSize: 42,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY > 0 ? maxY / 2 : 50.0,
                      getTitlesWidget: _leftTitles,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildVerticalBarGroups(displayData),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY > 0 ? maxY / 2 : 50.0,
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
            if (touchedGroupIndex >= 0 && touchedGroupIndex < displayData.length)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _buildTouchedInfo(displayData),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildVerticalBarGroups(List<MonthlyComparisonData> data) {
    final List<BarChartGroupData> groups = [];

    // 根据数据量调整条形图宽度
    double barWidth = _getBarWidth(data);

    for (int i = 0; i < data.length; i++) {
      final monthData = data[i];
      final isTouched = i == touchedGroupIndex;

      // 每个月份创建一个组，只有一个 rod，包含收入和支出
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: monthData.income,
            fromY: -monthData.expense,
            color: isTouched ? incomeColor.withValues(alpha: 0.8) : incomeColor,
            width: barWidth,
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(
              color: Colors.white,
              width: isTouched ? 2 : 0,
            ),
            rodStackItems: [
              BarChartRodStackItem(
                -monthData.expense,
                0,
                isTouched ? expenseColor.withValues(alpha: 0.8) : expenseColor,
              ),
              BarChartRodStackItem(
                0,
                monthData.income,
                isTouched ? incomeColor.withValues(alpha: 0.8) : incomeColor,
              ),
            ],
          ),
        ],
      ));
    }

    return groups;
  }

  double _getBarWidth(List<MonthlyComparisonData> data) {
    final dataCount = data.length;

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

  Widget _bottomTitles(double value, TitleMeta meta, List<MonthlyComparisonData> data) {
    if (value.toInt() >= data.length) {
      return const SizedBox();
    }

    final dataCount = data.length;
    final index = value.toInt();

    // 根据数据量决定显示标签的间隔
    int interval = _getLabelInterval(data);

    // 只在指定间隔显示标签
    if (index % interval != 0 && index != dataCount - 1) {
      return const SizedBox();
    }

    final month = data[index].month;
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

  int _getLabelInterval(List<MonthlyComparisonData> data) {
    final dataCount = data.length;

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

  Widget _buildTouchedInfo(List<MonthlyComparisonData> data) {
    final monthData = data[touchedGroupIndex];
    final expense = monthData.expense;
    final income = monthData.income;
    final balance = income - expense;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthData.month,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '收入: ${widget.currencySymbol}${_formatTooltipAmount(income)}',
          style: TextStyle(
            color: Colors.green[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '支出: ${widget.currencySymbol}${_formatTooltipAmount(expense)}',
          style: TextStyle(
            color: Colors.red[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '结余: ${widget.currencySymbol}${_formatTooltipAmount(balance)}',
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

  List<MonthlyComparisonData> _createPlaceholderData() {
    // If we have no real data, we need to create placeholder data that matches
    // the expected format based on the period range and date range context.
    
    final now = DateTime.now();
    
    // Check periodRange to determine the most appropriate format
    if (widget.periodRange == 'Y') {
      // Pure year view - use simple month labels
      return List.generate(12, (index) {
        return MonthlyComparisonData('${index + 1}月', 0.0, 0.0);
      });
    } else if (widget.periodRange == 'W') {
      // Week view - use day labels
      return List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return MonthlyComparisonData('${date.month}/${date.day}', 0.0, 0.0);
      });
    } else if (widget.periodRange == 'M') {
      // Month view - use day-of-month labels
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(daysInMonth, (index) {
        return MonthlyComparisonData('${index + 1}日', 0.0, 0.0);
      });
    } else {
      // Range mode - determine format based on the actual date range
      if (widget.dateRange != null) {
        final start = widget.dateRange!.start;
        final end = widget.dateRange!.end;
        
        // Check if this looks like a year range (12 months, starts in January)
        if (start.month == 1 && start.day == 1 && 
            end.month == 12 && end.day == 31 && 
            start.year == end.year) {
          // This is a full year range, use simple month format like "1月", "2月"
          return List.generate(12, (index) {
            return MonthlyComparisonData('${index + 1}月', 0.0, 0.0);
          });
        }
        
        // Check if this looks like a month range
        if (start.day == 1) {
          final expectedEnd = DateTime(start.year, start.month + 1, 0);
          if (end.year == expectedEnd.year && 
              end.month == expectedEnd.month && 
              end.day == expectedEnd.day) {
            // This is a month range, create day labels
            final daysInMonth = expectedEnd.day;
            return List.generate(daysInMonth, (index) {
              return MonthlyComparisonData('${index + 1}日', 0.0, 0.0);
            });
          }
        }
        
        // Check if this looks like a week range (7 days)
        final daysDiff = end.difference(start).inDays + 1;
        if (daysDiff == 7) {
          return List.generate(7, (index) {
            final date = start.add(Duration(days: index));
            return MonthlyComparisonData('${date.month}/${date.day}', 0.0, 0.0);
          });
        }
      }
      
      // Default fallback - likely a navigated year view without specific range info
      return List.generate(12, (index) {
        return MonthlyComparisonData('${now.year}/${index + 1}', 0.0, 0.0);
      });
    }
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