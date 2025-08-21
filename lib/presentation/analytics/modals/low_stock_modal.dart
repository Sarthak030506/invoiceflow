import 'package:flutter/material.dart';

class LowStockModal extends StatelessWidget {
  const LowStockModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Low-Stock Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildLowStockCard('Cooking Oil 1L', '0 units', '5 units', Colors.red),
                _buildLowStockCard('Wheat Flour 10kg', '2 units', '10 units', Colors.orange),
                _buildLowStockCard('Turmeric Powder', '3 units', '8 units', Colors.orange),
                _buildLowStockCard('Red Chili Powder', '4 units', '10 units', Colors.orange),
                _buildLowStockCard('Coconut Oil 500ml', '1 unit', '6 units', Colors.red),
                _buildLowStockCard('Basmati Rice 5kg', '2 units', '8 units', Colors.orange),
                _buildLowStockCard('Mustard Oil 1L', '1 unit', '5 units', Colors.red),
                _buildLowStockCard('Gram Flour 1kg', '3 units', '12 units', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(String name, String currentStock, String reorderPoint, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current: $currentStock | Reorder: $reorderPoint',
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'Reorder',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}