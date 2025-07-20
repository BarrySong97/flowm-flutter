import 'package:flutter/material.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';

enum PeriodRange {
  week('周', 'W'),
  month('月', 'M'),
  year('年', 'Y'),
  all('全部', 'ALL'),
  range('范围', 'RANGE');

  const PeriodRange(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

class PeriodRangeSelector extends StatelessWidget {
  final PeriodRange value;
  final ValueChanged<PeriodRange> onChanged;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const PeriodRangeSelector({
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
      child: CustomSlidingSegmentedControl<PeriodRange>(
        initialValue: value,
        children: {
          for (PeriodRange periodRange in PeriodRange.values)
            periodRange: Container(
              alignment: Alignment.center,
              child: Text(
                periodRange.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        },
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
        thumbDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
