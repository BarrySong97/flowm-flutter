import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowm/components/charts/flchart_income_expense_chart.dart';
import 'package:flowm/components/common/period_range_selector.dart';
import 'package:flowm/state/comparison/comparison_providers.dart';

class MonthlyDetailsPage extends ConsumerStatefulWidget {
  final String month;

  const MonthlyDetailsPage({
    super.key,
    required this.month,
  });

  @override
  ConsumerState<MonthlyDetailsPage> createState() => _MonthlyDetailsPageState();
}

class _MonthlyDetailsPageState extends ConsumerState<MonthlyDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        title: const Text(
          '支出收入对比详情',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFFF5F6FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Range Selector
              Consumer(
                builder: (context, ref, child) {
                  final selectedPeriodRange = ref.watch(periodRangeProvider);
                  final customRange = ref.watch(customDateRangeProvider);
                  return Column(
                    children: [
                      PeriodRangeSelector(
                        value: selectedPeriodRange,
                        customRange: customRange,
                        onChanged: (PeriodRange periodRange) {
                          ref.read(periodRangeProvider.notifier).state =
                              periodRange;
                        },
                        onCustomRangeChanged: (DateTimeRange range) {
                          ref.read(customDateRangeProvider.notifier).state = range;
                        },
                        padding: const EdgeInsets.all(0),
                        height: 45,
                      ),
                      const SizedBox(height: 12),
                      // Period Navigation Buttons
                      _buildPeriodNavigationButtons(ref, selectedPeriodRange, customRange),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Chart Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final selectedPeriodRange =
                                  ref.watch(periodRangeProvider);
                              final customRange =
                                  ref.watch(customDateRangeProvider);
                              return Text(
                                _getChartTitle(
                                    selectedPeriodRange, customRange),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '支出',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '收入',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final comparisonDataAsync =
                            ref.watch(comparisonDataProvider);

                        return comparisonDataAsync.when(
                          data: (comparisonData) {
                            final selectedPeriodRange = ref.watch(periodRangeProvider);
                            final customRange = ref.watch(customDateRangeProvider);
                            DateTimeRange? effectiveRange;
                            
                            // Determine the effective date range for the chart
                            if (selectedPeriodRange == PeriodRange.range && customRange != null) {
                              effectiveRange = customRange;
                            }
                            
                            return FlchartIncomeExpenseChart(
                              monthlyData: comparisonData.monthlyData,
                              periodRange: comparisonData.periodRange.shortLabel,
                              dateRange: effectiveRange,
                            );
                          },
                          loading: () => const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => SizedBox(
                            height: 200,
                            child: Center(
                              child: Text('加载数据失败: $error'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Section
              Consumer(
                builder: (context, ref, child) {
                  final comparisonDataAsync = ref.watch(comparisonDataProvider);
                  final selectedPeriodRange = ref.watch(periodRangeProvider);

                  return comparisonDataAsync.when(
                    data: (comparisonData) {
                      final totalExpense = comparisonData.monthlyData.fold(
                        0.0,
                        (sum, data) => sum + data.expense,
                      );
                      final totalIncome = comparisonData.monthlyData.fold(
                        0.0,
                        (sum, data) => sum + data.income,
                      );
                      final netAmount = totalIncome - totalExpense;

                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getSummaryTitle(
                                  selectedPeriodRange,
                                  comparisonData.periodRange ==
                                          PeriodRange.range
                                      ? ref.watch(customDateRangeProvider)
                                      : null),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow(
                              _getSummaryExpenseLabel(
                                  selectedPeriodRange,
                                  comparisonData.periodRange ==
                                          PeriodRange.range
                                      ? ref.watch(customDateRangeProvider)
                                      : null),
                              '¥${_formatAmount(totalExpense)}',
                              Colors.red[400]!,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              _getSummaryIncomeLabel(
                                  selectedPeriodRange,
                                  comparisonData.periodRange ==
                                          PeriodRange.range
                                      ? ref.watch(customDateRangeProvider)
                                      : null),
                              '¥${_formatAmount(totalIncome)}',
                              Colors.green[400]!,
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              '净收入',
                              '¥${_formatAmount(netAmount)}',
                              netAmount > 0
                                  ? Colors.blue[400]!
                                  : Colors.orange[400]!,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Center(
                        child: Text('加载汇总数据失败: $error'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChartTitle(PeriodRange periodRange, DateTimeRange? customRange) {
    switch (periodRange) {
      case PeriodRange.week:
        return '周收支对比';
      case PeriodRange.month:
        return '月度收支对比';
      case PeriodRange.year:
        return '年度收支对比';
      case PeriodRange.range:
        if (customRange != null) {
          final startStr =
              '${customRange.start.year}-${customRange.start.month.toString().padLeft(2, '0')}-${customRange.start.day.toString().padLeft(2, '0')}';
          final endStr =
              '${customRange.end.year}-${customRange.end.month.toString().padLeft(2, '0')}-${customRange.end.day.toString().padLeft(2, '0')}';
          return '$startStr至$endStr收支对比';
        }
        return '自定义范围收支对比';
    }
  }

  String _getSummaryTitle(PeriodRange periodRange, DateTimeRange? customRange) {
    switch (periodRange) {
      case PeriodRange.week:
        return '本周收支摘要';
      case PeriodRange.month:
        return '本月收支摘要';
      case PeriodRange.year:
        return '本年收支摘要';
      case PeriodRange.range:
        if (customRange != null) {
          final startStr =
              '${customRange.start.year}-${customRange.start.month.toString().padLeft(2, '0')}-${customRange.start.day.toString().padLeft(2, '0')}';
          final endStr =
              '${customRange.end.year}-${customRange.end.month.toString().padLeft(2, '0')}-${customRange.end.day.toString().padLeft(2, '0')}';
          return '$startStr至$endStr收支摘要';
        }
        return '自定义范围收支摘要';
    }
  }

  String _getSummaryExpenseLabel(
      PeriodRange periodRange, DateTimeRange? customRange) {
    switch (periodRange) {
      case PeriodRange.week:
        return '本周总支出';
      case PeriodRange.month:
        return '本月总支出';
      case PeriodRange.year:
        return '本年总支出';
      case PeriodRange.range:
        if (customRange != null) {
          final daysDifference =
              customRange.end.difference(customRange.start).inDays + 1;
          return '$daysDifference天总支出';
        }
        return '自定义总支出';
    }
  }

  String _getSummaryIncomeLabel(
      PeriodRange periodRange, DateTimeRange? customRange) {
    switch (periodRange) {
      case PeriodRange.week:
        return '本周总收入';
      case PeriodRange.month:
        return '本月总收入';
      case PeriodRange.year:
        return '本年总收入';
      case PeriodRange.range:
        if (customRange != null) {
          final daysDifference =
              customRange.end.difference(customRange.start).inDays + 1;
          return '$daysDifference天总收入';
        }
        return '自定义总收入';
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  Widget _buildPeriodNavigationButtons(WidgetRef ref, PeriodRange selectedRange, DateTimeRange? customRange) {
    final canNavigateNext = _canNavigateToNext(selectedRange, customRange);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous period button
          GestureDetector(
            onTap: () => _navigateToPreviousPeriod(ref, selectedRange, customRange),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.arrow_back_ios_outlined,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          // Current period text
          Expanded(
            child: Center(
              child: Text(
                _getCurrentPeriodText(selectedRange, customRange),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Next period button
          GestureDetector(
            onTap: canNavigateNext ? () => _navigateToNextPeriod(ref, selectedRange, customRange) : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                size: 16,
                color: canNavigateNext ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canNavigateToNext(PeriodRange selectedRange, DateTimeRange? customRange) {
    switch (selectedRange) {
      case PeriodRange.week:
      case PeriodRange.month: 
      case PeriodRange.year:
        final currentRange = _getCurrentRangeForPeriod(selectedRange);
        return _getNextRange(selectedRange, currentRange) != null;
      case PeriodRange.range:
        final baseRange = customRange ?? _getCurrentRangeForPeriod(PeriodRange.week);
        
        // Check if this is a month-like range
        if (_isMonthRange(baseRange)) {
          return _getNextRange(PeriodRange.month, baseRange) != null;
        } 
        // Check if this is a year-like range
        else if (_isYearRange(baseRange)) {
          return _getNextRange(PeriodRange.year, baseRange) != null;
        }
        // Otherwise use generic range logic
        else {
          final baseEndDay = DateTime(baseRange.end.year, baseRange.end.month, baseRange.end.day);
          final newStartDate = baseEndDay.add(const Duration(days: 1));
          final today = DateTime.now();
          final todayNormalized = DateTime(today.year, today.month, today.day);
          return !newStartDate.isAfter(todayNormalized);
        }
    }
  }

  String _getCurrentPeriodText(PeriodRange selectedRange, DateTimeRange? customRange) {
    // For range mode, show the actual custom range
    if (selectedRange == PeriodRange.range && customRange != null) {
      final start = customRange.start;
      final end = customRange.end;
      
      // Check if it's a week range (7 days)
      final daysDiff = end.difference(start).inDays + 1;
      if (daysDiff == 7) {
        return '${start.month}/${start.day} - ${end.month}/${end.day}';
      }
      
      // Check if it's a month range
      if (start.day == 1) {
        final nextMonthStart = DateTime(start.year, start.month + 1, 1);
        final lastDayOfMonth = nextMonthStart.subtract(const Duration(days: 1));
        if (end.year == lastDayOfMonth.year && 
            end.month == lastDayOfMonth.month && 
            end.day == lastDayOfMonth.day) {
          return '${start.year}年${start.month}月';
        }
      }
      
      // Check if it's a year range
      if (start.month == 1 && start.day == 1 && 
          end.month == 12 && end.day == 31 && 
          start.year == end.year) {
        return '${start.year}年';
      }
      
      // Default custom range format
      final startStr = '${start.month}/${start.day}';
      final endStr = '${end.month}/${end.day}';
      return '$startStr - $endStr';
    }
    
    // For other modes, show the default current period
    final now = DateTime.now();
    switch (selectedRange) {
      case PeriodRange.week:
        final weekStart = now.subtract(const Duration(days: 6));
        return '${weekStart.month}/${weekStart.day} - ${now.month}/${now.day}';
      case PeriodRange.month:
        return '${now.year}年${now.month}月';
      case PeriodRange.year:
        return '${now.year}年';
      case PeriodRange.range:
        return '自定义范围';
    }
  }

  void _navigateToPreviousPeriod(WidgetRef ref, PeriodRange selectedRange, DateTimeRange? customRange) {
    switch (selectedRange) {
      case PeriodRange.week:
      case PeriodRange.month: 
      case PeriodRange.year:
        // For built-in ranges, we temporarily switch to range mode to navigate
        final currentRange = _getCurrentRangeForPeriod(selectedRange);
        final newRange = _getPreviousRange(selectedRange, currentRange);
        ref.read(periodRangeProvider.notifier).state = PeriodRange.range;
        ref.read(customDateRangeProvider.notifier).state = newRange;
        break;
      case PeriodRange.range:
        // If no custom range set, use current period as base
        final baseRange = customRange ?? _getCurrentRangeForPeriod(PeriodRange.week);
        
        // Check if this is a month-like range (starts on 1st, ends on last day of month)
        if (_isMonthRange(baseRange)) {
          final newRange = _getPreviousRange(PeriodRange.month, baseRange);
          ref.read(customDateRangeProvider.notifier).state = newRange;
        } 
        // Check if this is a year-like range (starts on Jan 1st, ends on Dec 31st)
        else if (_isYearRange(baseRange)) {
          final newRange = _getPreviousRange(PeriodRange.year, baseRange);
          ref.read(customDateRangeProvider.notifier).state = newRange;
        }
        // Otherwise use generic range logic
        else {
          final daysDifference = baseRange.end.difference(baseRange.start).inDays + 1;
          final baseStartDay = DateTime(baseRange.start.year, baseRange.start.month, baseRange.start.day);
          final newEndDate = baseStartDay.subtract(const Duration(days: 1));
          final newStartDate = newEndDate.subtract(Duration(days: daysDifference - 1));
          final newRange = DateTimeRange(start: newStartDate, end: newEndDate);
          ref.read(customDateRangeProvider.notifier).state = newRange;
        }
        break;
    }
  }

  void _navigateToNextPeriod(WidgetRef ref, PeriodRange selectedRange, DateTimeRange? customRange) {
    switch (selectedRange) {
      case PeriodRange.week:
      case PeriodRange.month: 
      case PeriodRange.year:
        // For built-in ranges, we temporarily switch to range mode to navigate
        final currentRange = _getCurrentRangeForPeriod(selectedRange);
        final newRange = _getNextRange(selectedRange, currentRange);
        if (newRange != null) {
          ref.read(periodRangeProvider.notifier).state = PeriodRange.range;
          ref.read(customDateRangeProvider.notifier).state = newRange;
        }
        break;
      case PeriodRange.range:
        // If no custom range set, use current period as base
        final baseRange = customRange ?? _getCurrentRangeForPeriod(PeriodRange.week);
        
        // Check if this is a month-like range (starts on 1st, ends on last day of month)
        if (_isMonthRange(baseRange)) {
          final newRange = _getNextRange(PeriodRange.month, baseRange);
          if (newRange != null) {
            ref.read(customDateRangeProvider.notifier).state = newRange;
          }
        } 
        // Check if this is a year-like range (starts on Jan 1st, ends on Dec 31st)
        else if (_isYearRange(baseRange)) {
          final newRange = _getNextRange(PeriodRange.year, baseRange);
          if (newRange != null) {
            ref.read(customDateRangeProvider.notifier).state = newRange;
          }
        }
        // Otherwise use generic range logic
        else {
          final daysDifference = baseRange.end.difference(baseRange.start).inDays + 1;
          final baseEndDay = DateTime(baseRange.end.year, baseRange.end.month, baseRange.end.day);
          final newStartDate = baseEndDay.add(const Duration(days: 1));
          final newEndDate = newStartDate.add(Duration(days: daysDifference - 1));
          
          // Don't go beyond current date
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          if (newStartDate.isAfter(today)) {
            return;
          }
          
          final adjustedEnd = newEndDate.isAfter(today) ? today : newEndDate;
          final newRange = DateTimeRange(start: newStartDate, end: adjustedEnd);
          ref.read(customDateRangeProvider.notifier).state = newRange;
        }
        break;
    }
  }

  DateTimeRange _getCurrentRangeForPeriod(PeriodRange periodRange) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (periodRange) {
      case PeriodRange.week:
        final weekStart = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: weekStart, end: today);
      case PeriodRange.month:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: monthStart, end: monthEnd);
      case PeriodRange.year:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31);
        return DateTimeRange(start: yearStart, end: yearEnd);
      case PeriodRange.range:
        return DateTimeRange(start: today, end: today);
    }
  }

  DateTimeRange _getPreviousRange(PeriodRange periodRange, DateTimeRange currentRange) {
    switch (periodRange) {
      case PeriodRange.week:
        // Get the day before the current range start, normalize to day precision
        final currentStartDay = DateTime(currentRange.start.year, currentRange.start.month, currentRange.start.day);
        final newEnd = currentStartDay.subtract(const Duration(days: 1));
        final newStart = newEnd.subtract(const Duration(days: 6));
        return DateTimeRange(start: newStart, end: newEnd);
      case PeriodRange.month:
        final currentMonth = currentRange.start.month;
        final currentYear = currentRange.start.year;
        final previousMonth = currentMonth == 1 ? 12 : currentMonth - 1;
        final previousYear = currentMonth == 1 ? currentYear - 1 : currentYear;
        final newStart = DateTime(previousYear, previousMonth, 1);
        final newEnd = DateTime(previousYear, previousMonth + 1, 0);
        return DateTimeRange(start: newStart, end: newEnd);
      case PeriodRange.year:
        final previousYear = currentRange.start.year - 1;
        final newStart = DateTime(previousYear, 1, 1);
        final newEnd = DateTime(previousYear, 12, 31);
        return DateTimeRange(start: newStart, end: newEnd);
      case PeriodRange.range:
        return currentRange;
    }
  }

  DateTimeRange? _getNextRange(PeriodRange periodRange, DateTimeRange currentRange) {
    final now = DateTime.now();
    
    switch (periodRange) {
      case PeriodRange.week:
        // Get the day after the current range end, but normalize to start of day
        final currentEndDay = DateTime(currentRange.end.year, currentRange.end.month, currentRange.end.day);
        final newStart = currentEndDay.add(const Duration(days: 1));
        final newEnd = newStart.add(const Duration(days: 6));
        // Allow navigation if new start is not after today
        final today = DateTime(now.year, now.month, now.day);
        if (newStart.isAfter(today)) return null;
        // If new end is after today, adjust to today
        final adjustedEnd = newEnd.isAfter(today) ? today : newEnd;
        return DateTimeRange(start: newStart, end: adjustedEnd);
      case PeriodRange.month:
        final currentMonth = currentRange.start.month;
        final currentYear = currentRange.start.year;
        final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
        final nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;
        
        // Allow navigation if the next month has started
        final nextMonthStart = DateTime(nextYear, nextMonth, 1);
        final today = DateTime(now.year, now.month, now.day);
        if (nextMonthStart.isAfter(today)) {
          return null;
        }
        
        final newStart = DateTime(nextYear, nextMonth, 1);
        final newEnd = DateTime(nextYear, nextMonth + 1, 0);
        // If new end is after today, adjust to today
        final adjustedEnd = newEnd.isAfter(today) ? today : newEnd;
        return DateTimeRange(start: newStart, end: adjustedEnd);
      case PeriodRange.year:
        final nextYear = currentRange.start.year + 1;
        final nextYearStart = DateTime(nextYear, 1, 1);
        final today = DateTime(now.year, now.month, now.day);
        if (nextYearStart.isAfter(today)) return null;
        
        final newStart = DateTime(nextYear, 1, 1);
        final newEnd = DateTime(nextYear, 12, 31);
        // If new end is after today, adjust to today
        final adjustedEnd = newEnd.isAfter(today) ? today : newEnd;
        return DateTimeRange(start: newStart, end: adjustedEnd);
      case PeriodRange.range:
        return null;
    }
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  bool _isMonthRange(DateTimeRange range) {
    // Check if range starts on 1st of month and ends on last day of same month
    if (range.start.day != 1) return false;
    
    final expectedEnd = DateTime(range.start.year, range.start.month + 1, 0);
    return range.end.year == expectedEnd.year &&
           range.end.month == expectedEnd.month &&
           range.end.day == expectedEnd.day;
  }

  bool _isYearRange(DateTimeRange range) {
    // Check if range starts on Jan 1st and ends on Dec 31st of same year
    return range.start.month == 1 &&
           range.start.day == 1 &&
           range.end.month == 12 &&
           range.end.day == 31 &&
           range.start.year == range.end.year;
  }
}
