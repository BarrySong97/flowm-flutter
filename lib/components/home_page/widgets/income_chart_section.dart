import 'package:flutter/material.dart';
import '../../chart/barchart.dart' as barchart;
import '../../../config/app_constants.dart';
import '../../../state/icome/income_providers.dart';

/// 收入图表组件
class IncomeChartSection extends StatelessWidget {
  final IncomePageData data;

  const IncomeChartSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.chartHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: barchart.MyBarChart(
        barColor: Colors.green,
        chartData: data.currentMonthChartData,
      ),
    );
  }
}
