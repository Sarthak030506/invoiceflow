import 'package:flutter/material.dart';

class TotalSKUsModal extends StatelessWidget {
  const TotalSKUsModal({Key? key}) : super(key: key);

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
                Icon(Icons.inventory_2, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Total SKUs',
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
                _buildSKUCard('Rice Bag 25kg', 'RB25', 'In Stock', Colors.green),
                _buildSKUCard('Wheat Flour 10kg', 'WF10', 'Low Stock', Colors.orange),
                _buildSKUCard('Sugar 1kg', 'SG1', 'In Stock', Colors.green),
                _buildSKUCard('Cooking Oil 1L', 'CO1', 'Out of Stock', Colors.red),
                _buildSKUCard('Tea Powder 250g', 'TP250', 'In Stock', Colors.green),
                _buildSKUCard('Salt 1kg', 'SL1', 'In Stock', Colors.green),
                _buildSKUCard('Turmeric Powder', 'TU100', 'Low Stock', Colors.orange),
                _buildSKUCard('Red Chili Powder', 'RC100', 'In Stock', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSKUCard(String name, String sku, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: $sku',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}