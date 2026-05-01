import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../models/invoice_model.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';
import '../services/items_service.dart';

class ReviewSellingPricesScreen extends StatefulWidget {
  final List<InvoiceItem> items;
  const ReviewSellingPricesScreen({super.key, required this.items});

  @override
  State<ReviewSellingPricesScreen> createState() =>
      _ReviewSellingPricesScreenState();
}

class _RowState {
  final InvoiceItem invoiceItem;
  InventoryItem? inventoryItem;
  ProductCatalogItem? catalogItem;
  final TextEditingController controller = TextEditingController();
  bool loading = true;

  _RowState(this.invoiceItem);

  double get unitCost => invoiceItem.unitCost;
  double get currentSellingPrice =>
      inventoryItem?.sellingPrice ?? catalogItem?.sellingPrice ?? 0.0;

  void dispose() => controller.dispose();
}

class _ReviewSellingPricesScreenState
    extends State<ReviewSellingPricesScreen> {
  final _invService = InventoryService();
  final _itemsService = ItemsService();
  late final List<_RowState> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _rows = widget.items
        .where((i) => seen.add(i.name.trim().toLowerCase()))
        .map(_RowState.new)
        .toList();
    _loadCurrentPrices();
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPrices() async {
    await Future.wait(_rows.map((row) async {
      final inv = await _invService.getItemByName(row.invoiceItem.name);
      final cat = await _itemsService.findByNormalizedName(row.invoiceItem.name);
      row.inventoryItem = inv;
      row.catalogItem = cat;
      row.loading = false;
      final current = inv?.sellingPrice ?? cat?.sellingPrice ?? 0.0;
      if (current > 0) { row.controller.text = current.toStringAsFixed(2); }
    }));
    if (!mounted) return;
    setState(() {});
  }

  void _applyMargin(_RowState row, int pct) {
    if (row.unitCost <= 0) return;
    row.controller.text =
        (row.unitCost * (1 + pct / 100)).toStringAsFixed(2);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final row in _rows) {
        final raw = row.controller.text.trim();
        if (raw.isEmpty) continue;
        final newPrice = double.tryParse(raw);
        if (newPrice == null || newPrice <= 0) continue;

        final inv = row.inventoryItem;
        if (inv != null) {
          await _invService.updateItem(
              inv.copyWith(sellingPrice: newPrice));
        }
        final cat = row.catalogItem;
        if (cat != null) {
          await _itemsService.updateItem(
              cat.copyWith(sellingPrice: newPrice));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    _goHome();
  }

  void _goHome() =>
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Selling Prices'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _goHome,
            child: const Text('Skip',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.green.shade50,
            padding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Text(
              'Stock received. Set selling prices for '
              '${_rows.length} ${_rows.length == 1 ? 'item' : 'items'}.',
              style: TextStyle(
                  fontSize: 12.sp, color: Colors.green.shade800),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(3.w),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => SizedBox(height: 2.h),
              itemBuilder: (_, i) => _buildRow(_rows[i]),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRow(_RowState row) {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.invoiceItem.name,
              style: TextStyle(
                  fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 0.8.h),
            Row(
              children: [
                _priceLabel(
                    'Cost paid', row.unitCost, Colors.orange.shade700),
                SizedBox(width: 4.w),
                if (row.loading)
                  SizedBox(
                    width: 4.w,
                    height: 4.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _priceLabel('Current price',
                      row.currentSellingPrice, Colors.blue.shade700),
              ],
            ),
            SizedBox(height: 1.2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [10, 20, 30, 50].map((pct) {
                return ActionChip(
                  label: Text('+$pct%',
                      style: TextStyle(
                          fontSize: 11.sp, color: Colors.white)),
                  backgroundColor: row.unitCost > 0
                      ? Colors.green.shade600
                      : Colors.grey.shade400,
                  onPressed:
                      row.unitCost > 0 ? () => _applyMargin(row, pct) : null,
                );
              }).toList(),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: row.controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'New selling price',
                prefixText: '₹',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLabel(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 10.sp, color: Colors.grey.shade600)),
        Text(
          amount > 0 ? '₹${amount.toStringAsFixed(2)}' : '—',
          style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Save & Continue',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
