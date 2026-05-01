import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item_model.dart';
import '../providers/catalogue_provider.dart';
import '../services/inventory_service.dart';
import '../services/items_service.dart';

/// Where the selection came from, so the calling screen knows what to do next.
enum AutocompleteResultKind {
  /// User picked an existing inventory item — has stock, ready to use.
  inventory,

  /// User picked a catalogue item that is not in inventory yet.
  /// Sales: should warn and offer to seed opening stock.
  /// Purchase: creates inventory on first receive.
  catalogue,

  /// User typed a brand-new name and confirmed "Add new". The catalogue entry
  /// has already been created by [findOrCreate]; inventory does not exist yet.
  newItem,
}

/// Sales mode greys out catalogue-only items and warns on tap (cannot sell
/// what you don't stock). Purchase mode treats both lists as normal options.
enum AutocompleteMode { sales, purchase }

class ItemAutocompleteResult {
  final AutocompleteResultKind kind;
  final String name;
  final String sku;
  final double rate; // selling price — use for sales invoices
  final double costRate; // purchase/avg cost — use for purchase invoices
  final String unit;
  final String category;
  final InventoryItem? inventoryItem;
  final ProductCatalogItem? catalogueItem;

  const ItemAutocompleteResult({
    required this.kind,
    required this.name,
    required this.sku,
    required this.rate,
    this.costRate = 0.0,
    required this.unit,
    required this.category,
    this.inventoryItem,
    this.catalogueItem,
  });
}

/// Single autocomplete control used by both sales and purchase flows.
///
/// Search order:
///   1. Inventory items matching the query (real stock, primary).
///   2. Catalogue items matching the query (excluding any already shown above).
///   3. Bottom row: `+ Add new "<query>"` when nothing matches exactly.
class ItemAutocompleteField extends StatefulWidget {
  const ItemAutocompleteField({
    super.key,
    required this.mode,
    required this.onSelected,
    this.controller,
    this.decoration,
    this.autofocus = false,
    this.defaultRateForNewItem = 0.0,
    this.defaultUnit = 'pcs',
    this.defaultCategory = 'General',
    this.onOutOfStockTapped,
  });

  final AutocompleteMode mode;
  final ValueChanged<ItemAutocompleteResult> onSelected;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final bool autofocus;

  /// When the user creates a brand-new catalogue entry from this field.
  final double defaultRateForNewItem;
  final String defaultUnit;
  final String defaultCategory;

  /// Sales mode: invoked when user taps a catalogue item that has no
  /// inventory. Caller decides whether to open an "add opening stock" sheet
  /// or just block. If null, taps on out-of-stock catalogue items are no-ops.
  final ValueChanged<ProductCatalogItem>? onOutOfStockTapped;

  @override
  State<ItemAutocompleteField> createState() => _ItemAutocompleteFieldState();
}

class _ItemAutocompleteFieldState extends State<ItemAutocompleteField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  List<InventoryItem> _inventory = const [];
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final inv = await InventoryService().getAllItems();
      if (mounted) setState(() => _inventory = inv);
    } catch (_) {
      // Surface via empty list — caller's screen typically shows its own error.
    }
    if (mounted) {
      await context.read<CatalogueProvider>().load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() => _query = _controller.text);
      _refreshOverlay();
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Slight delay so a tap on an overlay row registers before dismissal.
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: _buildSuggestionList(),
          ),
        ),
      ),
    );
    overlay.insert(_overlay!);
  }

  void _refreshOverlay() {
    if (_overlay == null) return;
    _overlay!.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  // --- Suggestion building ------------------------------------------------

  List<InventoryItem> _matchingInventory(String q) {
    if (q.isEmpty) return const [];
    final lower = q.toLowerCase();
    final out = <InventoryItem>[];
    for (final i in _inventory) {
      if (i.name.toLowerCase().contains(lower) ||
          i.sku.toLowerCase().contains(lower)) {
        out.add(i);
        if (out.length >= 20) break;
      }
    }
    return out;
  }

  List<ProductCatalogItem> _matchingCatalogue(
      String q, Set<String?> inventoryCatalogIds) {
    final cat = context.read<CatalogueProvider>().search(q);
    if (cat.isEmpty) return const [];
    return cat
        .where((c) => !inventoryCatalogIds.contains(c.id))
        .toList(growable: false);
  }

  Widget _buildSuggestionList() {
    final q = _query.trim();
    final inventoryMatches = _matchingInventory(q);

    final inventoryCatalogIds =
        inventoryMatches.map((i) => i.catalogItemId).toSet();
    final catalogueMatches = _matchingCatalogue(q, inventoryCatalogIds);

    final hasExactMatch = inventoryMatches.any(
            (i) => i.name.toLowerCase() == q.toLowerCase()) ||
        catalogueMatches.any((c) => c.name.toLowerCase() == q.toLowerCase());
    final showAddNew = q.isNotEmpty && !hasExactMatch;

    final tiles = <Widget>[];

    if (inventoryMatches.isNotEmpty) {
      tiles.add(_sectionHeader('In stock'));
      for (final i in inventoryMatches) {
        tiles.add(_inventoryTile(i));
      }
    }

    if (catalogueMatches.isNotEmpty) {
      tiles.add(_sectionHeader(widget.mode == AutocompleteMode.sales
          ? 'Catalogue (not in stock)'
          : 'Catalogue'));
      for (final c in catalogueMatches) {
        tiles.add(_catalogueTile(c));
      }
    }

    if (showAddNew) {
      tiles.add(_addNewTile(q));
    }

    if (tiles.isEmpty) {
      tiles.add(const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Start typing to search items',
            style: TextStyle(color: Colors.black54)),
      ));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView(shrinkWrap: true, children: tiles),
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5)),
      );

  Widget _inventoryTile(InventoryItem item) {
    final displayRate = widget.mode == AutocompleteMode.sales
        ? item.sellingPrice
        : item.avgCost;
    return ListTile(
      dense: true,
      title: Text(item.name),
      subtitle: Text(
          '${item.sku} • Stock: ${item.currentStock.toStringAsFixed(item.currentStock == item.currentStock.roundToDouble() ? 0 : 2)} ${item.unit}'),
      trailing: Text('₹${displayRate.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () => _commitInventory(item),
    );
  }

  Widget _catalogueTile(ProductCatalogItem item) {
    final isSales = widget.mode == AutocompleteMode.sales;
    final color = isSales ? Colors.black38 : null;
    final displayRate = isSales ? item.sellingPrice : item.costPrice;
    return ListTile(
      dense: true,
      title: Text(item.name, style: TextStyle(color: color)),
      subtitle: Text(
        isSales
            ? '${item.sku} • Not in stock'
            : '${item.sku} • ${item.category}',
        style: TextStyle(color: color),
      ),
      trailing: Text('₹${displayRate.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: () => _commitCatalogue(item),
    );
  }

  Widget _addNewTile(String q) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.add_circle_outline),
      title: Text('Add new: "$q"'),
      onTap: () => _commitNew(q),
    );
  }

  // --- Selection handlers -------------------------------------------------

  void _commitInventory(InventoryItem item) {
    _controller.text = item.name;
    _focusNode.unfocus();
    widget.onSelected(ItemAutocompleteResult(
      kind: AutocompleteResultKind.inventory,
      name: item.name,
      sku: item.sku,
      rate: item.sellingPrice > 0 ? item.sellingPrice : item.avgCost,
      costRate: item.avgCost,
      unit: item.unit,
      category: item.category,
      inventoryItem: item,
    ));
  }

  void _commitCatalogue(ProductCatalogItem item) {
    if (widget.mode == AutocompleteMode.sales) {
      _focusNode.unfocus();
      widget.onOutOfStockTapped?.call(item);
      return;
    }
    _controller.text = item.name;
    _focusNode.unfocus();
    widget.onSelected(ItemAutocompleteResult(
      kind: AutocompleteResultKind.catalogue,
      name: item.name,
      sku: item.sku,
      rate: item.sellingPrice,
      costRate: item.costPrice,
      unit: item.unit,
      category: item.category,
      catalogueItem: item,
    ));
  }

  Future<void> _commitNew(String name) async {
    final provider = context.read<CatalogueProvider>();
    try {
      final created = await provider.findOrCreate(
        name: name,
        rate: widget.defaultRateForNewItem,
        unit: widget.defaultUnit,
        category: widget.defaultCategory,
      );
      _controller.text = created.name;
      _focusNode.unfocus();
      widget.onSelected(ItemAutocompleteResult(
        kind: AutocompleteResultKind.newItem,
        name: created.name,
        sku: created.sku,
        rate: created.sellingPrice,
        costRate: created.costPrice,
        unit: created.unit,
        category: created.category,
        catalogueItem: created,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        decoration: widget.decoration ??
            const InputDecoration(
              hintText: 'Search items',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
      ),
    );
  }
}
