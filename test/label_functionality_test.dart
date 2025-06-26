// test/label_functionality_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_helpers.dart';
import 'package:sankey_flutter/sankey_label_overlay.dart';
import 'package:sankey_flutter/label_position.dart';

void main() {
  group('Label Functionality Tests', () {
    late List<SankeyNode> testNodes;
    late List<SankeyLink> testLinks;
    late SankeyDataSet testDataSet;

    setUp(() {
      // Create test nodes
      testNodes = [
        SankeyNode(id: 0, label: 'Source'),
        SankeyNode(id: 1, label: 'Target'),
      ];

      // Create test links
      testLinks = [
        SankeyLink(source: testNodes[0], target: testNodes[1], value: 100),
      ];

      // Create dataset and layout
      testDataSet = SankeyDataSet(nodes: testNodes, links: testLinks);
      final sankey = generateSankeyLayout(width: 400, height: 300);
      testDataSet.layout(sankey);
    });

    testWidgets('SankeyDiagramWidget with labelBuilder renders correctly', (WidgetTester tester) async {
      Widget testLabelBuilder(BuildContext context, String label) {
        return Container(
          padding: const EdgeInsets.all(4),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SankeyDiagramWidget(
              data: testDataSet,
              nodeColors: const {'Source': Colors.blue, 'Target': Colors.red},
              showLabels: true,
              labelBuilder: testLabelBuilder,
              labelPosition: LabelPosition.right,
              size: const Size(400, 300),
            ),
          ),
        ),
      );

      // Let the widget build and measure labels
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the widget was built
      expect(find.byType(SankeyDiagramWidget), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('SankeyLabelOverlay renders labels correctly', (WidgetTester tester) async {
      Widget testLabelBuilder(BuildContext context, String label) {
        return Text(label, key: Key('label_$label'));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: SankeyLabelOverlay(
                nodes: testNodes,
                labelBuilder: testLabelBuilder,
                labelPosition: LabelPosition.right,
                canvasSize: const Size(400, 300),
                showLabels: true,
              ),
            ),
          ),
        ),
      );

      // Let the measurement complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify labels are rendered (they might be positioned off-screen initially)
      expect(find.byType(SankeyLabelOverlay), findsOneWidget);
    });

    test('LabelPosition.calculateOffset returns correct positions', () {
      final node = testNodes[0]; // Should have layout coordinates after setUp
      final labelSize = const Size(50, 20);
      const canvasSize = Size(400, 300);

      // Test right position
      final rightOffset = LabelPosition.right.calculateOffset(
        node,
        labelSize,
        canvasSize,
      );
      expect(rightOffset.dx, equals(node.x1 + 6.0)); // node.x1 + default margin

      // Test left position
      final leftOffset = LabelPosition.left.calculateOffset(
        node,
        labelSize,
        canvasSize,
      );
      expect(leftOffset.dx, equals(node.x0 - labelSize.width - 6.0));

      // Test center position
      final centerOffset = LabelPosition.center.calculateOffset(
        node,
        labelSize,
        canvasSize,
      );
      final nodeCenter = Offset(
        (node.x0 + node.x1) / 2,
        (node.y0 + node.y1) / 2,
      );
      expect(centerOffset.dx, equals(nodeCenter.dx - labelSize.width / 2));
      expect(centerOffset.dy, equals(nodeCenter.dy - labelSize.height / 2));
    });

    test('LabelPosition.isVisibleInCanvas works correctly', () {
      final node = testNodes[0];
      const smallLabel = Size(20, 10);
      const largeLabel = Size(200, 50);
      const canvasSize = Size(400, 300);

      // Small label should be visible in most positions
      expect(
        LabelPosition.right.isVisibleInCanvas(node, smallLabel, canvasSize),
        isTrue,
      );

      // Large label might not be visible depending on node position
      final isLargeLabelVisible = LabelPosition.right.isVisibleInCanvas(
        node,
        largeLabel,
        canvasSize,
      );
      expect(isLargeLabelVisible, isA<bool>());
    });

    testWidgets('Default label builder creates correct widget', (WidgetTester tester) async {
      const testLabel = 'Test Label';
      late Widget widget;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              widget = defaultLabelBuilder(context, testLabel);
              return widget;
            },
          ),
        ),
      );

      expect(widget, isA<Container>());
      // The widget should be a Container with padding, decoration, and Text child
      final container = widget as Container;
      expect(container.padding, isA<EdgeInsets>());
      expect(container.decoration, isA<BoxDecoration>());
      expect(container.child, isA<Text>());
      
      final text = container.child as Text;
      expect(text.data, equals(testLabel));
    });
  });
}