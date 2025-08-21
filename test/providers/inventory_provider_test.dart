import 'package:flutter_test/flutter_test.dart';
import '../../lib/providers/inventory_provider.dart';

void main() {
  group('InventoryProvider Tests', () {
    late InventoryProvider provider;

    setUp(() {
      provider = InventoryProvider();
    });

    test('should load item successfully', () async {
      expect(provider.isLoading, false);
      expect(provider.title, '');

      final future = provider.load('test_item');
      expect(provider.isLoading, true);

      await future;
      expect(provider.isLoading, false);
      expect(provider.title, isNotEmpty);
    });

    test('should receive stock correctly', () async {
      await provider.load('test_item');
      final initialStock = provider.currentStock;

      await provider.receive(10.0, 50.0);

      expect(provider.currentStock, initialStock + 10.0);
      expect(provider.movements.first.type.name, 'IN');
      expect(provider.movements.first.quantity, 10.0);
    });

    test('should issue stock correctly', () async {
      await provider.load('test_item');
      final initialStock = provider.currentStock;

      await provider.issue(5.0);

      expect(provider.currentStock, initialStock - 5.0);
      expect(provider.movements.first.type.name, 'OUT');
      expect(provider.movements.first.quantity, -5.0);
    });

    test('should prevent issuing more stock than available', () async {
      await provider.load('test_item');
      final initialStock = provider.currentStock;

      expect(
        () => provider.issue(initialStock + 10.0),
        throwsException,
      );
    });

    test('should adjust stock correctly', () async {
      await provider.load('test_item');
      final initialStock = provider.currentStock;
      final delta = 100.0 - initialStock;

      await provider.adjust(delta, 'test adjustment');

      expect(provider.currentStock, 100.0);
      expect(provider.movements.first.type.name, 'ADJUSTMENT');
    });
  });
}