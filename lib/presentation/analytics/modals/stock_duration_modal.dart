import 'package:flutter/material.dart';

class StockDurationModal extends StatelessWidget {
  const StockDurationModal({Key? key}) : super(key: key);

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
                Icon(Icons.schedule, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Stock Duration Analysis',
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
                _buildDurationCard('Rice Bag 25kg', '15 days', 'Fast moving', Colors.green),
                _buildDurationCard('Sugar 1kg', '18 days', 'Fast moving', Colors.green),
                _buildDurationCard('Tea Powder 250g', '22 days', 'Medium moving', Colors.orange),
                _buildDurationCard('Salt 1kg', '25 days', 'Medium moving', Colors.orange),
                _buildDurationCard('Wheat Flour 10kg', '32 days', 'Slow moving', Colors.red),
                _buildDurationCard('Cooking Oil 1L', '35 days', 'Slow moving', Colors.red),
                _buildDurationCard('Turmeric Powder', '42 days', 'Very slow', Colors.red.shade700),
                _buildDurationCard('Red Chili Powder', '45 days', 'Very slow', Colors.red.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(String name, String duration, String category, Color color) {
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
            child: Icon(Icons.schedule, color: Colors.white, size: 20),
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
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              duration,
              style: const TextStyle(
                color: Colors.white,
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