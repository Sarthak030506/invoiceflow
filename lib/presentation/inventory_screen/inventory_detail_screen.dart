import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/stock_movement_model.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String itemId;

  const InventoryDetailScreen({required this.itemId, super.key});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _slideController;
  late Animation<double> _stockAnimation;
  late Animation<double> _valueAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _animationsStarted = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'IN', 'OUT', 'ADJUST'];

  @override
  void initState() {
    super.initState();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      provider.load(widget.itemId);
    });
  }

  void _initAnimations() {
    _countController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _stockAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_countController);
    _valueAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_countController);

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAnimations(double stock, double value) {
    _countController.reset();
    _slideController.reset();

    _stockAnimation = Tween<double>(begin: 0.0, end: stock).animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));
    _valueAnimation = Tween<double>(begin: 0.0, end: value).animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));

    _countController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        // Start animations once when data appears
        if (!_animationsStarted && provider.title.isNotEmpty) {
          _animationsStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimations(provider.currentStock, provider.inventoryValue));
        }

        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Loading...'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.title.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Item Not Found'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Item not found', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text('The requested item could not be loaded.'),
                ],
              ),
            ),
          );
        }

        const double bottomBarHeight = 80.0;
        
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              provider.sku,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditDialog(provider),
                        icon: const Icon(Icons.edit_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () => _showBarcodeDialog(provider),
                        icon: const Icon(Icons.qr_code_2),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Main scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildSummaryCard(context, provider),
                            ),
                          ),
                        ),

                        // Info pills
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _infoPill(icon: Icons.category_outlined, label: 'Category', value: provider.category),
                              _infoPill(icon: Icons.straighten, label: 'Unit', value: provider.unit),
                              _infoPill(icon: Icons.notification_important_outlined, label: 'Reorder', value: provider.reorderPoint.toInt().toString()),
                              _infoPill(icon: Icons.qr_code, label: 'Barcode', value: provider.barcode.isEmpty ? 'Not set' : provider.barcode),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Movements header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Movements',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              // Filters
                              SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (c, i) {
                                    final label = _filters[i];
                                    final selected = label == _selectedFilter;
                                    return ChoiceChip(
                                      label: Text(
                                        label,
                                        style: TextStyle(
                                          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                      selected: selected,
                                      onSelected: (v) => setState(() => _selectedFilter = v ? label : 'All'),
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(
                                        color: selected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                                        width: selected ? 0 : 1,
                                      ),
                                      selectedColor: Theme.of(context).primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    );
                                  },
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemCount: _filters.length,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Movement list or empty state
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: provider.movements.isEmpty ? _emptyMovementState() : _buildMovementList(provider),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Bottom action bar
                Container(
                  height: bottomBarHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openStockForm(context, provider, 'receive'),
                          icon: const Icon(Icons.add_business_outlined, size: 20),
                          label: const Text('Receive'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openStockForm(context, provider, 'issue'),
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          label: const Text('Issue'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: IconButton(
                          onPressed: () => _openStockForm(context, provider, 'adjust'),
                          icon: const Icon(Icons.tune, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, InventoryProvider provider) {
    final theme = Theme.of(context);
    final low = provider.currentStock <= provider.reorderPoint;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (low)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Low Stock',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Stock info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _stockAnimation,
                      builder: (context, child) {
                        final val = _stockAnimation.value;
                        return Text(
                          '${val.toInt()} ${provider.unit}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current stock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reorder at ${provider.reorderPoint.toInt()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                
                // Right side - Cost info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Avg Cost',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${provider.avgCost.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Value',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _valueAnimation,
                      builder: (context, child) {
                        final val = _valueAnimation.value;
                        return Text(
                          '₹${val.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill({required IconData icon, required String label, required String value}) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50], 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]), 
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), 
                const SizedBox(height: 4), 
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
              ]
            )
          ),
        ]
      ),
    );
  }

  Widget _emptyMovementState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey[300]), 
          const SizedBox(height: 12), 
          Text('No movements yet — perform Receive, Issue or Adjust.', 
            style: TextStyle(color: Colors.grey[700]), 
            textAlign: TextAlign.center
          )
        ]
      ),
    );
  }

  Widget _buildMovementList(InventoryProvider provider) {
    final filtered = _getFilteredMovements(provider.movements);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (c, i) => _movementTile(filtered[i], provider),
      separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
    );
  }

  Widget _movementTile(dynamic movement, InventoryProvider provider) {
    final rawType = movement.type;
    final typeKey = _typeKey(rawType);
    final qty = movement.quantity ?? 0;
    final created = movement.createdAt;
    final note = movement.note ?? '';

    Color badgeColor = Colors.grey;
    if (typeKey.contains('IN')) badgeColor = Colors.green;
    if (typeKey.contains('OUT')) badgeColor = Colors.blue;
    if (typeKey.contains('ADJUST')) badgeColor = Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), 
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12), 
            borderRadius: BorderRadius.circular(8)
          ), 
          child: Text(typeKey.replaceAll('_', ' '), style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11))
        ),
        title: Text('${qty.toInt()} ${provider.unit} - ${_movementTitle(typeKey)}', 
          style: const TextStyle(fontWeight: FontWeight.w600)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(_movementSubtitle(created)), 
            if (note.isNotEmpty) Text(note, style: const TextStyle(color: Colors.grey))
          ]
        ),
      ),
    );
  }

  String _typeKey(dynamic type) {
    if (type == null) return '';
    // Normalize to a simple upper-case key like 'IN', 'OUT', 'ADJUSTMENT', 'RETURN_IN'
    final s = type.toString();
    // If enum, toString returns 'EnumName.value'
    final dot = s.lastIndexOf('.');
    final raw = dot != -1 ? s.substring(dot + 1) : s;
    return raw.toUpperCase();
  }

  String _movementTitle(dynamic type) {
    final t = _typeKey(type);
    if (t.contains('IN')) return 'Receive';
    if (t.contains('OUT')) return 'Issue';
    if (t.contains('ADJUST')) return 'Adjustment';
    return 'Movement';
  }

  String _movementSubtitle(DateTime? created) {
    if (created != null) {
      return '${created.day}/${created.month}/${created.year} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  List<dynamic> _getFilteredMovements(List<dynamic> movements) {
    if (_selectedFilter == 'All') return movements;
    final up = _selectedFilter.toUpperCase();
    return movements.where((m) {
      final t = _typeKey(m.type);
      if (up == 'IN') return t.contains('IN');
      if (up == 'OUT') return t.contains('OUT');
      if (up == 'ADJUST') return t.contains('ADJUST');
      return true;
    }).toList();
  }

  void _openStockForm(BuildContext context, InventoryProvider provider, String type) {
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController(text: provider.avgCost.toString());
    final reasonController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text('${type.toUpperCase()} Stock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyController, 
                keyboardType: TextInputType.number, 
                decoration: InputDecoration(labelText: 'Quantity *', border: const OutlineInputBorder()), 
                validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) <= 0) ? 'Enter positive quantity' : null
              ),
              if (type == 'receive') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: costController, 
                  keyboardType: TextInputType.number, 
                  decoration: const InputDecoration(labelText: 'Unit cost *', border: OutlineInputBorder(), prefixText: '₹'), 
                  validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) < 0) ? 'Enter valid cost' : null
                ),
              ],
              if (type == 'adjust') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController, 
                  decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()), 
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason required' : null
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController, 
                maxLines: 2, 
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => _submitStockForm(ctx, provider, type, formKey, qtyController, costController, reasonController, noteController), child: const Text('Confirm'))),
                ]
              ),
              const SizedBox(height: 8),
            ]
          ),
        ),
      ),
    );
  }

  Future<void> _submitStockForm(
    BuildContext ctx,
    InventoryProvider provider,
    String type,
    GlobalKey<FormState> formKey,
    TextEditingController qtyController,
    TextEditingController costController,
    TextEditingController reasonController,
    TextEditingController noteController,
  ) async {
    if (!formKey.currentState!.validate()) return;
    final q = double.parse(qtyController.text);
    final cost = double.tryParse(costController.text) ?? 0.0;
    final reason = reasonController.text.trim();
    final note = noteController.text.trim();

    final prevStock = provider.currentStock;

    Navigator.pop(ctx); // close modal while processing

    try {
      if (type == 'receive') {
        await provider.receive(q, cost, note: note);
      } else if (type == 'issue') {
        await provider.issue(q, note: note);
      } else {
        await provider.adjust(q, reason);
      }

      final newStock = provider.currentStock;
      final delta = newStock - prevStock;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${type.toUpperCase()} completed. Stock: ${newStock.toInt()} (${delta >= 0 ? '+' : ''}${delta.toInt()})'),
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'), 
        backgroundColor: Colors.red
      ));
    }
  }

  void _showEditDialog(InventoryProvider provider) {
    final nameCtrl = TextEditingController(text: provider.title);
    final skuCtrl = TextEditingController(text: provider.sku);
    final unitCtrl = TextEditingController(text: provider.unit);
    final catCtrl = TextEditingController(text: provider.category);
    final reorderCtrl = TextEditingController(text: provider.reorderPoint.toString());
    final barcodeCtrl = TextEditingController(text: provider.barcode);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 8),
                TextFormField(controller: reorderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Point')),
                const SizedBox(height: 8),
                TextFormField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode (optional)')),
              ]
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await provider.updateItem(
                  title: nameCtrl.text.trim(),
                  sku: skuCtrl.text.trim(),
                  unit: unitCtrl.text.trim(),
                  category: catCtrl.text.trim(),
                  reorderPoint: double.tryParse(reorderCtrl.text) ?? 0,
                  barcode: barcodeCtrl.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeDialog(InventoryProvider provider) {
    final barcodeCtrl = TextEditingController(text: provider.barcode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Barcode'),
        content: TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.updateItem(
                  title: provider.title,
                  sku: provider.sku,
                  unit: provider.unit,
                  category: provider.category,
                  reorderPoint: provider.reorderPoint,
                  barcode: barcodeCtrl.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode saved')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}