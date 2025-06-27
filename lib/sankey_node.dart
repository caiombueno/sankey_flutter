// lib/sankey_node.dart

import 'sankey_link.dart';

/// A node in the Sankey diagram.
class SankeyNode {
  final String id;
  String? label;
  int index = 0;
  double value = 0.0;
  double? fixedValue;
  int depth = 0; // Distance from source
  int height = 0; // Distance to sink
  int layer = 0; // Horizontal column index
  double x0 = 0.0; // Left x
  double x1 = 0.0; // Right x
  double y0 = 0.0; // Top y
  double y1 = 0.0; // Bottom y
  List<SankeyLink> sourceLinks = [];
  List<SankeyLink> targetLinks = [];

  SankeyNode({required this.id, this.label});
}
