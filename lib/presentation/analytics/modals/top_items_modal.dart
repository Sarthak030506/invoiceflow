import 'package:flutter/material.dart';

class TopItemsModal extends StatelessWidget {
  const TopItemsModal({Key? key}) : super(key: key);

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
                Icon(Icons.trending_up, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Top Selling Items',
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
                _buildTopItemCard(1, 'Rice Bag 25kg', '₹1,200', '15 units', Colors.amber),
                _buildTopItemCard(2, 'Wheat Flour 10kg', '₹950', '12 units', Colors.grey.shade400),
                _buildTopItemCard(3, 'Sugar 1kg', '₹780', '26 units', Colors.orange.shade300),
                _buildTopItemCard(4, 'Cooking Oil 1L', '₹650', '18 units', Colors.blue),
                _buildTopItemCard(5, 'Tea Powder 250g', '₹520', '22 units', Colors.green),
                _buildTopItemCard(6, 'Salt 1kg', '₹480', '24 units', Colors.purple),
                _buildTopItemCard(7, 'Turmeric Powder', '₹420', '14 units', Colors.teal),
                _buildTopItemCard(8, 'Red Chili Powder', '₹380', '16 units', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemCard(int rank, String itemName, String revenue, String quantity, Color color) {
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}