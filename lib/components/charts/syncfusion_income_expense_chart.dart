import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class MonthlyComparisonData {
  MonthlyComparisonData(this.month, this.expense, this.income);
  final String month;
  final double expense;
  final double income;
}

class ChartDataPoint {
  ChartDataPoint(this.month, this.value, this.type);
  final String month;
  final double value;
  final String type; // 'expense' or 'income'
}

class SyncfusionIncomeExpenseChart extends StatefulWidget {
  const SyncfusionIncomeExpenseChart({
    super.key,
    required this.monthlyData,
  });

  final List<MonthlyComparisonData> monthlyData;

  @override
  State<SyncfusionIncomeExpenseChart> createState() => _SyncfusionIncomeExpenseChartState();
}

class _SyncfusionIncomeExpenseChartState extends State<SyncfusionIncomeExpenseChart> {
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      header: '',
      canShowMarker: false,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
        final chartPoint = data as ChartDataPoint;
        final value = chartPoint.value.abs();
        final type = chartPoint.type == 'expense' ? '支出' : '收入';
        
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${chartPoint.month}$type',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                NumberFormat.compact().format(value),
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyData.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(child: Text('暂无数据')),
      );
    }

    // 转换数据格式，创建包含正负值的单一数据集
    final List<ChartDataPoint> chartData = [];
    for (var data in widget.monthlyData) {
      chartData.add(ChartDataPoint(data.month, data.expense, 'expense'));
      chartData.add(ChartDataPoint(data.month, -data.income, 'income'));
    }

    final double expenseMaxY = widget.monthlyData.map((e) => e.expense).reduce((a, b) => a > b ? a : b);
    final double incomeMaxY = widget.monthlyData.map((e) => e.income).reduce((a, b) => a > b ? a : b);
    final double dataMaxY = expenseMaxY > incomeMaxY ? expenseMaxY : incomeMaxY;
    final double maxY = dataMaxY * 1.2;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            labelStyle: const TextStyle(color: Color(0xff7589a2), fontSize: 12),
            majorTickLines: const MajorTickLines(size: 0),
            interval: 2, // 每隔一个月显示标签
          ),
          primaryYAxis: NumericAxis(
            minimum: -maxY,
            maximum: maxY,
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            labelStyle: const TextStyle(color: Color(0xff7589a2), fontSize: 12),
            majorTickLines: const MajorTickLines(size: 0),
            numberFormat: NumberFormat.compact(),
            axisLabelFormatter: (AxisLabelRenderDetails args) {
              // 隐藏0值标签，显示其他值的绝对值
              if (args.value == 0) {
                return ChartAxisLabel('', args.textStyle);
              }
              return ChartAxisLabel(
                NumberFormat.compact().format(args.value.abs()),
                args.textStyle,
              );
            },
            plotBands: <PlotBand>[
              // 添加中轴线
              PlotBand(
                start: 0,
                end: 0,
                borderWidth: 1,
                borderColor: Colors.grey[400]!,
              ),
            ],
          ),
          series: <CartesianSeries>[
            // 使用单一系列但通过 pointColorMapper 来区分颜色
            ColumnSeries<ChartDataPoint, String>(
              dataSource: chartData,
              xValueMapper: (ChartDataPoint data, _) => data.month,
              yValueMapper: (ChartDataPoint data, _) => data.value,
              pointColorMapper: (ChartDataPoint data, _) {
                return data.type == 'expense' 
                    ? const Color(0xfff85544) 
                    : const Color(0xff34C759);
              },
              width: 0.5,
              borderRadius: BorderRadius.zero,
              animationDuration: 500,
              enableTooltip: true,
            ),
          ],
          tooltipBehavior: _tooltipBehavior,
        ),
      ),
    );
  }

}

// 生成示例数据的独立函数
List<MonthlyComparisonData> generateSampleMonthlyData() {
  return List.generate(12, (index) {
    final expense = (index + 1) * 1000.0 + (index % 3) * 500;
    final income = (index + 1) * 800.0 + (index % 4) * 300;
    return MonthlyComparisonData('${index + 1}月', expense, income);
  });
}