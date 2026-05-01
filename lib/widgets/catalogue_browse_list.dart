import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../models/inventory_item_model.dart';
import '../providers/catalogue_provider.dart';
import '../services/items_service.dart';
import 'item_autocomplete_field.dart';

// ---------------------------------------------------------------------------
// Public browse list — cards with category chips and inline qty stepper.
// Used by both ChooseItemsInvoiceScreen and AddItemsDirectlyScreen.
//
// [selectedQtys] maps the stable selection key (inv:<id> / cat:<id> /
// name:<lower>) to the current quantity. The widget never mutates this map —
// all changes flow back through the three callbacks.
// ---------------------------------------------------------------------------

class CatalogueBrowseList extends StatefulWidget {
  const CatalogueBrowseList({
    super.key,
    required this.isSales,
    required this.accent,
    required this.inventory,
    required this.selectedQtys,
    required this.onSelected,
    required this.onDeselected,
    required this.onQtyChanged,
    this.onOutOfStockTapped,
  });

  /// `true` → sales mode (grey + block zero-stock items, enforce stock cap).
  /// `false` → purchase / inventory-receive mode (all items selectable).
  final bool isSales;
  final Color accent;
  final List<InventoryItem> inventory;

  /// key → current quantity. Widget treats this as read-only.
  final Map<String, double> selectedQtys;

  final ValueChanged<ItemAutocompleteResult> onSelected;
  final ValueChanged<String> onDeselected; // passes the key
  final void Function(String key, double qty) onQtyChanged;

  /// Sales mode only — called when a zero-stock item is tapped.
  final ValueChanged<ProductCatalogItem>? onOutOfStockTapped;

  @override
  State<CatalogueBrowseList> createState() => _CatalogueBrowseListState();
}

class _CatalogueBrowseListState extends State<CatalogueBrowseList> {
  String? _category;

  String _keyForRow(_BrowseRow row) {
    if (row.inventoryItem != null) return 'inv:${row.inventoryItem!.id}';
    return 'cat:${row.catalogueItem.id}';
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final catalogue = provider.items;
        final inventory = widget.inventory;

        if (catalogue.isEmpty && inventory.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isSales
                      ? Icons.shopping_cart_outlined
                      : Icons.inventory_outlined,
                  size: 18.w,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No items yet. Type a name above to add your first item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13.sp),
                ),
              ],
            ),
          );
        }

        final byCatalogId = <String, InventoryItem>{
          for (final inv in inventory)
            if (inv.catalogItemId != null) inv.catalogItemId!: inv,
        };
        final byName = <String, InventoryItem>{
          for (final inv in inventory) inv.name.toLowerCase().trim(): inv,
        };

        final allRows = catalogue.map((cat) {
          final inv =
              byCatalogId[cat.id] ?? byName[cat.name.toLowerCase().trim()];
          return _BrowseRow(catalogueItem: cat, inventoryItem: inv);
        }).toList();

        allRows.sort((a, b) {
          if (widget.isSales) {
            final aStock = (a.inventoryItem?.currentStock ?? 0) > 0;
            final bStock = (b.inventoryItem?.currentStock ?? 0) > 0;
            if (aStock != bStock) return aStock ? -1 : 1;
          }
          return a.catalogueItem.name.compareTo(b.catalogueItem.name);
        });

        final categoryCount = <String, int>{};
        for (final r in allRows) {
          final c = r.catalogueItem.category;
          if (c.isNotEmpty) categoryCount[c] = (categoryCount[c] ?? 0) + 1;
        }
        final categories = categoryCount.keys.toList()..sort();

        final filtered = _category == null
            ? allRows
            : allRows
                .where((r) => r.catalogueItem.category == _category)
                .toList();

        return Column(
          children: [
            SizedBox(
              height: 5.5.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                children: [
                  _CategoryChip(
                    label: 'All',
                    count: allRows.length,
                    selected: _category == null,
                    accent: widget.accent,
                    onTap: () => setState(() => _category = null),
                  ),
                  ...categories.map((cat) => _CategoryChip(
                        label: cat,
                        count: categoryCount[cat]!,
                        selected: _category == cat,
                        accent: widget.accent,
                        onTap: () => setState(
                            () => _category = _category == cat ? null : cat),
                      )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 0.5.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} items available',
                  style: TextStyle(
                      fontSize: 11.sp, color: Colors.grey.shade600),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _buildCard(ctx, filtered[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, _BrowseRow row) {
    final cat = row.catalogueItem;
    final inv = row.inventoryItem;
    final stock = inv?.currentStock ?? 0;
    final inStock = stock > 0;
    final greyed = widget.isSales && !inStock;
    final rate = widget.isSales
        ? (inv != null
            ? (inv.sellingPrice > 0 ? inv.sellingPrice : inv.avgCost)
            : cat.sellingPrice)
        : (inv != null && inv.avgCost > 0
            ? inv.avgCost
            : inv != null && inv.sellingPrice > 0
                ? inv.sellingPrice
                : cat.costPrice > 0
                    ? cat.costPrice
                    : cat.sellingPrice);
    final key = _keyForRow(row);
    final qty = widget.selectedQtys[key];
    final isSelected = qty != null;

    void select() => widget.onSelected(ItemAutocompleteResult(
          kind: inv != null
              ? AutocompleteResultKind.inventory
              : AutocompleteResultKind.catalogue,
          name: cat.name,
          sku: cat.sku,
          rate: rate,
          unit: cat.unit,
          category: cat.category,
          inventoryItem: inv,
          catalogueItem: cat,
        ));

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: widget.accent, width: 2)
            : BorderSide(color: Colors.grey.shade200),
      ),
      elevation: isSelected ? 2 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelected) { widget.onDeselected(key); return; }
          if (widget.isSales && !inStock) {
            widget.onOutOfStockTapped?.call(cat); return;
          }
          select();
        },
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: greyed && !isSelected
                        ? null
                        : (_) {
                            if (isSelected) {
                              widget.onDeselected(key);
                            } else if (widget.isSales && !inStock) {
                              widget.onOutOfStockTapped?.call(cat);
                            } else {
                              select();
                            }
                          },
                    activeColor: widget.accent,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: greyed
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          '${widget.isSales ? 'Sell' : 'Cost'}: ₹${rate.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: greyed
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 2.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: inStock
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: inStock
                            ? Colors.orange.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Text(
                      'Stock: ${_fmt(stock)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: inStock
                            ? Colors.orange.shade800
                            : Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const Divider(height: 12),
                _InlineStepper(
                  key: ValueKey('stepper_$key'),
                  quantity: qty,
                  rate: rate,
                  accent: widget.accent,
                  isSales: widget.isSales,
                  maxStock: inv?.currentStock ?? double.infinity,
                  onQtyChanged: (v) => widget.onQtyChanged(key, v),
                  onDeselected: () => widget.onDeselected(key),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _BrowseRow {
  const _BrowseRow({required this.catalogueItem, this.inventoryItem});
  final ProductCatalogItem catalogueItem;
  final InventoryItem? inventoryItem;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(width: 1.5.w),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 1.5.w, vertical: 0.2.h),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(1.5.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 5.w),
      ),
    );
  }
}

class _InlineStepper extends StatefulWidget {
  const _InlineStepper({
    super.key,
    required this.quantity,
    required this.rate,
    required this.accent,
    required this.isSales,
    required this.maxStock,
    required this.onQtyChanged,
    required this.onDeselected,
  });

  final double quantity;
  final double rate;
  final Color accent;
  final bool isSales;
  final double maxStock;
  final void Function(double) onQtyChanged;
  final VoidCallback onDeselected;

  @override
  State<_InlineStepper> createState() => _InlineStepperState();
}

class _InlineStepperState extends State<_InlineStepper> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.quantity));
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_InlineStepper old) {
    super.didUpdateWidget(old);
    if (old.quantity != widget.quantity && !_focus.hasFocus) {
      _ctrl.text = _fmt(widget.quantity);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _apply(double v) {
    if (widget.isSales && v > widget.maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Only ${_fmt(widget.maxStock)} in stock'),
        backgroundColor: Colors.red,
      ));
      v = widget.maxStock;
    }
    if (v <= 0) { widget.onDeselected(); return; }
    widget.onQtyChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.quantity * widget.rate;
    return Row(
      children: [
        _QtyButton(
            icon: Icons.remove,
            accent: widget.accent,
            onTap: () => _apply(widget.quantity - 1)),
        SizedBox(width: 2.w),
        SizedBox(
          width: 12.w,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed > 0) _apply(parsed);
            },
          ),
        ),
        SizedBox(width: 2.w),
        _QtyButton(
            icon: Icons.add,
            accent: widget.accent,
            onTap: () => _apply(widget.quantity + 1)),
        SizedBox(width: 3.w),
        Text(
          '@ ₹${widget.rate.toStringAsFixed(2)}',
          style:
              TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: widget.accent),
        ),
      ],
    );
  }
}
