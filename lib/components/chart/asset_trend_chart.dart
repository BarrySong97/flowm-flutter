import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../state/account/account_repository.dart'; // Still needed for AssetHistoryData type

/// 资产趋势线图组件
///
/// 显示资产变化趋势，数据通过参数传入
class AssetTrendChart extends StatelessWidget {
  final List<AssetHistoryData> assetData;
  const AssetTrendChart({super.key, required this.assetData});

  @override
  Widget build(BuildContext context) {
    // 定义图表主色调
    final Color primaryColor = const Color(0xFF22C5C2);

    return Container(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 200, // 固定高度，可根据需要调整
        child: () {
          if (assetData.isEmpty) {
            return const Center(child: Text('暂无资产趋势数据'));
          }

          // 格式化货币显示
          final formatter = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

          return SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.fromLTRB(10, 20, 10, 10),
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelPlacement: LabelPlacement.onTicks,
              axisLabelFormatter: (AxisLabelRenderDetails args) {
                // args.value is the index for CategoryAxis
                final int currentIndex = args.value.toInt();
                final int totalCount = assetData.length;

                if (totalCount == 0) {
                  // Handle empty data
                  return ChartAxisLabel('', args.textStyle);
                }

                // Only show the label for the last data point
                if (currentIndex == totalCount - 1) {
                  return ChartAxisLabel(args.text, args.textStyle);
                }
                return ChartAxisLabel('', args.textStyle);
              },
            ),
            primaryYAxis: NumericAxis(
              labelFormat: '{value}',
              numberFormat: NumberFormat.compact(locale: 'zh_CN'),
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
            ),
            series: <CartesianSeries>[
              // 折线图+面积图组合展示
              SplineAreaSeries<AssetHistoryData, String>(
                dataSource: assetData,
                xValueMapper: (data, _) => data.formattedDate,
                yValueMapper: (data, _) => data.totalAssets,
                splineType: SplineType.natural,
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
              SplineSeries<AssetHistoryData, String>(
                dataSource: assetData,
                xValueMapper: (data, _) => data.formattedDate,
                yValueMapper: (data, _) => data.totalAssets,
                color: primaryColor,
                width: 2,
                markerSettings: MarkerSettings(
                  isVisible: assetData.length <= 20, // 只有在数据点较少时才显示标记
                  color: primaryColor,
                  borderColor: Colors.white,
                  borderWidth: 2,
                  height: 6,
                  width: 6,
                ),
              ),
            ],
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              lineType: TrackballLineType.vertical,
              tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
              builder:
                  (BuildContext context, TrackballDetails trackballDetails) {
                final dynamic dataPoint = trackballDetails.point;

                if (dataPoint != null && dataPoint.y != null) {
                  final double currentY = dataPoint.y as double;

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
                    child: Text(
                      formatter.format(currentY),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
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
