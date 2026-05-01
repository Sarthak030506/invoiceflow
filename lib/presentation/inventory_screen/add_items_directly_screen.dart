import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../models/inventory_item_model.dart';
import '../../providers/catalogue_provider.dart';
import '../../services/business_profile_service.dart';
import '../../services/inventory_service.dart';
import '../../services/items_service.dart';
import '../../widgets/catalogue_browse_list.dart';
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

  /// Keyed by stable selection key (`inv:<id>` / `cat:<id>` / `name:<lower>`).
  final Map<String, _SelectedRow> _selected = {};
  List<InventoryItem> _inventory = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBrowseData());
  }

  Future<void> _loadBrowseData() async {
    if (!mounted) return;
    context.read<CatalogueProvider>().load();
    try {
      final items = await _inventoryService.getAllItems();
      if (mounted) setState(() => _inventory = items);
    } catch (_) {}
  }

  String _keyFor(ItemAutocompleteResult r) {
    if (r.inventoryItem != null) return 'inv:${r.inventoryItem!.id}';
    if (r.catalogueItem != null) return 'cat:${r.catalogueItem!.id}';
    return 'name:${r.name.toLowerCase()}';
  }

  void _handleSelection(ItemAutocompleteResult result) {
    final key = _keyFor(result);
    setState(() {
      _selected.putIfAbsent(key, () => _SelectedRow.fromResult(result));
    });
  }

  Future<void> _submit() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
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
                decoration: InputDecoration(
                  hintText: 'Search or add a new item',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            Expanded(
              child: CatalogueBrowseList(
                isSales: false,
                accent: Colors.green,
                inventory: _inventory,
                selectedQtys: {
                  for (final e in _selected.entries) e.key: e.value.quantity
                },
                onSelected: _handleSelection,
                onDeselected: (key) => setState(() => _selected.remove(key)),
                onQtyChanged: (key, qty) => setState(() {
                  if (_selected.containsKey(key)) _selected[key]!.quantity = qty;
                }),
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
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
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

// ---------------------------------------------------------------------------
// Data model for a selected inventory-receive row
// ---------------------------------------------------------------------------

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
