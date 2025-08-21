import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/screens/inventory_detail_screen.dart';
import '../../lib/providers/inventory_provider.dart';

void main() {
  group('InventoryDetailScreen Widget Tests', () {
    late InventoryProvider provider;

    setUp(() {
      provider = InventoryProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<InventoryProvider>(
          create: (_) => provider,
          child: const InventoryDetailScreen(itemId: 'test_item'),
        ),
      );
    }

    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display item details after loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 600));
      
      expect(find.text('Sample Product'), findsOneWidget);
      expect(find.text('ITEM001'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should show sticky action bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 600));
      
      expect(find.text('Receive'), findsOneWidget);
      expect(find.text('Issue'), findsOneWidget);
      expect(find.text('Adjust'), findsOneWidget);
    });

    testWidgets('should show empty state when no movements', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 600));
      
      // Wait for movements to load
      await tester.pump(const Duration(milliseconds: 400));
      
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should handle receive action', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 600));
      
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();
      
      expect(find.text('RECEIVE Stock'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
    });

    testWidgets('should be keyboard safe', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 600));
      
      // Simulate keyboard appearance
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      
      // Should not cause overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper tap targets', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 600));
      
      final receiveButton = find.text('Receive');
      final buttonSize = tester.getSize(receiveButton);
      
      // Should meet minimum 48px accessibility requirement
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
    });
  });
}