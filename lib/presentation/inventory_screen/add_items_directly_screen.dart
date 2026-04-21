import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../models/inventory_item_model.dart';
import '../../providers/catalogue_provider.dart';
import '../../services/business_profile_service.dart';
import '../../services/inventory_service.dart';
import '../../services/items_service.dart';
import '../../widgets/item_autocomplete_field.dart';

/// Add items directly to inventory (without raising a purchase invoice).
///
/// Search picks an existing inventory item, an existing catalogue item, or
/// creates a new catalogue entry on the fly. Each selected row carries a
/// quantity and unit cost; submitting fans out one stock-receive movement per
/// row, creating the linked inventory item first if it doesn't exist yet.
class AddItemsDirectlyScreen extends StatefulWidget {
  const AddItemsDirectlyScreen({super.key});

  @override
  State<AddItemsDirectlyScreen> createState() => _AddItemsDirectlyScreenState();
}

class _AddItemsDirectlyScreenState extends State<AddItemsDirectlyScreen> {
  final InventoryService _inventoryService = InventoryService();

  /// Keyed by a stable selection key (catalog id or inventory id) so the same
  /// item can't appear twice in the list.
  final Map<String, _SelectedRow> _selected = {};
  bool _submitting = false;

  void _handleSelection(ItemAutocompleteResult result) {
    final key = _keyFor(result);
    setState(() {
      _selected.putIfAbsent(key, () => _SelectedRow.fromResult(result));
    });
  }

  String _keyFor(ItemAutocompleteResult r) {
    if (r.inventoryItem != null) return 'inv:${r.inventoryItem!.id}';
    if (r.catalogueItem != null) return 'cat:${r.catalogueItem!.id}';
    return 'name:${r.name.toLowerCase()}';
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      // Snapshot existing inventory so we can match catalogue picks that have
      // already been promoted to inventory under the hood (e.g. catalogItemId
      // link) without creating duplicates.
      final inventory = await _inventoryService.getAllItems();
      final byCatalogId = <String, InventoryItem>{
        for (final i in inventory)
          if (i.catalogItemId != null) i.catalogItemId!: i,
      };

      for (final row in _selected.values) {
        if (row.quantity <= 0) continue;

        InventoryItem invItem;
        if (row.inventoryItem != null) {
          invItem = row.inventoryItem!;
        } else {
          final catalogue = row.catalogueItem!;
          final existing = byCatalogId[catalogue.id];
          if (existing != null) {
            invItem = existing;
          } else {
            invItem = InventoryItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              sku: catalogue.sku,
              name: catalogue.name,
              unit: catalogue.unit,
              openingStock: 0.0,
              currentStock: 0.0,
              reorderPoint: 0.0,
              avgCost: row.unitCost,
              category: catalogue.category,
              lastUpdated: DateTime.now(),
              barcode: catalogue.barcode,
              catalogItemId: catalogue.id,
            );
            await _inventoryService.addItem(invItem);
          }
        }

        await _inventoryService.receiveStock(
          invItem.id,
          row.quantity,
          row.unitCost,
          'direct_add:${DateTime.now().microsecondsSinceEpoch}',
        );
      }

      await BusinessProfileService.instance.markOnboardingComplete();
      if (!mounted) return;
      context.read<CatalogueProvider>().invalidate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selected.length} item(s) added to inventory'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Items to Inventory'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: ItemAutocompleteField(
                mode: AutocompleteMode.purchase,
                autofocus: true,
                onSelected: _handleSelection,
                decoration: const InputDecoration(
                  hintText: 'Search or add a new item',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _selected.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      children: _selected.entries
                          .map((e) => _SelectedRowTile(
                                key: ValueKey(e.key),
                                row: e.value,
                                onChanged: () => setState(() {}),
                                onRemove: () => setState(() => _selected.remove(e.key)),
                              ))
                          .toList(),
                    ),
            ),
            if (_selected.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.add_box),
                      label: Text(
                        _submitting
                            ? 'Adding...'
                            : 'Add ${_selected.length} item(s) to Inventory',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedRow {
  _SelectedRow({
    required this.name,
    required this.sku,
    required this.unit,
    required this.unitCost,
    required this.quantity,
    this.inventoryItem,
    this.catalogueItem,
  });

  final String name;
  final String sku;
  final String unit;
  double unitCost;
  double quantity;
  final InventoryItem? inventoryItem;
  final ProductCatalogItem? catalogueItem;

  factory _SelectedRow.fromResult(ItemAutocompleteResult r) => _SelectedRow(
        name: r.name,
        sku: r.sku,
        unit: r.unit,
        unitCost: r.rate,
        quantity: 1,
        inventoryItem: r.inventoryItem,
        catalogueItem: r.catalogueItem,
      );
}

class _SelectedRowTile extends StatefulWidget {
  const _SelectedRowTile({
    super.key,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final _SelectedRow row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_SelectedRowTile> createState() => _SelectedRowTileState();
}

class _SelectedRowTileState extends State<_SelectedRowTile> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: _fmt(widget.row.quantity));
    _costCtrl = TextEditingController(text: _fmt(widget.row.unitCost));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final isNew = widget.row.inventoryItem == null;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.row.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${widget.row.sku} • ${widget.row.unit}',
                          style: TextStyle(
                              fontSize: 11.sp, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (isNew)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 2.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('New',
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600)),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      widget.row.quantity = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Unit cost (₹)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      widget.row.unitCost = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 18.w, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          Text(
            'Search above to start adding items',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
