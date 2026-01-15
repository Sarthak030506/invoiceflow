import 'package:flutter/material.dart';
import 'package:invoiceflow/models/ocr_scan_model.dart';

class OCRResultsSheet extends StatefulWidget {
  final OCRScanModel scan;

  const OCRResultsSheet({super.key, required this.scan});

  @override
  State<OCRResultsSheet> createState() => _OCRResultsSheetState();
}

class _OCRResultsSheetState extends State<OCRResultsSheet> {
  late List<ExtractedItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.scan.extractedData?.items ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Scanned Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and confirm the matched items',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Items list
              Expanded(
                child: _items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return _buildItemCard(_items[index], index);
                        },
                      ),
              ),

              // Bottom info & action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  children: [
                    // Summary
                    if (widget.scan.extractedData?.totalAmount != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${widget.scan.extractedData!.totalAmount!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Create invoice button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _items.isEmpty ? null : _createInvoice,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Create Invoice'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No items detected',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try scanning again with better lighting',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ExtractedItem item, int index) {
    final hasMatch = item.hasMatch;
    final confidence = item.confidence;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OCR extracted text
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned: ${item.rawText}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Matched item name or no match message
                      if (hasMatch) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.matchedItemName!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          item.rawText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditDialog(item, index),
                  tooltip: 'Edit item',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Match confidence indicator
            if (hasMatch) ...[
              Row(
                children: [
                  Icon(
                    item.isHighConfidence
                        ? Icons.check_circle
                        : item.isMediumConfidence
                            ? Icons.check_circle_outline
                            : Icons.help_outline,
                    size: 16,
                    color: item.isHighConfidence
                        ? Colors.green
                        : item.isMediumConfidence
                            ? Colors.orange
                            : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.isHighConfidence
                        ? 'Excellent match'
                        : item.isMediumConfidence
                            ? 'Good match'
                            : 'Fair match - verify',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isHighConfidence
                          ? Colors.green[700]
                          : item.isMediumConfidence
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(confidence * 100).toInt()}% confident',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.grey[200],
                color: item.isHighConfidence
                    ? Colors.green
                    : item.isMediumConfidence
                        ? Colors.orange
                        : Colors.red,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'No match found - will create new item',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Quantity and price
            if (item.quantity != null || item.price != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.quantity != null) ...[
                    Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (item.price != null) ...[
                    Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '₹${item.price!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ExtractedItem item, int index) {
    // TODO: Show dialog to manually select different item from catalog
    // For now, just show info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Text('Manual item selection coming soon!\n\nCurrent: ${item.rawText}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createInvoice() {
    // TODO: Navigate to invoice creation with pre-filled data
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invoice creation from OCR coming soon!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}
