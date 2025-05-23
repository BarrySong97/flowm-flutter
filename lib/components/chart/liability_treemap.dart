import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';

// A generic model class for treemap data
class LiabilityTreemapData {
  final String name;
  final double value;
  final String? group;
  final Color? color;
  final bool canDrillDown;
  final double? percentageOfLevel;

  const LiabilityTreemapData({
    required this.name,
    required this.value,
    this.group,
    this.color,
    this.canDrillDown = false,
    this.percentageOfLevel,
  });
}

// A StatefulWidget to display the liability treemap.
class LiabilityTreemapWidget extends StatefulWidget {
  final String title;
  final List<LiabilityTreemapData> dataItems;
  final String? tooltipValueSuffix;
  final String? drilledDownAccountName;
  final Function(String accountName)? onDrillDownSelected;
  final Function(String accountName)? onDoubleClick;

  const LiabilityTreemapWidget({
    super.key,
    this.title = 'Liability Treemap',
    this.drilledDownAccountName,
    required this.dataItems,
    this.tooltipValueSuffix,
    this.onDrillDownSelected,
    this.onDoubleClick,
  });

  @override
  State<LiabilityTreemapWidget> createState() => _LiabilityTreemapWidgetState();
}

class _LiabilityTreemapWidgetState extends State<LiabilityTreemapWidget> {
  late List<TreemapColorMapper> _colorMappers;

  @override
  void initState() {
    super.initState();

    // Initialize color mappers for range-based coloring using red accent colors
    _colorMappers = <TreemapColorMapper>[
      TreemapColorMapper.range(
          from: 0,
          to: 1000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.redAccent[100]!), // Light red
      TreemapColorMapper.range(
          from: 1000,
          to: 5000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.redAccent[200]!), // Medium red
      TreemapColorMapper.range(
          from: 5000,
          to: 50000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.redAccent[400]!), // Dark red
      TreemapColorMapper.range(
          from: 50000,
          to: double.infinity,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.redAccent[700]!), // Darkest red
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SfTreemap(
      dataCount: widget.dataItems.length,
      weightValueMapper: (int index) {
        return widget.dataItems[index].value;
      },
      colorMappers: _colorMappers,
      levels: <TreemapLevel>[
        TreemapLevel(
          colorValueMapper: (TreemapTile tile) =>
              widget.dataItems[tile.indices[0]].value,
          tooltipBuilder: (BuildContext context, TreemapTile tile) {
            final dataItem = widget.dataItems[tile.indices[0]];
            final suffix = widget.tooltipValueSuffix ?? '';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dataItem.name,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '金额: $suffix${dataItem.value.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '占比: ${dataItem.percentageOfLevel != null ? dataItem.percentageOfLevel!.toStringAsFixed(2) + '%' : 'N/A'} (相对当前层级)',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dataItem.canDrillDown) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          child: const Text(
                            '[长按下钻查看 | 双击进入详情]',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
          groupMapper: (int index) {
            return widget.dataItems[index].name;
          },
          labelBuilder: (BuildContext context, TreemapTile tile) {
            final dataItem = widget.dataItems[tile.indices[0]];

            // Define min/max font sizes and ultra min for very small percentages
            const double ultraMinNameFontSize = 6.0;
            const double ultraMinPercFontSize = 4.0;
            const double minNameFontSize = 8.0;
            const double maxNameFontSize = 12.0;
            const double minPercFontSize = 6.0;
            const double maxPercFontSize = 10.0;

            // Percentage thresholds for scaling
            const double verySmallPercentageThreshold = 2.0;
            const double scalingStartPercentage = 5.0;
            const double maxScalingPercentage = 20.0;

            double currentPercentage = dataItem.percentageOfLevel ?? 0.0;
            double nameFontSize;
            double percFontSize;

            if (currentPercentage < verySmallPercentageThreshold) {
              nameFontSize = ultraMinNameFontSize;
              percFontSize = ultraMinPercFontSize;
            } else if (currentPercentage < scalingStartPercentage) {
              nameFontSize = minNameFontSize;
              percFontSize = minPercFontSize;
            } else if (currentPercentage >= maxScalingPercentage) {
              nameFontSize = maxNameFontSize;
              percFontSize = maxPercFontSize;
            } else {
              final factor = (currentPercentage - scalingStartPercentage) /
                  (maxScalingPercentage - scalingStartPercentage);
              nameFontSize = minNameFontSize +
                  (maxNameFontSize - minNameFontSize) * factor;
              percFontSize = minPercFontSize +
                  (maxPercFontSize - minPercFontSize) * factor;
            }

            nameFontSize =
                nameFontSize.clamp(ultraMinNameFontSize, maxNameFontSize);
            percFontSize =
                percFontSize.clamp(ultraMinPercFontSize, maxPercFontSize);

            return GestureDetector(
              onLongPress: () {
                if (dataItem.canDrillDown) {
                  widget.onDrillDownSelected?.call(dataItem.name);
                }
              },
              onDoubleTap: () {
                if (widget.onDoubleClick != null) {
                  widget.onDoubleClick!(dataItem.name);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dataItem.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w500),
                      ),
                      if (dataItem.percentageOfLevel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${dataItem.percentageOfLevel!.toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: percFontSize),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
