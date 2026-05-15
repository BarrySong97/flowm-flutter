import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';

// Data model for chart points
class ChartData {
  final double x;
  final double y;

  ChartData(this.x, this.y);
}

class AreaChartWidget extends StatelessWidget {
  const AreaChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF22C5C2); // Teal color from image

    // Mock data points for the chart's curve
    final List<ChartData> chartData = [
      ChartData(0, 4.5),
      ChartData(1, 3.8),
      ChartData(2, 2.0),
      ChartData(2.8, 3.5),
      ChartData(4, 5.0),
      ChartData(5, 6.2),
      ChartData(6, 7.0),
      ChartData(7, 5.8),
      ChartData(8, 6.5),
      ChartData(9, 5.2),
      ChartData(10, 5.8),
    ];

    return Container(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 150, // Fixed height, adjust as needed
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: NumericAxis(
            minimum: 0,
            maximum: 10,
            isVisible: false, // Hide axis
            plotOffset: 0, // Remove any axis padding
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 8, // Adjusted to fit the data range comfortably
            isVisible: false, // Hide axis
            plotOffset: 0, // Remove any axis padding
          ),
          series: <CartesianSeries>[
            // SplineArea series for smoother filled area below the line
            SplineAreaSeries<ChartData, double>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              splineType: SplineType.cardinal,
              cardinalSplineTension: 0.5,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderColor: const Color(0xFF20AC65),
            ),
          ],
          tooltipBehavior: TooltipBehavior(enable: false),
        ),
      ),
    );
  }
}
