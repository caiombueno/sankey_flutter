// lib/label_position.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_node.dart';

/// Enum defining different positioning options for labels relative to nodes
enum LabelPosition {
  /// Position label to the left of the node
  left,
  
  /// Position label to the right of the node
  right,
  
  /// Position label above the node
  top,
  
  /// Position label below the node
  bottom,
  
  /// Position label centered on the node
  center,
  
  /// Position label inside the node bounds
  inside,
  
  /// Use smart positioning logic (tries right, falls back to left)
  auto,
}

/// Extension methods for LabelPosition to calculate label offsets
extension LabelPositionCalculation on LabelPosition {
  /// Calculates the position offset for a label based on node position and label size
  /// 
  /// [node] - The SankeyNode to position the label relative to
  /// [labelSize] - The Size of the label widget
  /// [canvasSize] - The Size of the canvas/container
  /// [margin] - The margin distance from the node (default: 6.0)
  /// 
  /// Returns an Offset representing where to position the label
  Offset calculateOffset(
    SankeyNode node,
    Size labelSize,
    Size canvasSize, {
    double margin = 6.0,
  }) {
    final nodeRect = Rect.fromLTWH(
      node.x0, 
      node.y0, 
      node.x1 - node.x0, 
      node.y1 - node.y0,
    );
    
    final nodeCenter = nodeRect.center;
    
    switch (this) {
      case LabelPosition.left:
        return Offset(
          node.x0 - labelSize.width - margin,
          nodeCenter.dy - labelSize.height / 2,
        );
        
      case LabelPosition.right:
        return Offset(
          node.x1 + margin,
          nodeCenter.dy - labelSize.height / 2,
        );
        
      case LabelPosition.top:
        return Offset(
          nodeCenter.dx - labelSize.width / 2,
          node.y0 - labelSize.height - margin,
        );
        
      case LabelPosition.bottom:
        return Offset(
          nodeCenter.dx - labelSize.width / 2,
          node.y1 + margin,
        );
        
      case LabelPosition.center:
      case LabelPosition.inside:
        return Offset(
          nodeCenter.dx - labelSize.width / 2,
          nodeCenter.dy - labelSize.height / 2,
        );
        
      case LabelPosition.auto:
        // Smart positioning: try right first, fallback to left
        final rightOffset = Offset(
          node.x1 + margin,
          nodeCenter.dy - labelSize.height / 2,
        );
        
        final leftOffset = Offset(
          node.x0 - labelSize.width - margin,
          nodeCenter.dy - labelSize.height / 2,
        );
        
        // Check if right position fits within canvas
        if (rightOffset.dx + labelSize.width <= canvasSize.width) {
          return rightOffset;
        }
        
        // Check if left position fits within canvas
        if (leftOffset.dx >= 0) {
          return leftOffset;
        }
        
        // Fallback to right if neither fits perfectly
        return rightOffset;
    }
  }
  
  /// Checks if the calculated position would be visible within the canvas bounds
  /// 
  /// [node] - The SankeyNode to position the label relative to
  /// [labelSize] - The Size of the label widget
  /// [canvasSize] - The Size of the canvas/container
  /// [margin] - The margin distance from the node (default: 6.0)
  /// 
  /// Returns true if the label would be fully visible within canvas bounds
  bool isVisibleInCanvas(
    SankeyNode node,
    Size labelSize,
    Size canvasSize, {
    double margin = 6.0,
  }) {
    final offset = calculateOffset(node, labelSize, canvasSize, margin: margin);
    
    return offset.dx >= 0 &&
        offset.dy >= 0 &&
        offset.dx + labelSize.width <= canvasSize.width &&
        offset.dy + labelSize.height <= canvasSize.height;
  }
}