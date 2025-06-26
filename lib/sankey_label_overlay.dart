// lib/sankey_label_overlay.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/label_position.dart';

/// Signature for label builder function
typedef LabelBuilder = Widget Function(BuildContext context, String label);

/// A widget that renders positioned labels over a Sankey diagram
/// 
/// This widget creates label widgets using the provided [labelBuilder] function
/// and positions them according to the [labelPosition] relative to their
/// corresponding nodes.
class SankeyLabelOverlay extends StatefulWidget {
  /// List of nodes to create labels for
  final List<SankeyNode> nodes;
  
  /// Function to build label widgets
  final LabelBuilder labelBuilder;
  
  /// Position of labels relative to nodes
  final LabelPosition labelPosition;
  
  /// Size of the canvas/container
  final Size canvasSize;
  
  /// Margin distance from nodes
  final double margin;
  
  /// Whether to show labels
  final bool showLabels;

  const SankeyLabelOverlay({
    Key? key,
    required this.nodes,
    required this.labelBuilder,
    required this.canvasSize,
    this.labelPosition = LabelPosition.auto,
    this.margin = 6.0,
    this.showLabels = true,
  }) : super(key: key);

  @override
  State<SankeyLabelOverlay> createState() => _SankeyLabelOverlayState();
}

class _SankeyLabelOverlayState extends State<SankeyLabelOverlay> {
  /// Map to store measured label sizes
  final Map<int, Size> _labelSizes = {};
  
  /// Map to store global keys for each label
  final Map<int, GlobalKey> _labelKeys = {};
  
  /// Whether the initial measurement pass is complete
  bool _measurementComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeLabelKeys();
  }

  @override
  void didUpdateWidget(SankeyLabelOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset measurement if nodes changed
    if (widget.nodes != oldWidget.nodes) {
      _labelSizes.clear();
      _measurementComplete = false;
      _initializeLabelKeys();
    }
  }

  /// Initialize global keys for all nodes that have labels
  void _initializeLabelKeys() {
    _labelKeys.clear();
    for (final node in widget.nodes) {
      if (node.label != null) {
        _labelKeys[node.id] = GlobalKey();
      }
    }
  }

  /// Measure label sizes after the first render
  void _measureLabels() {
    if (_measurementComplete) return;
    
    bool allMeasured = true;
    
    for (final entry in _labelKeys.entries) {
      final nodeId = entry.key;
      final key = entry.value;
      
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        _labelSizes[nodeId] = renderBox.size;
      } else {
        allMeasured = false;
      }
    }
    
    if (allMeasured && _labelSizes.isNotEmpty) {
      setState(() {
        _measurementComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showLabels) {
      return const SizedBox.shrink();
    }

    // Schedule measurement after the first build
    if (!_measurementComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureLabels());
    }

    return Stack(
      children: widget.nodes
          .where((node) => node.label != null)
          .map((node) => _buildPositionedLabel(node))
          .toList(),
    );
  }

  /// Builds a positioned label widget for the given node
  Widget _buildPositionedLabel(SankeyNode node) {
    final label = node.label!;
    final key = _labelKeys[node.id]!;
    
    // Build the label widget
    final labelWidget = widget.labelBuilder(context, label);
    
    // If measurement is not complete, render invisibly for measurement
    if (!_measurementComplete) {
      return Positioned(
        left: -10000, // Position off-screen
        top: -10000,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: Container(
              key: key,
              child: labelWidget,
            ),
          ),
        ),
      );
    }
    
    // Get the measured size
    final labelSize = _labelSizes[node.id];
    if (labelSize == null) {
      return const SizedBox.shrink();
    }
    
    // Calculate position
    final offset = widget.labelPosition.calculateOffset(
      node,
      labelSize,
      widget.canvasSize,
      margin: widget.margin,
    );
    
    // Check if the label would be visible
    final isVisible = widget.labelPosition.isVisibleInCanvas(
      node,
      labelSize,
      widget.canvasSize,
      margin: widget.margin,
    );
    
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: isVisible
          ? labelWidget
          : Opacity(
              opacity: 0.5, // Partially visible if clipped
              child: labelWidget,
            ),
    );
  }
}

/// Default label builder that creates a simple Text widget
/// 
/// This can be used as a fallback when no custom labelBuilder is provided
Widget defaultLabelBuilder(BuildContext context, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );
}