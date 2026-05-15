import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart'; // For number formatting

class ChartData {
  ChartData(this.x, this.y, this.day);
  final double x;
  final double y;
  final String day; // For tooltip
}

class MyBarChart extends StatefulWidget {
  const MyBarChart({
    super.key,
    this.barColor = Colors.blue,
    required this.chartData,
  });

  final Color barColor;
  final List<ChartData> chartData;

  @override
  State<StatefulWidget> createState() => MyBarChartState();
}

class MyBarChartState extends State<MyBarChart> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      header: '', // No header
      canShowMarker: false,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
          int seriesIndex) {
        final chartData = data as ChartData;
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
            minimum: -0.5, // Adjust for bars
            maximum: widget.chartData.length - 0.5, // Adjust for bars
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
            maximum: widget.chartData.isEmpty
                ? 20
                : widget.chartData
                        .map((e) => e.y)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
            interval: 10, // Set interval to 10 to get 0, 10, 20
            majorGridLines:
                const MajorGridLines(width: 0), // No horizontal grid lines
            axisLine: const AxisLine(width: 0), // No y-axis line
            labelStyle: const TextStyle(color: Color(0xff7589a2), fontSize: 12),
            majorTickLines: const MajorTickLines(size: 0), // No ticks
            numberFormat: NumberFormat.compact(), // For 10K, 20K
          ),
          series: <CartesianSeries>[
            // Column Series (Bar Chart)
            ColumnSeries<ChartData, double>(
              dataSource: widget.chartData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              width: 0.8, // Adjust bar width (0.0 to 1.0)
              color: widget.barColor,
              borderRadius: BorderRadius.zero, // Square corners
              animationDuration: 500,
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
        child: MyBarChart(
            barColor: Colors.teal,
            chartData: []), // Example with a different color
      ),
    );
  }
}
