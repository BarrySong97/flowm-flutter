import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';

// A model class to represent the data for the treemap.
class SocialMediaUsers {
  const SocialMediaUsers(this.country, this.socialMedia, this.usersInMillions);

  final String country;
  final String socialMedia;
  final double usersInMillions;
}

// A StatefulWidget to display the treemap.
class TreemapWidget extends StatefulWidget {
  const TreemapWidget({super.key, this.title = 'Treemap Demo'});

  final String title;

  @override
  State<TreemapWidget> createState() => _TreemapWidgetState();
}

class _TreemapWidgetState extends State<TreemapWidget> {
  late List<SocialMediaUsers> _source;
  late List<TreemapColorMapper> _colorMappers;

  @override
  void initState() {
    super.initState();
    // Initialize sample data for the treemap.
    // In a real application, this data would likely come from a service or state management.
    _source = const <SocialMediaUsers>[
      SocialMediaUsers('India', 'Facebook', 25.4),
      SocialMediaUsers('USA', 'Instagram', 19.11),
      SocialMediaUsers('Japan', 'Facebook', 13.3),
      SocialMediaUsers('Germany', 'Instagram', 10.65),
      SocialMediaUsers('France', 'Twitter', 7.54),
      SocialMediaUsers('UK', 'Instagram', 4.93),
    ];

    // Initialize color mappers for range-based coloring.
    _colorMappers = <TreemapColorMapper>[
      TreemapColorMapper.range(
          from: 0,
          to: 10,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.green[200]!), // Light green
      TreemapColorMapper.range(
          from: 10,
          to: 20,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.green), // Medium green
      TreemapColorMapper.range(
          from: 20,
          to: 30,
          minSaturation: 0.5,
          maxSaturation: 1,
          color: Colors.green[800]!), // Dark green
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SfTreemap(
      // The number of data points.
      dataCount: _source.length,
      // Maps data points to their weight for treemap visualization.
      weightValueMapper: (int index) {
        return _source[index].usersInMillions;
      },
      // Defines the levels of the treemap.
      levels: <TreemapLevel>[
        TreemapLevel(
          colorValueMapper: (TreemapTile tile) =>
              _source[tile.indices[0]].usersInMillions,

          tooltipBuilder: (BuildContext context, TreemapTile tile) {
            final dataItem = _source.firstWhere(
              (item) => item.country == tile.group,
              orElse: () => const SocialMediaUsers('Unknown', 'N/A', 0.0),
            );
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                '''Country          : ${tile.group}
Social media : ${dataItem.socialMedia}
Users (Millions) : ${tile.weight}M''',
                style:
                    const TextStyle(color: Colors.black), // Tooltip text color
              ),
            );
          },
          groupMapper: (int index) {
            return _source[index].country;
          },
          // Builds the label for each treemap tile.
          labelBuilder: (BuildContext context, TreemapTile tile) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                tile.group,
                style: const TextStyle(
                    color: Colors
                        .white), // Label text color set to white for contrast
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
