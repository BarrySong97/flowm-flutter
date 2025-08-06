import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

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
    this.startDate,
    this.endDate,
    this.isLandscape = false,
    this.currencySymbol = AppConstants.currencySymbol,
  });

  final List<ChartData> chartData;
  final Color barColor;
  final int? daysInMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLandscape;
  final String currencySymbol;

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

    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 0.0, right: 24.0, top: 32.0, bottom: 16),
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
    );
  }

  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.blueGrey.withValues(alpha: 0.9),
        tooltipMargin: isLandscape ? 12 : 8, // More margin in landscape
        tooltipPadding: const EdgeInsets.all(8),
        tooltipBorder: BorderSide.none,
        fitInsideHorizontally: true,
        fitInsideVertically: true, // Force tooltip to stay inside chart bounds
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final data = chartData[groupIndex];
          return BarTooltipItem(
            '${data.day}\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14, // Slightly smaller for better fit
            ),
            children: <TextSpan>[
              TextSpan(
                text: '$currencySymbol${rod.toY.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 12,
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
              fontSize: 10,
            );

            final count = daysInMonth ?? chartData.length;
            final index = value.toInt();
            String text = '';

            // For longer periods, show more labels in landscape fullscreen mode
            if (count > 31 && startDate != null && endDate != null) {
              if (isLandscape) {
                // In landscape fullscreen mode, show more frequent labels
                if (count <= 90) {
                  // Show labels every 5 days for 90-day view (more frequent)
                  if (index == 0 ||
                      (index + 1) % 5 == 0 ||
                      index == count - 1) {
                    final labelDate = startDate!.add(Duration(days: index));
                    text = '${labelDate.month}/${labelDate.day}';
                  }
                } else if (count <= 365) {
                  // Show labels every 10 days for "all" data view (more frequent)
                  if (index == 0 ||
                      (index + 1) % 10 == 0 ||
                      index == count - 1) {
                    final labelDate = startDate!.add(Duration(days: index));
                    text = '${labelDate.month}/${labelDate.day}';
                  }
                } else {
                  // For very long periods, show labels every 15 days
                  if (index == 0 ||
                      (index + 1) % 15 == 0 ||
                      index == count - 1) {
                    final labelDate = startDate!.add(Duration(days: index));
                    text = '${labelDate.month}/${labelDate.day}';
                  }
                }
              } else {
                // Portrait mode - show only start and end dates
                if (index == 0) {
                  text = '${startDate!.month}/${startDate!.day}';
                } else if (index == count - 1) {
                  text = '${endDate!.month}/${endDate!.day}';
                }
              }
            } else {
              // For monthly view, show day numbers as before
              final day = index + 1;
              if (day == 1 || day % 5 == 0) {
                text = day.toString();
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
          reservedSize:
              isLandscape ? 60 : 70, // Fixed width in landscape for stability
          interval: maxY / 5,
          getTitlesWidget: (value, meta) {
            String formattedValue;
            if (value >= 10000) {
              formattedValue = '${(value / 10000).toStringAsFixed(1)}万';
            } else if (value >= 1000) {
              formattedValue = '${(value / 1000).toStringAsFixed(1)}k';
            } else {
              formattedValue = value.toInt().toString();
            }
            return Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: isLandscape ? 8.0 : 16.0),
              child: Text(
                formattedValue,
                style: TextStyle(
                    color: const Color(0xff7589a2),
                    fontSize: isLandscape ? 10 : 11),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: isLandscape, // Only show in landscape mode
          reservedSize: 8, // Minimal space - numbers very close to bars
          // getTitlesWidget: (double value, TitleMeta meta) {
          //   final index = value.toInt();
          //   if (index < chartData.length) {
          //     final data = chartData[index];
          //     // Only show values < 100 and > 0
          //     if (data.y > 0 && data.y < 100) {
          //       return Text(
          //         data.y.toStringAsFixed(0),
          //         style: const TextStyle(
          //           fontSize: 8,
          //           fontWeight: FontWeight.bold,
          //           color: Colors.grey, // Changed to grey color
          //         ),
          //       );
          //     }
          //   }
          //   return const SizedBox.shrink();
          // },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final count = daysInMonth ?? chartData.length;

    // Calculate dynamic bar width based on data amount and orientation
    double barWidth;
    if (count <= 31) {
      barWidth = 8; // Standard width for monthly view
    } else if (count <= 60) {
      barWidth = isLandscape ? 6 : 3; // Wider bars in landscape for 60 days
    } else if (count <= 90) {
      barWidth =
          isLandscape ? 4 : 1.5; // Much wider bars in landscape for 90 days
    } else {
      // For very long periods in landscape with scrolling, use wider bars
      barWidth = isLandscape
          ? 6
          : 1; // Much wider bars in scrollable landscape for all data
    }

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
            width: barWidth,
            borderRadius: BorderRadius.zero,
          )
        ],
      );
    });
  }
}
