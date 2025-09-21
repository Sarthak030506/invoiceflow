import 'stock_movement_type.dart';

class StockMovement {
  // ...existing code...
  StockMovementType type;
  int quantity;
  Item item;

  StockMovement(this.type, this.quantity, this.item);

  String getTypeDisplay() {
    return type.toDisplayString();
  }

  @override
  String toString() {
    return '${type.toDisplayString()}: $quantity ${item.unit}';
  }
}

class Item {
  String unit;

  Item(this.unit);
}