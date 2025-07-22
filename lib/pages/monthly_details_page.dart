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
                  return PeriodRangeSelector(
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
                          data: (comparisonData) => FlchartIncomeExpenseChart(
                            monthlyData: comparisonData.monthlyData,
                            periodRange: comparisonData.periodRange.shortLabel,
                          ),
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
                      final netAmount = totalExpense - totalIncome;

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
                              '净支出',
                              '¥${_formatAmount(netAmount)}',
                              netAmount > 0
                                  ? Colors.orange[400]!
                                  : Colors.blue[400]!,
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
          return '${daysDifference}天总支出';
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
          return '${daysDifference}天总收入';
        }
        return '自定义总收入';
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
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
}
