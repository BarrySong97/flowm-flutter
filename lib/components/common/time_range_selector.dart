import 'package:flutter/material.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';

enum TimeRange {
  thisMonth('本月', '1M'),
  this3Months('近60天', '3M'),
  this90Days('近90天', '90D'),
  thisYear('近一年', '1Y'),
  all('全部', 'ALL');

  const TimeRange(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

class TimeRangeSelector extends StatelessWidget {
  final TimeRange value;
  final ValueChanged<TimeRange> onChanged;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const TimeRangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      child: CustomSlidingSegmentedControl<TimeRange>(
        initialValue: value,
        children: {
          for (TimeRange timeRange in TimeRange.values)
            timeRange: Container(
              alignment: Alignment.center,
              child: Text(
                timeRange.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        },
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        thumbDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        onValueChanged: (value) {
          onChanged(value);
        },
        innerPadding: const EdgeInsets.all(2),
        isStretch: true,
      ),
    );
  }
}
