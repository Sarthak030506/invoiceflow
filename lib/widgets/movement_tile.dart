import 'package:flutter/material.dart';
import '../models/stock_movement_model.dart';

class MovementTile extends StatelessWidget {
  final StockMovement movement;

  const MovementTile({Key? key, required this.movement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildMovementBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movement.quantity > 0 ? '+' : ''}${movement.quantity.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(movement.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _getMovementSource(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (movement.type == StockMovementType.IN && movement.unitCost > 0)
            Text(
              '₹${movement.unitCost.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovementBadge() {
    Color color;
    String label;
    
    switch (movement.type) {
      case StockMovementType.IN:
        color = Colors.green;
        label = 'IN';
        break;
      case StockMovementType.OUT:
        color = Colors.red;
        label = 'OUT';
        break;
      case StockMovementType.RETURN_IN:
        color = Colors.green;
        label = 'IN';
        break;
      case StockMovementType.RETURN_OUT:
        color = Colors.orange;
        label = 'OUT';
        break;
      case StockMovementType.ADJUSTMENT:
        color = Colors.grey;
        label = 'ADJ';
        break;
      default:
        color = Colors.grey;
        label = 'ADJ';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getMovementTitle() {
    switch (movement.type) {
      case StockMovementType.IN:
        return 'Receive';
      case StockMovementType.OUT:
        return 'Issue';
      case StockMovementType.RETURN_IN:
        return 'Return In';
      case StockMovementType.RETURN_OUT:
        return 'Return Out';
      case StockMovementType.ADJUSTMENT:
        return 'Adjustment';
      default:
        return 'Movement';
    }
  }

  String _getMovementSource() {
    switch (movement.sourceRefType.toLowerCase()) {
      case 'invoice':
        return 'Invoice #${movement.sourceRefId}';
      case 'purchase':
        return 'Purchase #${movement.sourceRefId}';
      case 'manual':
        return movement.sourceRefId.isNotEmpty ? movement.sourceRefId : 'Manual';
      case 'adjustment':
        return movement.sourceRefId.isNotEmpty ? movement.sourceRefId : 'Adjustment';
      default:
        return 'System';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}