import 'package:flutter/material.dart';
import 'returned_item_model.dart';

// Enum to distinguish between return types
enum ReturnType { sales, purchase }

class ReturnSummaryScreen extends StatefulWidget {
  final ReturnType returnType;
  final double originalValue;
  final double returnedGoodsValue;
  final List<ReturnedItem> returnedItems;

  const ReturnSummaryScreen({
    super.key,
    required this.returnType,
    required this.originalValue,
    required this.returnedGoodsValue,
    required this.returnedItems,
  });

  @override
  State<ReturnSummaryScreen> createState() => _ReturnSummaryScreenState();
}

class _ReturnSummaryScreenState extends State<ReturnSummaryScreen> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.returnedGoodsValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSalesReturn = widget.returnType == ReturnType.sales;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSalesReturn ? 'Sales Return Summary' : 'Purchase Return Summary',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(theme, isSalesReturn),
            const SizedBox(height: 24),
            _buildInventorySection(theme, isSalesReturn),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Handle confirmation logic
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                // You can use this value for your business logic
                print('Confirmed Return. Amount: $amount');
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm Return'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isSalesReturn) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              label: isSalesReturn
                  ? 'Original Sales Value:'
                  : 'Original Purchase Cost:',
              value: '₹${widget.originalValue.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              label: 'Value of Returned Goods:',
              value: '₹${widget.returnedGoodsValue.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildAmountInputRow(
              label: isSalesReturn
                  ? 'Amount Refunded (if any):'
                  : 'Amount Expected from Distributor (if any):',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(ThemeData theme, bool isSalesReturn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSalesReturn
                  ? Icons.replay_circle_filled_outlined
                  : Icons.upload_outlined,
              color: isSalesReturn ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isSalesReturn
                  ? 'Inventory Adjusted (items added back to stock):'
                  : 'Inventory Adjusted (items removed from stock):',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.returnedItems.length,
            itemBuilder: (context, index) {
              final item = widget.returnedItems[index];
              return ListTile(
                title: Text(item.name),
                trailing: Text('Qty: ${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildAmountInputRow(
          {required String label, required ThemeData theme}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: Text(label, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              ),
            ),
          ),
        ],
      );
}