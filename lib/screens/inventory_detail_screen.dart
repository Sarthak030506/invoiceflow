import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/stock_movement_model.dart';
import '../constants/strings.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String itemId;

  const InventoryDetailScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<double> _stockAnimation;
  late Animation<double> _valueAnimation;
  double _lastStock = 0.0;
  double _lastValue = 0.0;

  @override
  void initState() {
    super.initState();
    _countController =
        AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _stockAnimation = Tween<double>(begin: 0, end: 0).animate(_countController);
    _valueAnimation = Tween<double>(begin: 0, end: 0).animate(_countController);

    // Load item using your provider's load method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).load(widget.itemId);
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _startCountAnimations(double stock, double value) {
    _countController.reset();
    _stockAnimation = Tween<double>(begin: 0.0, end: stock)
        .animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));
    _valueAnimation = Tween<double>(begin: 0.0, end: value)
        .animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));
    _countController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<InventoryProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());

            if (provider.title.isEmpty) return Center(child: Text(AppStrings.itemNotFound));

            // restart animations only when values change
            if (provider.currentStock != _lastStock || provider.inventoryValue != _lastValue) {
              _lastStock = provider.currentStock;
              _lastValue = provider.inventoryValue;
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _startCountAnimations(provider.currentStock, provider.inventoryValue));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(provider.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(provider.sku,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey)),
                            ]),
                      ),
                      IconButton(
                        onPressed: () async {
                          await provider.load(widget.itemId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshed'), duration: Duration(seconds: 1)),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                      IconButton(onPressed: () => _showEditDialog(provider), icon: const Icon(Icons.edit)),
                      IconButton(
                        onPressed: () => _showDeleteDialog(provider),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _SummaryCard(
                            stockAnimation: _stockAnimation,
                            valueAnimation: _valueAnimation,
                            stock: provider.currentStock,
                            unit: provider.unit,
                            reorderPoint: provider.reorderPoint,
                            avgCost: provider.avgCost,
                            inventoryValue: provider.inventoryValue,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(
                                  icon: Icons.category_outlined,
                                  label: AppStrings.category,
                                  value: provider.category),
                              _InfoPill(icon: Icons.straighten, label: AppStrings.unit, value: provider.unit),
                              _InfoPill(
                                  icon: Icons.warning_amber_outlined,
                                  label: AppStrings.reorderPoint,
                                  value: provider.reorderPoint.toInt().toString()),
                              _InfoPill(
                                  icon: Icons.qr_code,
                                  label: 'Barcode',
                                  value: provider.barcode.isEmpty ? 'Not set' : provider.barcode),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                  child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text('Receive'),
                                      onPressed: () => _showReceiveDialog(provider))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                                      icon: const Icon(Icons.remove),
                                      label: const Text('Issue'),
                                      onPressed: () => _showIssueDialog(provider))),
                              const SizedBox(width: 10),
                              InkWell(
                                  onTap: () => _showAdjustDialog(provider),
                                  child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.tune))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(AppStrings.recentMovements,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: provider.movements.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(AppStrings.noMovements, style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: provider.movements
                                      .map((m) => _MovementTile(movement: m, unit: provider.unit))
                                      .toList(),
                                ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),


    );
  }

  // ---------------- Dialogs ----------------

  void _showReceiveDialog(InventoryProvider provider) {
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(text: provider.avgCost.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Form(
            key: formKey,
            child:
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RECEIVE STOCK', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: AppStrings.quantity, border: const OutlineInputBorder()),
                  validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) <= 0) ? 'Enter qty > 0' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Unit cost', border: OutlineInputBorder(), prefixText: '₹'),
                  validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) < 0) ? 'Enter valid cost' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final qty = double.parse(qtyCtrl.text);
                      final cost = double.parse(costCtrl.text);
                      Navigator.pop(ctx);
                      try {
                        await provider.receive(qty, cost);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Received ${qty.toInt()} ${provider.unit}'),
                          action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                try {
                                  await provider.issue(qty);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Undo successful')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Undo failed: $e'), backgroundColor: Colors.red));
                                }
                              }),
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Receive failed: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: Text(AppStrings.confirm),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
    );
  }

  void _showIssueDialog(InventoryProvider provider) {
    final qtyCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Form(
            key: formKey,
            child:
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ISSUE STOCK', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: AppStrings.quantity, border: const OutlineInputBorder()),
                  validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) <= 0) ? 'Enter qty > 0' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final qty = double.parse(qtyCtrl.text);
                      Navigator.pop(ctx);
                      try {
                        await provider.issue(qty);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Issued ${qty.toInt()} ${provider.unit}'),
                          action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                try {
                                  await provider.receive(qty, provider.avgCost);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(content: Text('Undo successful')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Undo failed: $e'), backgroundColor: Colors.red));
                                }
                              }),
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Issue failed: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: Text(AppStrings.confirm),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAdjustDialog(InventoryProvider provider) {
    final deltaCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();
    bool allowNegative = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setState2) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ADJUST STOCK', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                    controller: deltaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Delta (positive add, negative remove)', border: OutlineInputBorder()),
                    validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) == 0) ? 'Enter non-zero delta' : null),
                const SizedBox(height: 12),
                TextFormField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason required' : null),
                const SizedBox(height: 8),
                Row(children: [
                  Checkbox(value: allowNegative, onChanged: (val) => setState2(() => allowNegative = val ?? false)),
                  const SizedBox(width: 6),
                  const Text('Allow negative stock (override)'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final delta = double.parse(deltaCtrl.text);
                        final reason = reasonCtrl.text.trim();
                        Navigator.pop(ctx);
                        try {
                          await provider.adjust(delta, reason, override: allowNegative);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Adjusted ${delta >= 0 ? '+' : ''}${delta.toInt()} ${provider.unit}')));
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Adjust failed: $e'), backgroundColor: Colors.red));
                        }
                      },
                      child: Text(AppStrings.confirm),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        );
      }),
    );
  }

  // ---------------- Edit dialog ----------------

  void _showEditDialog(InventoryProvider provider) {
    final titleCtrl = TextEditingController(text: provider.title);
    final skuCtrl = TextEditingController(text: provider.sku);
    final unitCtrl = TextEditingController(text: provider.unit);
    final categoryCtrl = TextEditingController(text: provider.category);
    final reorderCtrl = TextEditingController(text: provider.reorderPoint.toInt().toString());
    final barcodeCtrl = TextEditingController(text: provider.barcode);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 10),
              TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit')),
              const SizedBox(height: 10),
              TextFormField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 10),
              TextFormField(controller: reorderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Point')),
              const SizedBox(height: 10),
              TextFormField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final rp = double.tryParse(reorderCtrl.text) ?? 0.0;
              Navigator.pop(ctx);
              try {
                await provider.updateItem(
                  title: titleCtrl.text.trim(),
                  sku: skuCtrl.text.trim(),
                  unit: unitCtrl.text.trim(),
                  category: categoryCtrl.text.trim(),
                  reorderPoint: rp,
                  barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'), // AppStrings.save was missing — use a literal
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${provider.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteItem();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${provider.title}" deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Local UI widgets (you can replace these with your widgets)

class _SummaryCard extends StatelessWidget {
  final Animation<double> stockAnimation;
  final Animation<double> valueAnimation;
  final double stock;
  final String unit;
  final double reorderPoint;
  final double avgCost;
  final double inventoryValue;

  const _SummaryCard({
    Key? key,
    required this.stockAnimation,
    required this.valueAnimation,
    required this.stock,
    required this.unit,
    required this.reorderPoint,
    required this.avgCost,
    required this.inventoryValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final low = stock <= reorderPoint;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (low)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(18)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
                    SizedBox(width: 6),
                    Text('Low Stock', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600))
                  ]),
                ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                  animation: stockAnimation,
                  builder: (_, __) => Text('${stockAnimation.value.toInt()} $unit',
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.deepOrange, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              Text('Current stock', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 6),
              Text('Reorder at ${reorderPoint.toInt()}', style: theme.textTheme.bodySmall),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Avg Cost', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 6),
            Text('₹${avgCost.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text('Inventory Value', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 6),
            AnimatedBuilder(animation: valueAnimation, builder: (_, __) => Text('₹${valueAnimation.value.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.w600))),
          ]),
        ]),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoPill({Key? key, required this.icon, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 56) / 2;
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))
          ]),
        ),
      ]),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final dynamic movement; // dynamic to avoid compile-time mismatch with various model shapes
  final String unit;
  const _MovementTile({Key? key, required this.movement, required this.unit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final type = movement.type;
    final qty = (movement.quantity is num) ? movement.quantity.toDouble() : 0.0;
    final created = movement.createdAt ?? DateTime.now();
    // StockMovement doesn't have note field, use sourceRefId as description
    final note = movement.sourceRefId ?? '';
    final src = movement.sourceRefType ?? '';

    Color color = Colors.grey;
    if (type == StockMovementType.IN) color = Colors.green;
    if (type == StockMovementType.OUT) color = Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(_getTypeText(type), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
        title: Text('${qty.toInt()} $unit - ${_movementTitle(type)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${created.day}/${created.month}/${created.year} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}'),
          if (note.isNotEmpty) Text(note, style: const TextStyle(color: Colors.grey))
        ]),
        trailing: src != null && src.toString().isNotEmpty ? Text(src.toString(), style: const TextStyle(fontSize: 13, color: Colors.grey)) : null,
      ),
    );
  }

  String _getTypeText(dynamic type) {
    if (type == StockMovementType.IN) return 'IN';
    if (type == StockMovementType.OUT) return 'OUT';
    if (type == StockMovementType.ADJUSTMENT) return 'ADJ';
    if (type == StockMovementType.RETURN_IN) return 'RET+';
    if (type == StockMovementType.RETURN_OUT) return 'RET-';
    if (type == StockMovementType.REVERSAL_OUT) return 'REV';
    return 'M';
  }

  String _movementTitle(dynamic type) {
    if (type == StockMovementType.IN) return 'Receive';
    if (type == StockMovementType.OUT) return 'Issue';
    if (type == StockMovementType.ADJUSTMENT) return 'Adjustment';
    return 'Movement';
  }
}

class _StickyActionBar extends StatelessWidget {
  final VoidCallback onReceive;
  final VoidCallback onIssue;
  final VoidCallback onAdjust;

  const _StickyActionBar({Key? key, required this.onReceive, required this.onIssue, required this.onAdjust})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: onReceive, icon: const Icon(Icons.add_business_outlined), label: const Text('Receive'))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(onPressed: onIssue, icon: const Icon(Icons.remove_circle_outline), label: const Text('Issue'))),
        const SizedBox(width: 10),
        InkWell(onTap: onAdjust, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.tune))),
      ]),
    );
  }
}
