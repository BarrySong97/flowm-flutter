import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

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
    this.startDate,
    this.endDate,
    this.isLandscape = false,
    this.currencySymbol = AppConstants.currencySymbol,
  });

  final List<ChartData> chartData;
  final Color lineColor;
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
        child: Stack(
          children: [
            LineChart(
              LineChartData(
                maxY: maxY,
                lineTouchData: _buildLineTouchData(),
                titlesData: _buildTitlesData(maxY),
                borderData: FlBorderData(show: false),
                lineBarsData: _buildLineBarsData(),
                gridData: const FlGridData(show: false),
              ),
            ),
            // Custom overlay for small values in landscape mode
            if (isLandscape) _buildValueLabelsOverlay(maxY),
          ],
        ),
      ),
    );
  }

  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.9),
        tooltipMargin: isLandscape ? 12 : 8, // More margin in landscape
        tooltipPadding: const EdgeInsets.all(8),
        tooltipBorder: BorderSide.none,
        fitInsideHorizontally: true,
        fitInsideVertically: true, // Force tooltip to stay inside chart bounds
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final dataIndex = barSpot.x.toInt();
            final data =
                dataIndex < chartData.length ? chartData[dataIndex] : null;
            return LineTooltipItem(
              '${data?.day ?? (dataIndex + 1).toString()}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14, // Slightly smaller for better fit
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '$currencySymbol${barSpot.y.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList();
        },
      ),
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((spotIndex) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: Colors.transparent,
              strokeWidth: 0,
            ),
            FlDotData(
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
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
                  if (index == 0 || (index + 1) % 5 == 0 || index == count - 1) {
                    final labelDate = startDate!.add(Duration(days: index));
                    text = '${labelDate.month}/${labelDate.day}';
                  }
                } else if (count <= 365) {
                  // Show labels every 10 days for "all" data view (more frequent)
                  if (index == 0 || (index + 1) % 10 == 0 || index == count - 1) {
                    final labelDate = startDate!.add(Duration(days: index));
                    text = '${labelDate.month}/${labelDate.day}';
                  }
                } else {
                  // For very long periods, show labels every 15 days
                  if (index == 0 || (index + 1) % 15 == 0 || index == count - 1) {
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
          reservedSize: isLandscape ? 60 : 70, // Fixed width in landscape for stability
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
                  fontSize: isLandscape ? 10 : 11
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildValueLabelsOverlay(double maxY) {
    final count = daysInMonth ?? chartData.length;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;
        final pointSpacing = chartWidth / count;
        
        return Stack(
          children: chartData.asMap().entries.where((entry) {
            // Only show labels for values < 100 and > 0
            return entry.value.y > 0 && entry.value.y < 100;
          }).map((entry) {
            final index = entry.key;
            final data = entry.value;
            
            // Calculate position
            final x = (index + 0.5) * pointSpacing;
            final pointHeightRatio = data.y / maxY;
            final y = chartHeight * (1 - pointHeightRatio) - 25; // 25px above point
            
            return Positioned(
              left: x - 15, // Center the text (approximate)
              top: y,
              child: Container(
                width: 30,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: lineColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    data.y.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final count = daysInMonth ?? chartData.length;
    final spots = <FlSpot>[];

    for (int i = 0; i < count; i++) {
      final data =
          i < chartData.length ? chartData[i] : ChartData(i.toDouble(), 0, '');
      spots.add(FlSpot(i.toDouble(), data.y));
    }

    return [
      LineChartBarData(
        spots: spots,
        color: lineColor,
        barWidth: 2,
        isStrokeCapRound: true,
        isCurved: true,
        preventCurveOverShooting: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: lineColor.withValues(alpha: 0.2),
        ),
      ),
    ];
  }
}
