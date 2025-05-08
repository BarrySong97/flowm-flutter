import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Define a model class for chart data
class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color? color;
}

class CustomPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> expenseData;

  const CustomPieChart({super.key, required this.expenseData});

  @override
  Widget build(BuildContext context) {
    // Filter and transform data for the pie chart
    // We only want positive amounts and valid categories
    final List<ChartData> chartDataSource = expenseData
        .where((item) =>
            item['amount'] is num &&
            (item['amount'] as num) > 0 &&
            item['category'] is String &&
            (item['category'] as String).isNotEmpty)
        .map((item) => ChartData(
              item['category'] as String,
              (item['amount'] as num).toDouble(),
              item['color'] as Color?, // Use the color from expenseData
            ))
        .toList();

    if (chartDataSource.isEmpty) {
      return const Center(child: Text('No data to display.'));
    }

    return SfCircularChart(
      // title: ChartTitle(text: 'Expense Distribution'), // Optional: Add a title
      legend: const Legend(
        isVisible: false, // Set isVisible to false to hide the legend
        overflowMode: LegendItemOverflowMode.wrap, // Handles many legend items
        position: LegendPosition.bottom,
      ),
      series: <CircularSeries>[
        DoughnutSeries<ChartData, String>(
          dataSource: chartDataSource,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          innerRadius: '60%', // Makes it a doughnut chart
          pointColorMapper: (ChartData data, _) =>
              data.color, // Map color for each slice
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition:
                ChartDataLabelPosition.outside, // Position labels outside
            connectorLineSettings: ConnectorLineSettings(
              type: ConnectorType.line, // Use straight connector lines
              length: '10%', // Adjust connector line length
            ),
            // Consider using a builder for more complex label formatting if needed
            // e.g., to show percentage or trim long labels
          ),
          enableTooltip: true,
          // Explode a slice on tap, if desired
          // explode: true,
          // explodeIndex: 0, // Explode the first slice by default
        )
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }
}
