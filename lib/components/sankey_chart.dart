// example/main.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';

/// A stateless widget that defines the overall structure of the Sankey Diagram Example App
///
/// It sets the app title, theme, and uses a [Scaffold] to provide an app bar and a body
/// that renders the Sankey diagram
class SankeyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SankeyComplexDiagramWidget();
  }
}

/// A stateful widget that manages the interactive Sankey diagram
///
/// This widget builds a Sankey diagram using data defined in the [initState] method
/// It also handles user tap interactions to select nodes
class SankeyComplexDiagramWidget extends StatefulWidget {
  @override
  _SankeyComplexDiagramWidgetState createState() =>
      _SankeyComplexDiagramWidgetState();
}

/// The state class for [SankeyComplexDiagramWidget]
///
/// It defines the nodes, links, node colors, and handles layout computation and tap interactions
/// Changes in state trigger a repaint to reflect node selection and updates to the diagram
class _SankeyComplexDiagramWidgetState
    extends State<SankeyComplexDiagramWidget> {
  late List<SankeyNode> nodes;
  late List<SankeyLink> links;
  late Map<String, Color> nodeColors;
  int? selectedNodeId;
  late SankeyDataSet sankeyDataSet;

  // Define layout dimensions as instance variables
  final double _layoutWidth = 300.0;
  final double _layoutHeight = 100.0;

  @override
  void initState() {
    super.initState();

    // Define the list of nodes across multiple layers
    nodes = [
      SankeyNode(id: 0, label: 'Salary'),
      SankeyNode(id: 1, label: 'Freelance'),
      SankeyNode(id: 13, label: 'Mandatory Expenses'),
    ];

    // Define the links between nodes with specified flow values
    links = [
      SankeyLink(source: nodes[0], target: nodes[2], value: 70),
      SankeyLink(source: nodes[1], target: nodes[2], value: 30),
    ];

    // Automatically generate a color map for the nodes using their labels
    nodeColors = generateDefaultNodeColorMap(nodes);

    // Combine the nodes and links into a data set
    sankeyDataSet = SankeyDataSet(nodes: nodes, links: links);

    // Generate the layout using a helper that configures the layout engine
    final sankey = generateSankeyLayout(
      width: _layoutWidth,
      height: _layoutHeight,
      nodeWidth: 10,
      nodePadding: 15,
    );
    sankeyDataSet.layout(sankey);
  }

  /// Callback for handling tap events on nodes
  ///
  /// When a node is tapped, its [id] is stored in [selectedNodeId],
  /// triggering a rebuild that highlights the node
  void _handleNodeTap(int? nodeId) {
    setState(() {
      selectedNodeId = nodeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SankeyDiagramWidget(
      data: sankeyDataSet,
      nodeColors: nodeColors,
      selectedNodeId: selectedNodeId,
      onNodeTap: _handleNodeTap,
      size: Size(_layoutWidth, _layoutHeight),
    );
  }
}
