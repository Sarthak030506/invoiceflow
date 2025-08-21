import 'package:flutter/material.dart';

class ItemwiseOutstandingModal extends StatelessWidget {
  const ItemwiseOutstandingModal({Key? key}) : super(key: key);

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
                Icon(Icons.inventory, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Itemwise Outstanding',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(flex: 2, child: Text('Due Amount', style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(flex: 2, child: Text('Customers', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildItemRow('Rice Bag 25kg', '₹8,500', '3 customers'),
                _buildItemRow('Wheat Flour 10kg', '₹6,200', '4 customers'),
                _buildItemRow('Sugar 1kg', '₹4,800', '5 customers'),
                _buildItemRow('Cooking Oil 1L', '₹3,900', '2 customers'),
                _buildItemRow('Tea Powder 250g', '₹2,700', '3 customers'),
                _buildItemRow('Salt 1kg', '₹1,800', '4 customers'),
                _buildItemRow('Turmeric Powder', '₹1,200', '2 customers'),
                _buildItemRow('Red Chili Powder', '₹900', '2 customers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String item, String amount, String customers) {
    return GestureDetector(
      onTap: () {
        // Show customer breakdown for this item
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    customers,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}