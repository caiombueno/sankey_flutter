// lib/sankey_label_overlay.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/label_position.dart';

/// Signature for label builder function
typedef LabelBuilder = Widget Function(
    BuildContext context, String label, double value);

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
  final Map<String, Size> _labelSizes = {};

  /// Map to store global keys for each label
  final Map<String, GlobalKey> _labelKeys = {};

  /// Whether the initial measurement pass is complete
  bool _measurementComplete = false;
  
  /// Calculated padding required for centered labels
  EdgeInsets _calculatedPadding = EdgeInsets.zero;
  
  /// Getter for accessing calculated padding from parent widgets
  EdgeInsets get calculatedPadding => _calculatedPadding;

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
        final nodeId = node.id;

        _labelKeys[nodeId] = GlobalKey();
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
      _calculateRequiredPadding();
      setState(() {
        _measurementComplete = true;
      });
    }
  }
  
  /// Calculate the padding required to ensure centered labels are fully visible
  void _calculateRequiredPadding() {
    if (widget.labelPosition != LabelPosition.center) {
      _calculatedPadding = EdgeInsets.zero;
      return;
    }
    
    double maxLeftPadding = 0;
    double maxRightPadding = 0;
    double maxTopPadding = 0;
    double maxBottomPadding = 0;
    
    for (final node in widget.nodes) {
      final labelSize = _labelSizes[node.id];
      if (labelSize == null || node.label == null) continue;
      
      // Calculate centered position
      final nodeCenter = Offset(
        node.x0 + (node.x1 - node.x0) / 2,
        node.y0 + (node.y1 - node.y0) / 2,
      );
      
      final labelLeft = nodeCenter.dx - labelSize.width / 2;
      final labelRight = nodeCenter.dx + labelSize.width / 2;
      final labelTop = nodeCenter.dy - labelSize.height / 2;
      final labelBottom = nodeCenter.dy + labelSize.height / 2;
      
      // Calculate required padding to keep labels within bounds
      if (labelLeft < 0) {
        maxLeftPadding = math.max(maxLeftPadding, -labelLeft + widget.margin);
      }
      if (labelRight > widget.canvasSize.width) {
        maxRightPadding = math.max(maxRightPadding, labelRight - widget.canvasSize.width + widget.margin);
      }
      if (labelTop < 0) {
        maxTopPadding = math.max(maxTopPadding, -labelTop + widget.margin);
      }
      if (labelBottom > widget.canvasSize.height) {
        maxBottomPadding = math.max(maxBottomPadding, labelBottom - widget.canvasSize.height + widget.margin);
      }
    }
    
    _calculatedPadding = EdgeInsets.only(
      left: maxLeftPadding,
      right: maxRightPadding,
      top: maxTopPadding,
      bottom: maxBottomPadding,
    );
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

    return SizedBox(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      child: Stack(
        clipBehavior: Clip.none, // Allow labels to extend beyond canvas bounds
        children: widget.nodes
            .where((node) => node.label != null)
            .map((node) => _buildPositionedLabel(node))
            .toList(),
      ),
    );
  }

  /// Builds a positioned label widget for the given node
  Widget _buildPositionedLabel(SankeyNode node) {
    final label = node.label!;
    final key = _labelKeys[node.id]!;

    // Build the label widget
    final labelWidget = widget.labelBuilder(context, label, node.value);

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

    // For center positioning, always show labels at full opacity since they're properly centered
    final isVisible = widget.labelPosition == LabelPosition.center || 
        widget.labelPosition.isVisibleInCanvas(
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
Widget defaultLabelBuilder(BuildContext context, String label, double value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
    ),
    child: Text(
      '$label (${value.toStringAsFixed(1)})',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );
}
