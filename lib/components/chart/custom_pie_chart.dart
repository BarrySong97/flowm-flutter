import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Define a model class for chart data
class ChartData {
  ChartData(this.x, this.y, this.percentage, [this.color]);
  final String x;
  final double y;
  final double percentage; // Added percentage
  final Color? color;
}

class CustomPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> expenseData;

  const CustomPieChart({super.key, required this.expenseData});

  @override
  Widget build(BuildContext context) {
    // Filter and transform data for the pie chart
    final List<Map<String, dynamic>> validExpenseData = expenseData
        .where((item) =>
            item['amount'] is num &&
            (item['amount'] as num) > 0 &&
            item['category'] is String &&
            (item['category'] as String).isNotEmpty)
        .toList();

    if (validExpenseData.isEmpty) {
      return const Center(child: Text('No data to display.'));
    }

    // Calculate total amount for percentage calculation
    final double totalAmount = validExpenseData.fold(
        0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

    final List<ChartData> chartDataSource = validExpenseData.map((item) {
      final amount = (item['amount'] as num).toDouble();
      final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
      return ChartData(
        item['category'] as String,
        amount,
        percentage, // Pass percentage
        item['color'] as Color?,
      );
    }).toList();

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
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            // Attempt to show all labels, even if they might overlap initially
            labelIntersectAction: LabelIntersectAction.none,
            connectorLineSettings: const ConnectorLineSettings(
              type: ConnectorType.line,
              length: '5%', // Increased connector line length
            ),
            builder: (dynamic data, dynamic point, dynamic series,
                int pointIndex, int seriesIndex) {
              final chartData = data as ChartData;
              // Consider truncating long account names if still an issue
              String displayName = chartData.x;
              // Example truncation: if (displayName.length > 10) {
              //   displayName = '${displayName.substring(0, 8)}...';
              // }
              return Text(
                '$displayName ${chartData.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          enableTooltip: true,
          // Explode a slice on tap, if desired
          // explode: true,
          // explodeIndex: 0, // Explode the first slice by default
        )
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        // Use builder for custom tooltip content
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          final chartData = data as ChartData;
          // Assuming a currency symbol, replace '¥' with your actual symbol or logic
          final String currencySymbol = '¥';
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800], // Tooltip background color
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chartData.x, // Account name
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol${chartData.y.toStringAsFixed(2)} (${chartData.percentage.toStringAsFixed(0)}%)', // Amount and percentage
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
