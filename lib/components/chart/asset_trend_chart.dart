import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../state/account/account_repository.dart';

/// 资产趋势线图组件
///
/// 显示最近一年的资产变化趋势
class AssetTrendChart extends ConsumerWidget {
  const AssetTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听年度资产趋势数据
    final assetTrendAsync = ref.watch(yearlyAssetTrendProvider);

    // 定义图表主色调
    final Color primaryColor = const Color(0xFF22C5C2);

    return Container(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: 200, // 固定高度，可根据需要调整
        child: assetTrendAsync.when(
          data: (assetData) {
            if (assetData.isEmpty) {
              return const Center(child: Text('暂无资产趋势数据'));
            }

            // 格式化货币显示
            final formatter =
                NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

            // 判断数据点是否过多，如果超过30个点，只显示部分X轴标签
            final bool showAllLabels = assetData.length <= 30;
            final int labelInterval =
                showAllLabels ? 1 : (assetData.length / 10).ceil();

            return SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle:
                    const TextStyle(color: Colors.black54, fontSize: 12),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelPlacement: LabelPlacement.onTicks,
                interval: labelInterval.toDouble(), // 控制标签间隔
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}',
                numberFormat: NumberFormat.compact(locale: 'zh_CN'),
                labelStyle:
                    const TextStyle(color: Colors.black54, fontSize: 12),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x: ${formatter.format('{point.y}')}',
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
              crosshairBehavior: CrosshairBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                lineColor: Colors.grey,
                lineType: CrosshairLineType.both,
                lineDashArray: <double>[5, 5],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('加载资产趋势数据失败: $error'),
          ),
        ),
      ),
    );
  }
}
