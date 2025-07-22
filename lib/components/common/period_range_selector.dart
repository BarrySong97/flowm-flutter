import 'package:flutter/material.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';

enum PeriodRange {
  week('周', 'W'),
  month('月', 'M'),
  year('年', 'Y'),
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
  final DateTimeRange? customRange;
  final ValueChanged<DateTimeRange>? onCustomRangeChanged;

  const PeriodRangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 40,
    this.customRange,
    this.onCustomRangeChanged,
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
        onValueChanged: (selectedValue) {
          if (selectedValue == PeriodRange.range) {
            _showDateRangePicker(context);
          } else {
            onChanged(selectedValue);
          }
        },
        innerPadding: const EdgeInsets.all(2),
        isStretch: true,
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateRangePickerSheet(
        initialRange: customRange,
        onRangeSelected: (range) {
          onCustomRangeChanged?.call(range);
          onChanged(PeriodRange.range);
        },
      ),
    );
  }
}

class _DateRangePickerSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange> onRangeSelected;

  const _DateRangePickerSheet({
    required this.onRangeSelected,
    this.initialRange,
  });

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      startDate = widget.initialRange!.start;
      endDate = widget.initialRange!.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '选择时间范围',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            
            // Date selection buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Start date
                  Row(
                    children: [
                      const Text(
                        '开始日期：',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _selectStartDate(context),
                          child: Text(
                            startDate != null
                                ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                                : '选择开始日期',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // End date
                  Row(
                    children: [
                      const Text(
                        '结束日期：',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _selectEndDate(context),
                          child: Text(
                            endDate != null
                                ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
                                : '选择结束日期',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _canConfirm() ? _confirm : null,
                      child: const Text(
                        '确定',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: endDate ?? DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        startDate = picked;
        // 如果结束日期早于开始日期，清除结束日期
        if (endDate != null && endDate!.isBefore(picked)) {
          endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  bool _canConfirm() {
    return startDate != null && endDate != null && !endDate!.isBefore(startDate!);
  }

  void _confirm() {
    if (_canConfirm()) {
      widget.onRangeSelected(DateTimeRange(start: startDate!, end: endDate!));
      Navigator.pop(context);
    }
  }
}
