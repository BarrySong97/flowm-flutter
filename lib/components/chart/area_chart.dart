import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Data structure for points that need special highlighting or labels
class HighlightedPoint {
  final double x;
  final double y;
  final String label;
  final bool showDottedLine;
  final bool labelAbove; // To guide potential label placement
  final Color pointColor;

  HighlightedPoint({
    required this.x,
    required this.y,
    required this.label,
    this.showDottedLine = false,
    this.labelAbove = true,
    this.pointColor = const Color(0xFF22C5C2), // Default to primary teal
  });
}

class AreaChartWidget extends StatelessWidget {
  const AreaChartWidget({super.key});

  // Helper function to build styled labels similar to the image.
  // These would typically be used with a Stack and Positioned widgets for precise placement on the chart.

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF22C5C2); // Teal color from image
    final Color areaFillColor = primaryColor.withOpacity(0.25);
    final Color titleHeaderColor =
        Theme.of(context).textTheme.titleMedium?.color ?? Colors.black87;
    final Color mainValueColor =
        Theme.of(context).textTheme.displaySmall?.color ?? Colors.black;
    final Color faintLineColor = Colors.grey.withOpacity(0.5);

    // Mock data points for the chart's curve
    final List<FlSpot> spots = [
      const FlSpot(0, 4.5),
      const FlSpot(1, 3.8),
      const FlSpot(2, 2.0), // Visually aligns with the "70282.12" point
      const FlSpot(2.8, 3.5),
      const FlSpot(4, 5.0), // Visually aligns with the "74699.20" point
      const FlSpot(5, 6.2),
      const FlSpot(6, 7.0), // Visually aligns with the "33729.51" peak
      const FlSpot(7, 5.8),
      const FlSpot(8, 6.5),
      const FlSpot(9, 5.2),
      const FlSpot(10, 5.8),
    ];

    // Define the points to be highlighted on the chart
    final List<HighlightedPoint> highlightedPoints = [
      HighlightedPoint(
          x: 2,
          y: 2.0,
          label: '70282.12',
          showDottedLine: false,
          labelAbove: false),
      HighlightedPoint(
          x: 4,
          y: 5.0,
          label: '74699.20',
          showDottedLine: true,
          labelAbove: true),
      HighlightedPoint(
          x: 6,
          y: 7.0,
          label: '33729.51',
          showDottedLine: true,
          labelAbove: true),
    ];

    return Container(
      child: AspectRatio(
        aspectRatio: 3, // Adjust based on desired chart proportions
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 10,
            minY: 0,
            maxY: 8, // Adjusted to fit the data range comfortably
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: primaryColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: false,
                  checkToShowDot: (spot, barData) {
                    // Show dots only for our defined highlighted points
                    return highlightedPoints
                        .any((p) => p.x == spot.x && p.y == spot.y);
                  },
                  getDotPainter: (spot, percent, barData, index) {
                    // Custom painter for the dots on highlighted points
                    return FlDotCirclePainter(
                      radius: 5,
                      color: primaryColor,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: areaFillColor,
                ),
              ),
            ],
            titlesData:
                const FlTitlesData(show: false), // Hide axis titles and labels
            borderData: FlBorderData(show: false), // Hide chart border
            gridData: const FlGridData(show: false), // Hide grid lines
            extraLinesData: ExtraLinesData(
              verticalLines: [],
            ),
            lineTouchData: LineTouchData(enabled: false),
          ),
        ),
      ),
    );
  }
}
