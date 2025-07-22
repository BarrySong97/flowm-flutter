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
  });

  final List<MonthlyComparisonData> monthlyData;

  @override
  State<FlchartIncomeExpenseChart> createState() => _FlchartIncomeExpenseChartState();
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
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final double expenseMaxY = widget.monthlyData.map((e) => e.expense).reduce((a, b) => a > b ? a : b);
    final double incomeMaxY = widget.monthlyData.map((e) => e.income).reduce((a, b) => a > b ? a : b);
    final double dataMaxY = expenseMaxY > incomeMaxY ? expenseMaxY : incomeMaxY;
    final double maxY = dataMaxY * 1.2;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final data = widget.monthlyData[groupIndex];
                  final isExpense = rodIndex == 0;
                  final value = isExpense ? data.expense : data.income;
                  final type = isExpense ? '支出' : '收入';
                  
                  return BarTooltipItem(
                    '${data.month}$type\n${NumberFormat.compact().format(value)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
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
                  interval: maxY / 4,
                  getTitlesWidget: _leftTitles,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(),
            gridData: FlGridData(
              show: true,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
              drawVerticalLine: false,
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final List<BarChartGroupData> groups = [];
    
    for (int i = 0; i < widget.monthlyData.length; i++) {
      final data = widget.monthlyData[i];
      
      // 每个月份创建一个组，包含支出和收入两个条形图
      groups.add(BarChartGroupData(
        x: i,
        groupVertically: false,
        barsSpace: 2, // 减小间距让条形图更紧密
        barRods: [
          // 支出条（红色）
          BarChartRodData(
            toY: data.expense,
            color: expenseColor,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
          // 收入条（绿色）
          BarChartRodData(
            toY: data.income,
            color: incomeColor,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ));
    }
    
    return groups;
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    if (value == 0) {
      return const SizedBox();
    }
    
    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        NumberFormat.compact().format(value),
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
    
    final month = widget.monthlyData[value.toInt()].month;
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text(
        month,
        style: const TextStyle(
          color: Color(0xff7589a2),
          fontSize: 12,
        ),
      ),
    );
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