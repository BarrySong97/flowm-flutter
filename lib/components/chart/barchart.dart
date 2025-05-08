import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart'; // For number formatting

class MyBarChart extends StatefulWidget {
  const MyBarChart({super.key, this.barColor = Colors.blue});

  final Color barColor;

  @override
  State<StatefulWidget> createState() => MyBarChartState();
}

class _ChartData {
  _ChartData(this.x, this.y, this.day);
  final double x;
  final double y;
  final String day; // For tooltip
}

class MyBarChartState extends State<MyBarChart> {
  late List<_ChartData> _chartData;
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _chartData = List.generate(30, (i) {
      // Sample y data for 30 days, keeping it within a reasonable range for maxY: 20
      double yValue = 5 + (math.Random().nextDouble() * 10);
      if (yValue > 18)
        yValue = 18; // Cap to avoid frequent clipping against maxY
      if (yValue < 2) yValue = 2;
      return _ChartData(i.toDouble(), yValue, 'Day ${i + 1}');
    });

    _tooltipBehavior = TooltipBehavior(
      enable: true,
      header: '', // No header
      canShowMarker: false,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
          int seriesIndex) {
        final chartData = data as _ChartData;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chartData.day,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Adjusted for consistency
                ),
              ),
              Text(
                chartData.y.toString(), // Using the direct y value
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 14, // Adjusted for consistency
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: SfCartesianChart(
          plotAreaBorderWidth: 0, // No border around plot area
          primaryXAxis: NumericAxis(
            minimum: -0.5, // Adjust for 30 bars (0-29)
            maximum: 29.5, // Adjust for 30 bars (0-29)
            interval: 5, // Show labels for Day 1, 6, 11, 16, 21, 26
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            labelStyle: const TextStyle(color: Color(0xff7589a2), fontSize: 12),
            majorTickLines: const MajorTickLines(size: 0),
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            axisLabelFormatter: (AxisLabelRenderDetails args) {
              // args.value will be 0, 5, 10, 15, 20, 25 due to interval
              return ChartAxisLabel(
                  '${args.value.toInt() + 1}', args.textStyle);
            },
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 20,
            interval: 10, // Set interval to 10 to get 0, 10, 20
            majorGridLines:
                const MajorGridLines(width: 0), // No horizontal grid lines
            axisLine: const AxisLine(width: 0), // No y-axis line
            labelStyle: const TextStyle(color: Color(0xff7589a2), fontSize: 12),
            majorTickLines: const MajorTickLines(size: 0), // No ticks
            numberFormat: NumberFormat.compact(), // For 10K, 20K
            axisLabelFormatter: (AxisLabelRenderDetails args) {
              String textValue;
              if (args.value == 0) {
                textValue = '0';
              } else if (args.value == 10) {
                textValue = '10K';
              } else if (args.value == 20) {
                // Changed from 19 to 20 for the label
                textValue = '20K';
              } else {
                return ChartAxisLabel('', args.textStyle); // Hide other labels
              }
              return ChartAxisLabel(textValue, args.textStyle);
            },
          ),
          series: <CartesianSeries>[
            // Column Series (Bar Chart)
            ColumnSeries<_ChartData, double>(
              dataSource: _chartData,
              xValueMapper: (_ChartData data, _) => data.x,
              yValueMapper: (_ChartData data, _) => data.y,
              width: 0.8, // Adjust bar width (0.0 to 1.0)
              color: widget.barColor,
              borderRadius: BorderRadius.zero, // Square corners
              animationDuration: 0,
              // Enable touch interaction for tooltips
              enableTooltip: true,
            ),
          ],
          tooltipBehavior: _tooltipBehavior,
        ),
      ),
    );
  }
}

// Sample widget to display the chart, if needed for testing
class BarChartSample extends StatelessWidget {
  const BarChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child:
            MyBarChart(barColor: Colors.teal), // Example with a different color
      ),
    );
  }
}
