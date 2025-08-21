import 'package:flutter/material.dart';
import '../services/invoice_service.dart';
import '../services/inventory_service.dart';
import '../services/event_service.dart';
import '../models/invoice_model.dart';

class InvoiceCancellationDialog extends StatefulWidget {
  final String invoiceId;
  final VoidCallback? onCancelled;

  const InvoiceCancellationDialog({
    Key? key,
    required this.invoiceId,
    this.onCancelled,
  }) : super(key: key);

  @override
  State<InvoiceCancellationDialog> createState() => _InvoiceCancellationDialogState();
}

class _InvoiceCancellationDialogState extends State<InvoiceCancellationDialog> {
  final InvoiceService _invoiceService = InvoiceService.instance;
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _reasonController = TextEditingController();
  
  bool _isLoading = false;
  bool _showAdminOverride = false;
  Map<String, dynamic>? _validationResult;
  InvoiceModel? _invoice;
  int _affectedItemsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInvoiceAndValidate();
  }

  Future<void> _loadInvoiceAndValidate() async {
    setState(() => _isLoading = true);
    
    try {
      final invoice = await _invoiceService.getInvoiceById(widget.invoiceId);
      final result = await _invoiceService.validateInvoiceCancellation(widget.invoiceId);
      
      setState(() {
        _invoice = invoice;
        _validationResult = result;
        _showAdminOverride = !result['canCancel'];
        _affectedItemsCount = invoice?.items.length ?? 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelInvoice({bool adminOverride = false}) async {
    setState(() => _isLoading = true);
    
    try {
      if (adminOverride) {
        await _invoiceService.cancelInvoiceWithAdminOverride(
          widget.invoiceId,
          _reasonController.text.trim(),
        );
      } else {
        await _invoiceService.cancelInvoice(widget.invoiceId);
      }
      
      Navigator.of(context).pop();
      
      // Trigger events for UI refresh
      _triggerRefreshEvents();
      
      widget.onCancelled?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancellation failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _triggerRefreshEvents() {
    final eventService = EventService();
    eventService.triggerInventoryUpdated();
    eventService.triggerDashboardUpdated();
  }

  void _showStockUsage() {
    final issues = _validationResult!['negativeStockIssues'] as List<Map<String, dynamic>>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Usage Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.orange),
                title: Text(issue['itemName']),
                subtitle: Text(
                  'Current: ${issue['currentStock']} → Would become: ${issue['resultingStock']}',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Invoice'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    if (_validationResult == null || _invoice == null) return const SizedBox.shrink();

    final canCancel = _validationResult!['canCancel'] as bool;
    
    if (canCancel && _invoice!.invoiceType == 'purchase') {
      return Text(
        'Cancelling this invoice will remove received stock for $_affectedItemsCount items. Proceed?',
        style: const TextStyle(fontSize: 16),
      );
    } else if (canCancel) {
      return const Text('This invoice can be cancelled safely. Continue?');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Cannot cancel - stock would go negative',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Negative stock issues
        if (_validationResult!['negativeStockIssues'].isNotEmpty) ...[
          const Text('• Insufficient stock for items:'),
          const SizedBox(height: 8),
          ..._buildNegativeStockItems(),
          const SizedBox(height: 12),
        ],
        
        // Dependent documents
        if (_validationResult!['dependentDocuments'].isNotEmpty) ...[
          const Text('• Dependent documents exist:'),
          const SizedBox(height: 8),
          ..._buildDependentDocuments(),
          const SizedBox(height: 12),
        ],
        
        const Text(
          'Resolve by issuing return-in, adjusting stock, or reversing dependents first.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        
        if (_showAdminOverride) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Admin Override:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for override',
              hintText: 'Enter reason for allowing negative stock...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildNegativeStockItems() {
    final issues = _validationResult!['negativeStockIssues'] as List<Map<String, dynamic>>;
    return issues.map((issue) => Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        '${issue['itemName']}: Current ${issue['currentStock']}, '
        'would become ${issue['resultingStock']}',
        style: const TextStyle(fontSize: 12),
      ),
    )).toList();
  }

  List<Widget> _buildDependentDocuments() {
    final dependents = _validationResult!['dependentDocuments'] as List<String>;
    return dependents.map((doc) => Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(doc, style: const TextStyle(fontSize: 12)),
    )).toList();
  }

  List<Widget> _buildActions() {
    if (_isLoading) return [];

    final canCancel = _validationResult?['canCancel'] as bool? ?? false;
    final hasNegativeStock = _validationResult?['negativeStockIssues']?.isNotEmpty ?? false;

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      
      if (hasNegativeStock) 
        TextButton(
          onPressed: _showStockUsage,
          child: const Text('View Stock Usage'),
        )
      else if (canCancel)
        ElevatedButton(
          onPressed: () => _cancelInvoice(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Proceed'),
        ),
      
      if (_showAdminOverride && !hasNegativeStock)
        ElevatedButton(
          onPressed: _reasonController.text.trim().isNotEmpty
              ? () => _cancelInvoice(adminOverride: true)
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Override & Cancel'),
        ),
    ];
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}