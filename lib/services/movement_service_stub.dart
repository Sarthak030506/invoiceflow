import '../models/stock_movement_model.dart';

class MovementServiceStub {
  Future<List<StockMovement>> getMovements(String itemId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return [
      StockMovement(
        id: '1',
        itemId: itemId,
        type: StockMovementType.IN,
        quantity: 50.0,
        unitCost: 150.0,
        sourceRefType: 'purchase',
        sourceRefId: 'PO001',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      StockMovement(
        id: '2',
        itemId: itemId,
        type: StockMovementType.OUT,
        quantity: -5.0,
        unitCost: 0.0,
        sourceRefType: 'invoice',
        sourceRefId: 'INV001',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      StockMovement(
        id: '3',
        itemId: itemId,
        type: StockMovementType.ADJUSTMENT,
        quantity: 0.0,
        unitCost: 0.0,
        sourceRefType: 'manual',
        sourceRefId: 'stock_count',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}