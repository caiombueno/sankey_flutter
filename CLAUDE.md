# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter package that provides Sankey diagram visualization capabilities. The package adapts the d3-sankey layout algorithm to Dart/Flutter, enabling the creation of flow diagrams with nodes and weighted links. The architecture follows a separation between layout computation (mathematical positioning) and rendering (Flutter CustomPainter).

## Development Commands

### Testing
```bash
flutter test
```

### Package Development
```bash
flutter pub get          # Install dependencies
flutter pub deps         # Show dependency tree
flutter packages pub publish --dry-run  # Validate package for publishing
```

### Example App
```bash
cd example && flutter run  # Run the example application
```

### Code Analysis
```bash
flutter analyze          # Run static analysis
dart format .            # Format code
```

## Architecture

### Core Components

**Layout Engine (`lib/sankey.dart`)**
- `Sankey` class: Main layout generator that computes node positions and link geometries
- Implements d3-sankey algorithm with depth-first positioning, iterative relaxation, and collision resolution
- Supports multiple alignment strategies: left, right, center, justify
- Key methods: `layout()` orchestrates the entire positioning process

**Data Models**
- `SankeyNode` (`lib/sankey_node.dart`): Represents diagram nodes with position properties (x0, x1, y0, y1) and link references
- `SankeyLink` (`lib/sankey_link.dart`): Represents flows between nodes with source, target, value, and computed width
- Both models use dynamic typing for source/target to handle references during layout computation

**Rendering**
- `SankeyPainter` (`lib/sankey_painter.dart`): Base CustomPainter for static rendering with cubic Bézier curves for links
- `InteractiveSankeyPainter` (`lib/interactive_sankey_painter.dart`): Extended painter with node selection, custom colors, and hover feedback

**Helper Utilities (`lib/sankey_helpers.dart`)**
- `generateSankeyLayout()`: Factory for configured Sankey instances
- `SankeyNodeThemeManager`: Color management with automatic defaults
- `SankeyDiagramWidget`: Complete widget with gesture detection
- `detectTappedNode()`: Hit testing for node interaction

### Layout Algorithm Flow

1. **Link initialization**: Establish bidirectional node-link relationships
2. **Value computation**: Calculate node values from incoming/outgoing flows
3. **Depth assignment**: Breadth-first search for horizontal positioning
4. **Height computation**: Reverse traversal for optimal alignment
5. **Vertical positioning**: Multi-pass relaxation with collision resolution
6. **Link positioning**: Compute vertical offsets for link endpoints

### Testing Strategy

The test suite (`test/sankey_test.dart`) validates layout accuracy against d3-sankey reference data using:
- Energy flow dataset comparison
- Fuzzy matching with configurable tolerance
- Round-trip precision testing for node and link positions

## Key File Locations

- `lib/sankey.dart`: Core layout algorithm (539 lines)
- `lib/interactive_sankey_painter.dart`: Interactive rendering
- `lib/sankey_helpers.dart`: Utility functions and widgets
- `example/main.dart`: Complete working example with financial flow data
- `test/sankey_test.dart`: Layout validation tests

## Flutter Version

This package uses FVM with Flutter 3.29.0 (see `.fvmrc`). Use `fvm flutter` commands for consistent Flutter version.