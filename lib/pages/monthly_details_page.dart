import 'package:flutter/material.dart';
import 'package:flowm/components/charts/flchart_income_expense_chart.dart';
import 'package:flowm/components/common/period_range_selector.dart';

class MonthlyDetailsPage extends StatefulWidget {
  final String month;
  
  const MonthlyDetailsPage({
    super.key,
    required this.month,
  });

  @override
  State<MonthlyDetailsPage> createState() => _MonthlyDetailsPageState();
}

class _MonthlyDetailsPageState extends State<MonthlyDetailsPage> {
  PeriodRange _selectedPeriodRange = PeriodRange.month;

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
              PeriodRangeSelector(
                value: _selectedPeriodRange,
                onChanged: (PeriodRange periodRange) {
                  setState(() {
                    _selectedPeriodRange = periodRange;
                  });
                },
                padding: const EdgeInsets.all(0),
                height: 45,
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
                          Text(
                            _getChartTitle(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
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
                    FlchartIncomeExpenseChart(
                      monthlyData: generateSampleMonthlyData(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Summary Section
              Container(
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
                      _getSummaryTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(_getSummaryExpenseLabel(), '¥45,600', Colors.red[400]!),
                    const SizedBox(height: 12),
                    _buildSummaryRow(_getSummaryIncomeLabel(), '¥38,400', Colors.green[400]!),
                    const SizedBox(height: 12),
                    _buildSummaryRow('净支出', '¥7,200', Colors.orange[400]!),
                    const SizedBox(height: 16),
                    const Text(
                      '注：数据为示例数据，实际数据将来自您的财务记录。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedPeriodRange) {
      case PeriodRange.week:
        return '周收支对比';
      case PeriodRange.month:
        return '月度收支对比';
      case PeriodRange.year:
        return '年度收支对比';
      case PeriodRange.all:
        return '全时段收支对比';
      case PeriodRange.range:
        return '自定义范围收支对比';
    }
  }

  String _getSummaryTitle() {
    switch (_selectedPeriodRange) {
      case PeriodRange.week:
        return '本周收支摘要';
      case PeriodRange.month:
        return '本月收支摘要';
      case PeriodRange.year:
        return '本年收支摘要';
      case PeriodRange.all:
        return '全时段收支摘要';
      case PeriodRange.range:
        return '自定义范围收支摘要';
    }
  }

  String _getSummaryExpenseLabel() {
    switch (_selectedPeriodRange) {
      case PeriodRange.week:
        return '本周总支出';
      case PeriodRange.month:
        return '本月总支出';
      case PeriodRange.year:
        return '本年总支出';
      case PeriodRange.all:
        return '总支出';
      case PeriodRange.range:
        return '范围内总支出';
    }
  }

  String _getSummaryIncomeLabel() {
    switch (_selectedPeriodRange) {
      case PeriodRange.week:
        return '本周总收入';
      case PeriodRange.month:
        return '本月总收入';
      case PeriodRange.year:
        return '本年总收入';
      case PeriodRange.all:
        return '总收入';
      case PeriodRange.range:
        return '范围内总收入';
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
}