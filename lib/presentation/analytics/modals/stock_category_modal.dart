import 'package:flutter/material.dart';

class StockCategoryModal extends StatelessWidget {
  const StockCategoryModal({Key? key}) : super(key: key);

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
                Icon(Icons.category, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Stock Value by Category',
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
                _buildCategoryCard('Groceries', '₹45,200', '36%', '28 items', Colors.green),
                _buildCategoryCard('Beverages', '₹28,500', '23%', '15 items', Colors.blue),
                _buildCategoryCard('Spices & Condiments', '₹22,800', '18%', '22 items', Colors.orange),
                _buildCategoryCard('Personal Care', '₹15,600', '13%', '18 items', Colors.purple),
                _buildCategoryCard('Household Items', '₹8,900', '7%', '12 items', Colors.teal),
                _buildCategoryCard('Others', '₹3,500', '3%', '8 items', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, String value, String percentage, String itemCount, Color color) {
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
            child: Icon(Icons.category, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount • $percentage of total',
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}