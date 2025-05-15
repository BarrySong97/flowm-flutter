import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';

// A generic model class for treemap data
class TreemapData {
  final String name;
  final double value;
  final String? group;
  final Color? color;
  final bool canDrillDown;
  final double? percentageOfLevel;

  const TreemapData({
    required this.name,
    required this.value,
    this.group,
    this.color,
    this.canDrillDown = false,
    this.percentageOfLevel,
  });
}

// A StatefulWidget to display the treemap.
class TreemapWidget extends StatefulWidget {
  final String title;
  final List<TreemapData> dataItems;
  final String? tooltipValueSuffix;
  final String? drilledDownAccountName;
  final Function(String accountName)? onDrillDownSelected;

  const TreemapWidget({
    super.key,
    this.title = 'Treemap Demo',
    this.drilledDownAccountName,
    required this.dataItems,
    this.tooltipValueSuffix,
    this.onDrillDownSelected,
  });

  @override
  State<TreemapWidget> createState() => _TreemapWidgetState();
}

class _TreemapWidgetState extends State<TreemapWidget> {
  late List<TreemapColorMapper> _colorMappers;

  @override
  void initState() {
    super.initState();

    // Initialize color mappers for range-based coloring.
    _colorMappers = <TreemapColorMapper>[
      TreemapColorMapper.range(
          from: 0,
          to: 1000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: const Color.fromARGB(255, 122, 165, 123)!), // Light green
      TreemapColorMapper.range(
          from: 1000,
          to: 5000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: const Color.fromARGB(255, 83, 172, 86)), // Medium green
      TreemapColorMapper.range(
          from: 5000,
          to: 50000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: const Color.fromARGB(255, 74, 190, 79)!), // Dark green
      TreemapColorMapper.range(
          // New range for values greater than 50000
          from: 50000,
          to: double
              .infinity, // Or a sufficiently large number if infinity is not appropriate
          minSaturation: 0.5,
          maxSaturation: 1,
          color: const Color.fromARGB(255, 10, 151, 81)!), // Darkest green
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SfTreemap(
      // The number of data points.
      dataCount: widget.dataItems.length,
      // Maps data points to their weight for treemap visualization.
      weightValueMapper: (int index) {
        return widget.dataItems[index].value;
      },
      // Defines the levels of the treemap.
      levels: <TreemapLevel>[
        TreemapLevel(
          colorValueMapper: (TreemapTile tile) =>
              widget.dataItems[tile.indices[0]].value,

          tooltipBuilder: (BuildContext context, TreemapTile tile) {
            final dataItem = widget.dataItems[tile.indices[0]];
            final suffix = widget.tooltipValueSuffix ?? '';
            // Placeholder for percentage calculation
            const String percentagePlaceholder = 'XX%';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4), // Added border radius
                boxShadow: [
                  // Added shadow for a popover look
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dataItem.name, // "房屋及建筑"
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
                          // Optional: Add some padding if needed for easier tapping
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          child: const Text(
                            '[长按下钻查看 ]',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // The [x] close button is usually handled by the tooltip behavior itself
                  // or would require a more custom overlay implementation.
                  // If SfTreemap's tooltip doesn't provide a close button by default,
                  // we might need to wrap this in a custom popover.
                ],
              ),
            );
          },

          groupMapper: (int index) {
            return widget.dataItems[index].name;
          },
          // Builds the label for each treemap tile.
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
            const double verySmallPercentageThreshold =
                2.0; // Below this, use ultraMin font size
            const double smallPercentageThreshold =
                5.0; // Between verySmall and small, use min font size
            const double scalingStartPercentage =
                5.0; // Same as smallPercentageThreshold, for clarity
            const double maxScalingPercentage =
                20.0; // Reach max font size at this percentage

            double currentPercentage = dataItem.percentageOfLevel ?? 0.0;
            double nameFontSize;
            double percFontSize;

            if (currentPercentage < verySmallPercentageThreshold) {
              // e.g. < 2.0%
              nameFontSize = ultraMinNameFontSize;
              percFontSize = ultraMinPercFontSize;
            } else if (currentPercentage < scalingStartPercentage) {
              // e.g. >= 2.0% and < 5.0%
              nameFontSize = minNameFontSize;
              percFontSize = minPercFontSize;
            } else if (currentPercentage >= maxScalingPercentage) {
              // e.g. >= 20.0%
              nameFontSize = maxNameFontSize;
              percFontSize = maxPercFontSize;
            } else {
              // e.g. >= 5.0% and < 20.0% (scaling part)
              final factor = (currentPercentage - scalingStartPercentage) /
                  (maxScalingPercentage - scalingStartPercentage);
              nameFontSize = minNameFontSize +
                  (maxNameFontSize - minNameFontSize) * factor;
              percFontSize = minPercFontSize +
                  (maxPercFontSize - minPercFontSize) * factor;
            }

            // Clamp to absolute min/max to be safe
            nameFontSize =
                nameFontSize.clamp(ultraMinNameFontSize, maxNameFontSize);
            percFontSize =
                percFontSize.clamp(ultraMinPercFontSize, maxPercFontSize);

            return GestureDetector(
              onLongPress: () {
                if (dataItem.canDrillDown) {
                  print('长按标签下钻: ${dataItem.name}');
                  widget.onDrillDownSelected?.call(dataItem.name);
                } else {
                  print('长按标签: ${dataItem.name} (不可下钻)');
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      dataItem.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    // Show percentage if available, regardless of its value (font size will handle visibility)
                    if (dataItem.percentageOfLevel != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${dataItem.percentageOfLevel!.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70, fontSize: percFontSize),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ],
      colorMappers: _colorMappers,
      tooltipSettings: TreemapTooltipSettings(color: Colors.white),
    );
  }
}

// Example usage (can be placed in a page or another widget):
//
// class MyPage extends StatelessWidget {
//   const MyPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const TreemapWidget(title: 'Social Media Usage');
//   }
// }
