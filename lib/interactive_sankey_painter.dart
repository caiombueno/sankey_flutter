// lib\interactive_sankey_painter.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_painter.dart';

/// A [SankeyPainter] subclass that adds interactivity:
///
/// - Supports custom node colors per label
/// - Highlights connected links when a node is selected
/// - Applies hover/focus feedback with opacity and borders
///
/// Note: This painter does not render labels. Use [SankeyLabelOverlay]
/// for label rendering with flexible positioning.
class InteractiveSankeyPainter extends SankeyPainter {
  /// Map of node labels to specific colors
  final Map<String, Color> nodeColors;

  /// ID of the currently selected node, if any
  final String? selectedNodeId;

  InteractiveSankeyPainter({
    required List<SankeyNode> nodes,
    required List<SankeyLink> links,
    required this.nodeColors,
    this.selectedNodeId,
    Color linkColor = Colors.grey,
  }) : super(
          showLabels: false, // Labels are handled by SankeyLabelOverlay
          nodes: nodes,
          links: links,
          nodeColor: Colors.blue, // fallback node color
          linkColor: linkColor,
        );

  /// Blends two colors for transition effects (used in link paths)
  Color blendColors(Color a, Color b) => Color.lerp(a, b, 0.5) ?? a;

  @override
  void paint(Canvas canvas, Size size) {
    // --- Draw enhanced links ---
    for (SankeyLink link in links) {
      final source = link.source as SankeyNode;
      final target = link.target as SankeyNode;

      final sourceColor = nodeColors[source.label] ?? Colors.blue;
      final targetColor = nodeColors[target.label] ?? Colors.blue;
      var blended = blendColors(sourceColor, targetColor);

      // Highlight links connected to the selected node
      final isConnected = (selectedNodeId != null) &&
          (source.id == selectedNodeId || target.id == selectedNodeId);
      blended = blended.withValues(alpha: isConnected ? 0.9 : 0.5);

      final linkPaint = Paint()
        ..color = blended
        ..style = PaintingStyle.stroke
        ..strokeWidth = link.width;

      final path = Path();
      final xMid = (source.x1 + target.x0) / 2;
      path.moveTo(source.x1, link.y0);
      path.cubicTo(xMid, link.y0, xMid, link.y1, target.x0, link.y1);

      canvas.drawPath(path, linkPaint);
    }

    // --- Draw colored nodes and labels with selection borders ---
    for (SankeyNode node in nodes) {
      final color = nodeColors[node.label] ?? Colors.blue;
      final rect =
          Rect.fromLTWH(node.x0, node.y0, node.x1 - node.x0, node.y1 - node.y0);
      final isSelected = selectedNodeId != null && node.id == selectedNodeId;

      canvas.drawRect(rect, Paint()..color = color);

      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRect(rect, borderPaint);
      }
    }
  }
}
