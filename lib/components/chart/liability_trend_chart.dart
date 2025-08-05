import 'package:flowm/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../state/liabilities/liabilities_repository.dart';
import '../../config/app_constants.dart';

/// 负债趋势线图组件
///
/// 显示负债变化趋势，数据通过参数传入
class LiabilityTrendChart extends StatelessWidget {
  final List<LiabilityHistoryData> liabilityData;
  final String currencySymbol;
  const LiabilityTrendChart(
      {super.key,
      required this.liabilityData,
      this.currencySymbol = AppConstants.currencySymbol});

  @override
  Widget build(BuildContext context) {
    // 定义图表主色调 - 使用红色系表示负债
    final Color primaryColor = Colors.redAccent;
    return Container(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 140,
        child: () {
          if (liabilityData.isEmpty) {
            return const Center(child: Text('暂无负债趋势数据'));
          }

          // 格式化货币显示
          final formatter =
              NumberFormat.currency(locale: 'zh_CN', symbol: currencySymbol);

          // 检测是否所有数据都为0
          final bool allDataIsZero =
              liabilityData.every((data) => data.totalLiabilities == 0.0);

          return SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.only(top: 12),
            primaryXAxis: CategoryAxis(
              isVisible: false,
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelPlacement: LabelPlacement.onTicks,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              axisLabelFormatter: (AxisLabelRenderDetails args) {
                final int currentIndex = args.value.toInt();
                final int totalCount = liabilityData.length;

                if (totalCount == 0) {
                  return ChartAxisLabel('', args.textStyle);
                }

                if (currentIndex == totalCount - 1) {
                  return ChartAxisLabel(args.text, args.textStyle);
                }
                return ChartAxisLabel('', args.textStyle);
              },
            ),
            primaryYAxis: NumericAxis(
              isVisible: false,
              numberFormat: NumberFormat.compact(locale: 'zh_CN'),
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              minimum: null,
              maximum: null,
              desiredIntervals: 1,
            ),
            series: <CartesianSeries>[
              // 根据数据情况选择图表类型
              if (allDataIsZero) ...[
                // 当所有数据为0时使用直线图
                LineSeries<LiabilityHistoryData, String>(
                  dataSource: liabilityData,
                  xValueMapper: (data, _) => data.formattedDate,
                  yValueMapper: (data, _) => data.totalLiabilities,
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ] else ...[
                // 有非零数据时使用样条曲线图
                SplineAreaSeries<LiabilityHistoryData, String>(
                  dataSource: liabilityData,
                  xValueMapper: (data, _) => data.formattedDate,
                  yValueMapper: (data, _) => data.totalLiabilities,
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
                  borderColor: primaryColor,
                  borderWidth: 2,
                ),
                SplineSeries<LiabilityHistoryData, String>(
                  dataSource: liabilityData,
                  xValueMapper: (data, _) => data.formattedDate,
                  yValueMapper: (data, _) => data.totalLiabilities,
                  color: primaryColor,
                  width: 2,
                  splineType: SplineType.cardinal,
                  cardinalSplineTension: 0.5,
                  markerSettings: const MarkerSettings(isVisible: false),
                ),
              ],
            ],
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              lineType: TrackballLineType.vertical,
              lineDashArray: <double>[5, 5],
              lineColor: Colors.black45,
              tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
              builder:
                  (BuildContext context, TrackballDetails trackballDetails) {
                final dynamic dataPoint = trackballDetails.point;
                if (dataPoint != null && dataPoint.y != null) {
                  final double currentY = dataPoint.y as double;
                  final String formattedDate = dataPoint.x as String;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatter.format(currentY),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        }(),
      ),
    );
  }
}
