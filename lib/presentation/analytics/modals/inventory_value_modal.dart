import 'package:flutter/material.dart';

class InventoryValueModal extends StatelessWidget {
  const InventoryValueModal({Key? key}) : super(key: key);

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
                Icon(Icons.account_balance_wallet, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Inventory Value',
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
                _buildValueCard('Rice Bag 25kg', '15 units', '₹18,750', Colors.green),
                _buildValueCard('Wheat Flour 10kg', '22 units', '₹15,400', Colors.green),
                _buildValueCard('Sugar 1kg', '45 units', '₹13,500', Colors.green),
                _buildValueCard('Cooking Oil 1L', '28 units', '₹12,600', Colors.green),
                _buildValueCard('Tea Powder 250g', '35 units', '₹10,500', Colors.green),
                _buildValueCard('Salt 1kg', '60 units', '₹9,600', Colors.green),
                _buildValueCard('Turmeric Powder', '18 units', '₹7,200', Colors.green),
                _buildValueCard('Red Chili Powder', '25 units', '₹6,250', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String name, String quantity, String value, Color color) {
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
            child: Icon(Icons.inventory, color: Colors.white, size: 20),
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
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}