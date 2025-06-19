import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../state/liabilities/liabilities_repository.dart';

/// 负债趋势线图组件
///
/// 显示负债变化趋势，数据通过参数传入
class LiabilityTrendChart extends StatelessWidget {
  final List<LiabilityHistoryData> liabilityData;
  const LiabilityTrendChart({super.key, required this.liabilityData});

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
          final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

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
              // 折线图+面积图组合展示
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
                    primaryColor.withOpacity(0.3),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderColor: primaryColor,
                borderWidth: 2,
              ),
              // 添加折线和数据点
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
                      color: Colors.white.withOpacity(0.9),
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
                          '${formatter.format(currentY)}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$formattedDate',
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
