import 'package:flutter/material.dart';
import '../providers/inventory_provider.dart';

class SummaryCard extends StatelessWidget {
  final InventoryProvider provider;
  final Animation<double>? stockAnimation;
  final Animation<double>? valueAnimation;

  const SummaryCard({
    Key? key,
    required this.provider,
    this.stockAnimation,
    this.valueAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLowStock = provider.currentStock <= provider.reorderPoint;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Left column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLowStock)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Low Stock',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  AnimatedBuilder(
                    animation: stockAnimation ?? const AlwaysStoppedAnimation(0),
                    builder: (context, child) {
                      final value = stockAnimation?.value ?? provider.currentStock;
                      return Text(
                        '${value.toInt()} ${provider.unit}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLowStock ? Colors.orange.shade700 : Colors.grey.shade800,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Stock',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reorder at ${provider.reorderPoint.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Right column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${provider.avgCost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avg Cost',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: valueAnimation ?? const AlwaysStoppedAnimation(0),
                  builder: (context, child) {
                    final value = valueAnimation?.value ?? provider.inventoryValue;
                    return Text(
                      '₹${value.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Inventory Value',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}