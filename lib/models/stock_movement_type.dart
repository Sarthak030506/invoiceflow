enum StockMovementType {
  purchase,
  sale,
  adjustment,
  return_in,
  return_out;

  String toDisplayString() {
    return name.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
  
  @override
  String toString() => toDisplayString();
}

extension StockMovementTypeX on StockMovementType {
  bool get isInbound => this == StockMovementType.purchase || 
                       this == StockMovementType.return_in;
                       
  bool get isOutbound => this == StockMovementType.sale || 
                        this == StockMovementType.return_out;
}
