import 'package:flowm/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../state/account/account_repository.dart'; // Still needed for AssetHistoryData type
import '../../config/app_constants.dart';

/// 资产趋势线图组件
///
/// 显示资产变化趋势，数据通过参数传入
class AssetTrendChart extends StatelessWidget {
  final List<AssetHistoryData> assetData;
  final Ledger? ledger;
  const AssetTrendChart({
    super.key,
    required this.assetData,
    this.ledger,
  });

  @override
  Widget build(BuildContext context) {
    // 定义图表主色调
    final Color primaryColor = const Color(0xFF8CC398);
    final Color gradientColor = const Color(0xFFF3F8F3);
    return Container(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 140, // 固定高度，可根据需要调整
        child: () {
          if (assetData.isEmpty) {
            return const Center(child: Text('暂无资产趋势数据'));
          }

          // 格式化货币显示
          final formatter = NumberFormat.currency(
              locale: 'zh_CN', symbol: ledger?.currencySymbol ?? AppConstants.currencySymbol);

          // 检测是否所有数据都为0
          final bool allDataIsZero =
              assetData.every((data) => data.totalAssets == 0.0);

          return SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.only(top: 12), // 只在顶部加边距，防止曲线被截断
            primaryXAxis: CategoryAxis(
              isVisible: false,
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              labelPlacement: LabelPlacement.onTicks,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
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
              isVisible: false,
              // numberFormat handles the formatting of the labels
              numberFormat: NumberFormat.compact(locale: 'zh_CN'),
              labelStyle: const TextStyle(color: Colors.black54, fontSize: 12),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              // 调整Y轴范围，确保数据点准确对应
              minimum: null, // 让图表自动计算最小值
              maximum: null, // 让图表自动计算最大值
              desiredIntervals:
                  1, // This should result in labels at the effective min and max of the axis.
              // The custom axisLabelFormatter is removed as desiredIntervals: 1 and numberFormat should suffice.
            ),
            series: <CartesianSeries>[
              // 根据数据情况选择图表类型
              if (allDataIsZero) ...[
                // 当所有数据为0时使用直线图
                LineSeries<AssetHistoryData, String>(
                  dataSource: assetData,
                  xValueMapper: (data, _) => data.formattedDate,
                  yValueMapper: (data, _) => data.totalAssets,
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ] else ...[
                // 有非零数据时使用样条曲线图
                SplineAreaSeries<AssetHistoryData, String>(
                  dataSource: assetData,
                  xValueMapper: (data, _) => data.formattedDate,
                  yValueMapper: (data, _) => data.totalAssets,
                  splineType: SplineType.cardinal, // 使用cardinal样条，更贴近数据点
                  cardinalSplineTension: 0.5, // 增加张力值，让波峰波谷更圆滑
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      gradientColor.withValues(alpha: 1.0), // 顶部颜色更深
                      gradientColor.withValues(alpha: 0.4), // 底部颜色加深
                    ],
                  ),
                  borderColor: primaryColor,
                  borderWidth: 2,
                ),
                SplineSeries<AssetHistoryData, String>(
                  dataSource: assetData,
                  xValueMapper: (data, _) => data.formattedDate,
                  yValueMapper: (data, _) => data.totalAssets,
                  color: primaryColor,
                  width: 2,
                  splineType: SplineType.cardinal, // 使用cardinal样条，更贴近数据点
                  cardinalSplineTension: 0.5, // 增加张力值，让波峰波谷更圆滑
                  markerSettings:
                      const MarkerSettings(isVisible: false), // 隐藏数据点标记
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
                    //                     child: Text(
                    //   '$formattedDate: ${formatter.format(currentY)}',
                    //   style: const TextStyle(color: Colors.black, fontSize: 12),
                    // ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // mainAxisAlignment: MainAxisAlignment.start,
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
