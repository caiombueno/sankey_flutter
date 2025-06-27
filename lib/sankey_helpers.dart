// lib/sankey_helpers.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/interactive_sankey_painter.dart';
import 'package:sankey_flutter/sankey_label_overlay.dart';
import 'package:sankey_flutter/label_position.dart';

/// Generates a configured [Sankey] layout engine
///
/// The [width] and [height] parameters define the drawing area dimensions
/// [nodeWidth] is the width of each node, and [nodePadding] sets the space between nodes
/// The returned [Sankey] object is pre-configured with the specified dimensions and
/// properties for use in computing the layout
///
/// Example:
/// ```dart
/// final sankey = generateSankeyLayout(
///   width: 1000,
///   height: 600,
///   nodeWidth: 20,
///   nodePadding: 15,
/// );
/// ```
Sankey generateSankeyLayout({
  double width = 1000,
  double height = 600,
  double nodeWidth = 20,
  double nodePadding = 15,
}) {
  return Sankey()
    ..nodeWidth = nodeWidth
    ..nodePadding = nodePadding
    ..x0 = 0
    ..y0 = 0
    ..x1 = width
    ..y1 = height;
}

/// A default palette of 15 visually distinct colors for use in node theming
///
/// These colors can be automatically assigned to nodes if no custom color is provided
const List<Color> defaultNodeColors = [
  Colors.blue,
  Colors.green,
  Colors.purple,
  Colors.deepOrange,
  Colors.redAccent,
  Colors.indigoAccent,
  Colors.red,
  Colors.teal,
  Colors.indigo,
  Colors.brown,
  Colors.grey,
  Colors.deepPurple,
  Colors.pink,
  Colors.amber,
  Colors.lightBlue,
];

/// Utility class for managing node theming
///
/// This class provides methods to retrieve a node's color and contrast text color
/// based on its label. If a custom color is not specified in [nodeColors], a color
/// from [defaultNodeColors] is chosen based on a hash of the node's label
class SankeyNodeThemeManager {
  final Map<String, Color> nodeColors;

  SankeyNodeThemeManager(this.nodeColors);

  /// Returns the color associated with the given [label]
  ///
  /// If no custom color is defined for [label], it selects a default color
  /// from [defaultNodeColors] using a hash
  Color getColor(String label) {
    return nodeColors[label] ??
        defaultNodeColors[label.hashCode % defaultNodeColors.length];
  }

  /// Returns an appropriate text color (white or black) for the background color
  /// assigned to the given [label] to ensure legible contrast
  Color getTextColor(String label) {
    final background = getColor(label);
    final isDark = background.computeLuminance() < 0.05;
    return isDark ? Colors.white : Colors.black;
  }
}

/// Generates a default node color map for a list of [SankeyNode] objects
///
/// Each node's [label] is used to assign a color from [defaultNodeColors] in sequence
/// (cycling through the palette). This is useful as a convenience method when no
/// custom node colors are provided
///
/// Returns a [Map] with the node label as key and the assigned [Color] as value
Map<String, Color> generateDefaultNodeColorMap(List<SankeyNode> nodes) {
  final Map<String, Color> colorMap = {};
  for (int i = 0; i < nodes.length; i++) {
    final label = nodes[i].label;
    if (label != null && !colorMap.containsKey(label)) {
      colorMap[label] = defaultNodeColors[i % defaultNodeColors.length];
    }
  }
  return colorMap;
}

/// Determines if a tap hit a node and returns its [id]; returns null if no node is hit
///
/// [nodes] is the list of [SankeyNode] objects and [tapPos] is the [Offset] of
/// the tap event in the canvas coordinate space
String? detectTappedNode(List<SankeyNode> nodes, Offset tapPos) {
  for (var node in nodes) {
    final rect =
        Rect.fromLTWH(node.x0, node.y0, node.x1 - node.x0, node.y1 - node.y0);
    if (rect.contains(tapPos)) return node.id;
  }
  return null;
}

/// Combines nodes and links with layout logic
///
/// The [SankeyDataSet] class holds the list of nodes and links, and provides a
/// [layout] method that applies the given [Sankey] layout generator to compute
/// the positions and dimensions for the nodes and links
class SankeyDataSet {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;

  SankeyDataSet({required this.nodes, required this.links});

  /// Computes the layout for the nodes and links using the provided [sankey] generator.
  void layout(Sankey sankey) {
    sankey.layout(nodes, links);
  }
}

/// Builds an interactive painter based on the provided nodes, links, and node colors
///
/// The [selectedNodeId] parameter indicates an optional node ID for which
/// special highlighting may be applied.
/// Returns an instance of [InteractiveSankeyPainter].
///
/// Note: Labels are not rendered by this painter. Use [SankeyLabelOverlay] for labels.
InteractiveSankeyPainter buildInteractiveSankeyPainter({
  required List<SankeyNode> nodes,
  required List<SankeyLink> links,
  required Map<String, Color> nodeColors,
  String? selectedNodeId,
}) {
  return InteractiveSankeyPainter(
    nodes: nodes,
    links: links,
    nodeColors: nodeColors,
    selectedNodeId: selectedNodeId,
  );
}

/// A widget that wraps an interactive Sankey diagram with flexible label positioning
///
/// The [SankeyDiagramWidget] integrates gesture detection for tapping nodes and
/// renders the diagram using a [CustomPaint] widget with an overlay for labels.
/// It takes a [SankeyDataSet] as its data source, a node colors map, and an optional
/// [selectedNodeId] along with a callback [onNodeTap] which is called when a node is tapped.
///
/// Labels are rendered using the provided [labelBuilder] function and positioned
/// according to [labelPosition]. The [size] parameter specifies the drawing area.
class SankeyDiagramWidget extends StatelessWidget {
  final SankeyDataSet data;
  final Map<String, Color> nodeColors;
  final String? selectedNodeId;
  final Function(String?)? onNodeTap;
  final Size size;
  final bool showLabels;
  final LabelBuilder? labelBuilder;
  final LabelPosition labelPosition;
  final double labelMargin;

  const SankeyDiagramWidget({
    Key? key,
    required this.data,
    required this.nodeColors,
    this.selectedNodeId,
    this.onNodeTap,
    this.size = const Size(1000, 600),
    this.showLabels = true,
    this.labelBuilder,
    this.labelPosition = LabelPosition.auto,
    this.labelMargin = 6.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final tapped = detectTappedNode(data.nodes, details.localPosition);
        if (onNodeTap != null) onNodeTap!(tapped);
      },
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // Base diagram without labels
            CustomPaint(
              size: size,
              painter: buildInteractiveSankeyPainter(
                nodes: data.nodes,
                links: data.links,
                nodeColors: nodeColors,
                selectedNodeId: selectedNodeId,
              ),
            ),
            // Label overlay
            if (showLabels && labelBuilder != null)
              SankeyLabelOverlay(
                nodes: data.nodes,
                labelBuilder: labelBuilder!,
                labelPosition: labelPosition,
                canvasSize: size,
                margin: labelMargin,
                showLabels: showLabels,
              ),
          ],
        ),
      ),
    );
  }
}
