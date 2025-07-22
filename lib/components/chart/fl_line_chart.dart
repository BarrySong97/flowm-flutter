import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChartData {
  ChartData(this.x, this.y, this.day);
  final double x;
  final double y;
  final String day;
}

class FlLineChart extends StatelessWidget {
  const FlLineChart({
    super.key,
    required this.chartData,
    this.lineColor = const Color(0xfff85544),
    this.daysInMonth,
  });

  final List<ChartData> chartData;
  final Color lineColor;
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
          child: LineChart(
            LineChartData(
              maxY: maxY,
              lineTouchData: _buildLineTouchData(),
              titlesData: _buildTitlesData(maxY),
              borderData: FlBorderData(show: false),
              lineBarsData: _buildLineBarsData(),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.blueGrey,
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final dataIndex = barSpot.x.toInt();
            final data = dataIndex < chartData.length ? chartData[dataIndex] : null;
            return LineTooltipItem(
              '${data?.day ?? (dataIndex + 1).toString()}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: barSpot.y.toString(),
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((spotIndex) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: Colors.transparent,
              strokeWidth: 0,
            ),
            FlDotData(
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3,
                color: lineColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
          );
        }).toList();
      },
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

  List<LineChartBarData> _buildLineBarsData() {
    final count = daysInMonth ?? chartData.length;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < count; i++) {
      final data = i < chartData.length ? chartData[i] : ChartData(i.toDouble(), 0, '');
      // Ensure minimum value is slightly above 0 to prevent below-baseline rendering
      final yValue = data.y <= 0 ? 0.01 : data.y;
      spots.add(FlSpot(i.toDouble(), yValue));
    }

    return [
      LineChartBarData(
        spots: spots,
        color: lineColor,
        barWidth: 2,
        isStrokeCapRound: true,
        isCurved: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    ];
  }
}