import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceflow/presentation/analytics_redesign/analytics_redesign_scaffold.dart';
import 'package:invoiceflow/services/analytics_service.dart';
import 'package:invoiceflow/services/inventory_service.dart';
import 'package:sizer/sizer.dart';

// Mock Services
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<List<Map<String, dynamic>>> getFilteredAnalytics(String range, {bool salesOnly = true}) async {
    return [
      {'label': 'Revenue', 'value': 1000.0, 'delta': 5.0},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerWiseRevenue(String range, {bool salesOnly = true}) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> fetchPerformanceInsights(String range) async {
    return {
      'insights': {'totalClients': 10},
      'trends': {'revenueChange': 10.0},
    };
  }

  @override
  Future<Map<String, dynamic>> getChartAnalytics(String range) async {
    return {
      'salesVsPurchases': {'sales': 5000.0, 'purchases': 2000.0},
      'outstandingPayments': {'remaining': 1500.0},
      'revenueTrend': [],
      'topSellingItems': [],
    };
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockInventoryService implements InventoryService {
  @override
  Future<Map<String, dynamic>> getInventoryAnalytics() async {
    return {
      'totalItems': 50,
      'totalValue': 25000.0,
      'lowStockCount': 5,
      'fastMovingItems': <Map<String, dynamic>>[],
      'slowMovingItems': <Map<String, dynamic>>[],
      'averageStockValue': 500.0,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Sanity check: Container renders', (WidgetTester tester) async {
    await tester.pumpWidget(Container());
  });

  testWidgets('Sanity check: Sizer renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(home: Container());
        },
      ),
    );
  });

  testWidgets('AnalyticsRedesignScaffold renders and loads data', (WidgetTester tester) async {
    // Set screen size to avoid overflow
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange
    final mockAnalyticsService = MockAnalyticsService();
    final mockInventoryService = MockInventoryService();

    // Act
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: AnalyticsRedesignScaffold(
              analyticsService: mockAnalyticsService,
              inventoryService: mockInventoryService,
            ),
          );
        },
      ),
    );

    // Assert - Initial loading state (Skeleton loaders)
    await tester.pump(); // Start animation

    // Wait for futures to complete
    await tester.pumpAndSettle();

    // Assert - Loaded state
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Inventory Analytics'), findsOneWidget);
    
    // Verify data rendering
    expect(find.textContaining('5.0K'), findsOneWidget);
    
    // Verify Inventory Data
    expect(find.text('Inventory Summary'), findsOneWidget);
    expect(find.text('50'), findsOneWidget); // Total items
  });
}
