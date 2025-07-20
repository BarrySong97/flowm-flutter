import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyData {
  MonthlyData(this.month, this.expense, this.income);
  final String month;
  final double expense;
  final double income;
}

class IncomeExpenseBarChart extends StatelessWidget {
  final List<MonthlyData> monthlyData;

  const IncomeExpenseBarChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final double expenseMaxY = monthlyData.map((e) => e.expense).reduce((a, b) => a > b ? a : b);
    final double incomeMaxY = monthlyData.map((e) => e.income).reduce((a, b) => a > b ? a : b);
    final double dataMaxY = expenseMaxY > incomeMaxY ? expenseMaxY : incomeMaxY;
    
    const niceDivisor = 1000.0;
    double maxY = (dataMaxY * 1.2 / niceDivisor).ceil() * niceDivisor;
    if (maxY == 0) {
      maxY = 5000;
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10.0, right: 24.0, top: 32.0, bottom: 16
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: -maxY,
            barTouchData: _buildBarTouchData(),
            titlesData: _buildTitlesData(maxY),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(),
            gridData: const FlGridData(show: false),
            alignment: BarChartAlignment.spaceAround,
          ),
        ),
      ),
    );
  }

  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.blueGrey,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final data = monthlyData[groupIndex];
          final isExpense = rod.toY > 0;
          final value = rod.toY.abs();
          final type = isExpense ? '支出' : '收入';
          
          return BarTooltipItem(
            '${data.month}$type\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            children: <TextSpan>[
              TextSpan(
                text: NumberFormat.compact().format(value),
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  FlTitlesData _buildTitlesData(double maxY) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          getTitlesWidget: (double value, TitleMeta meta) {
            const style = TextStyle(
              color: Color(0xff7589a2),
              fontSize: 12,
            );
            String text = '';
            if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
              // 只显示部分月份标签避免拥挤
              final monthIndex = value.toInt() + 1;
              if (monthIndex == 1 || monthIndex % 2 == 0) {
                text = '$monthIndex月';
              }
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(text, style: style),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: maxY / 2, // 减少标签数量
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox.shrink();
            return Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                NumberFormat.compact().format(value.abs()),
                style: const TextStyle(color: Color(0xff7589a2), fontSize: 12),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(monthlyData.length, (index) {
      final data = monthlyData[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          // 支出柱子（向上）
          BarChartRodData(
            toY: data.expense,
            color: const Color(0xfff85544), // 使用参考样式的红色
            width: 8,
            borderRadius: BorderRadius.zero,
          ),
          // 收入柱子（向下）
          BarChartRodData(
            toY: -data.income,
            color: const Color(0xff34C759), // 绿色
            width: 8,
            borderRadius: BorderRadius.zero,
          ),
        ],
        barsSpace: 0, // 设置柱子之间的间距为0，让它们重叠对齐
      );
    });
  }

  static List<MonthlyData> generateSampleData() {
    return List.generate(12, (index) {
      final expense = (index + 1) * 1000.0 + (index % 3) * 500;
      final income = (index + 1) * 800.0 + (index % 4) * 300;
      return MonthlyData('${index + 1}月', expense, income);
    });
  }
}