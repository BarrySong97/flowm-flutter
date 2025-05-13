import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';

// A generic model class for treemap data
class TreemapData {
  final String name;
  final double value;
  final String? group;
  final Color? color;

  const TreemapData({
    required this.name,
    required this.value,
    this.group,
    this.color,
  });
}

// A StatefulWidget to display the treemap.
class TreemapWidget extends StatefulWidget {
  final String title;
  final List<TreemapData> dataItems;
  final String? tooltipValueSuffix;

  const TreemapWidget({
    super.key,
    this.title = 'Treemap Demo',
    required this.dataItems,
    this.tooltipValueSuffix,
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
          color: Colors.green[200]!), // Light green
      TreemapColorMapper.range(
          from: 1000,
          to: 5000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.green), // Medium green
      TreemapColorMapper.range(
          from: 5000,
          to: 50000,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.green[800]!), // Dark green
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

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                '''Name: ${dataItem.name}
Value: ${dataItem.value.toStringAsFixed(2)}$suffix''',
                style: const TextStyle(color: Colors.black),
              ),
            );
          },
          groupMapper: (int index) {
            return widget.dataItems[index].name;
          },
          // Builds the label for each treemap tile.
          labelBuilder: (BuildContext context, TreemapTile tile) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.dataItems[tile.indices[0]].name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12), // Label text color set to white for contrast
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
      colorMappers: _colorMappers,
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
