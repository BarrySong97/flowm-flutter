import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChartData {
  ChartData(this.x, this.y, this.day);
  final double x;
  final double y;
  final String day;
}

class FlBarChart extends StatelessWidget {
  const FlBarChart({
    super.key,
    required this.chartData,
    this.barColor = const Color(0xfff85544),
    this.daysInMonth,
  });

  final List<ChartData> chartData;
  final Color barColor;
  final int? daysInMonth;

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(child: Text('当月无数据')),
      );
    }

    final double dataMaxY =
        chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    const niceDivisor = 180.0;
    double maxY = (dataMaxY * 1.2 / niceDivisor).ceil() * niceDivisor;
    if (maxY == 0) {
      maxY = 1800;
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 10.0, right: 24.0, top: 32.0, bottom: 16),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barTouchData: _buildBarTouchData(),
              titlesData: _buildTitlesData(maxY),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(),
              gridData: const FlGridData(show: false),
              alignment: BarChartAlignment.spaceAround,
            ),
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
          final data = chartData[groupIndex];
          return BarTooltipItem(
            '${data.day}\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            children: <TextSpan>[
              TextSpan(
                text: rod.toY.toString(),
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
            String text;
            final day = value.toInt() + 1;
            if (day == 1 || day % 5 == 0) {
              text = day.toString();
            } else {
              text = '';
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
          interval: maxY / 5,
          getTitlesWidget: (value, meta) {
            return Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                NumberFormat.compact().format(value),
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
    final count = daysInMonth ?? chartData.length;
    return List.generate(count, (index) {
      final data = index < chartData.length
          ? chartData[index]
          : ChartData(index.toDouble(), 0, '');
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.y,
            color: barColor,
            width: 8,
            borderRadius: BorderRadius.zero,
          )
        ],
      );
    });
  }
}
