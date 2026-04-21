import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../models/invoice_model.dart';
import '../models/inventory_item_model.dart';
import '../providers/catalogue_provider.dart';
import '../services/customer_service.dart';
import '../services/inventory_service.dart';
import '../services/invoice_service.dart';
import '../services/items_service.dart';
import '../services/return_service.dart';
import '../utils/app_logger.dart';
import '../widgets/enhanced_payment_details_widget.dart';
import '../widgets/item_autocomplete_field.dart';
import './create_invoice/widgets/customer_input_widget.dart';

class ChooseItemsInvoiceScreen extends StatefulWidget {
  final String invoiceType; // 'sales' or 'purchase'

  const ChooseItemsInvoiceScreen({
    Key? key,
    required this.invoiceType,
  }) : super(key: key);

  @override
  State<ChooseItemsInvoiceScreen> createState() =>
      _ChooseItemsInvoiceScreenState();
}

class _ChooseItemsInvoiceScreenState extends State<ChooseItemsInvoiceScreen> {
  late final InvoiceService _invoiceService;
  late final CustomerService _customerService;
  late final ReturnService _returnService;
  late final InventoryService _inventoryService;

  /// Keyed by stable selection key (`inv:<id>` / `cat:<id>` / `name:<lower>`)
  /// so the same item can't appear twice.
  final Map<String, _SelectedRow> _selected = {};

  String _customerName = '';
  String _customerPhone = '';
  String? _customerId;
  double _pendingRefundAmount = 0.0;

  bool get _isSales => widget.invoiceType == 'sales';
  Color get _accent => _isSales ? Colors.blue : Colors.green;

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService.instance;
    _customerService = CustomerService.instance;
    _returnService = ReturnService.instance;
    _inventoryService = InventoryService();
  }

  // --- Selection -----------------------------------------------------------

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

  Future<void> _handleOutOfStockTap(ProductCatalogItem item) async {
    final seed = await showModalBottomSheet<_SeedStockResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeedStockSheet(item: item),
    );
    if (seed == null || !mounted) return;
    try {
      final invItem = InventoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sku: item.sku,
        name: item.name,
        unit: item.unit,
        openingStock: 0.0,
        currentStock: 0.0,
        reorderPoint: 0.0,
        avgCost: seed.unitCost,
        category: item.category,
        lastUpdated: DateTime.now(),
        barcode: item.barcode,
        catalogItemId: item.id,
      );
      await _inventoryService.addItem(invItem);
      await _inventoryService.receiveStock(
        invItem.id,
        seed.quantity,
        seed.unitCost,
        'opening_stock:${DateTime.now().microsecondsSinceEpoch}',
      );
      if (!mounted) return;
      // Auto-select the freshly stocked item.
      final fresh = await _inventoryService.getItemById(invItem.id);
      if (fresh != null && mounted) {
        setState(() {
          _selected['inv:${fresh.id}'] = _SelectedRow(
            name: fresh.name,
            sku: fresh.sku,
            unit: fresh.unit,
            rate: fresh.avgCost,
            quantity: 1,
            inventoryItem: fresh,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add opening stock: $e')),
      );
    }
  }

  double get _total =>
      _selected.values.fold<double>(0, (s, r) => s + r.quantity * r.rate);

  // --- Invoice generation flow --------------------------------------------

  Future<void> _ensureCatalogueLinkedInventory() async {
    // For each selected row that came from catalogue/new, make sure a matching
    // inventory item exists with `catalogItemId` linkage. _processInvoiceInventory
    // creates inventory by name only and would lose the linkage otherwise.
    final inventory = await _inventoryService.getAllItems();
    final byName = {for (final i in inventory) i.name.toLowerCase().trim(): i};
    final byCatalogId = <String, InventoryItem>{
      for (final i in inventory)
        if (i.catalogItemId != null) i.catalogItemId!: i,
    };

    for (final row in _selected.values) {
      if (row.catalogueItem == null) continue;
      final cat = row.catalogueItem!;
      if (byCatalogId.containsKey(cat.id)) continue;
      if (byName.containsKey(cat.name.toLowerCase().trim())) continue;

      final invItem = InventoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sku: cat.sku,
        name: cat.name,
        unit: cat.unit,
        openingStock: 0.0,
        currentStock: 0.0,
        reorderPoint: 0.0,
        avgCost: row.rate,
        category: cat.category,
        lastUpdated: DateTime.now(),
        barcode: cat.barcode,
        catalogItemId: cat.id,
      );
      await _inventoryService.addItem(invItem);
    }
  }

  void _onCustomerSelected(String name, String phone, String? customerId) async {
    setState(() {
      _customerName = name;
      _customerPhone = phone;
      _customerId = customerId;
      _pendingRefundAmount = 0.0;
    });
    if (_isSales && customerId != null) {
      try {
        final customer = await _customerService.getCustomerById(customerId);
        if (customer != null && customer.pendingReturnAmount > 0) {
          setState(() => _pendingRefundAmount = customer.pendingReturnAmount);
        }
      } catch (e) {
        AppLogger.error('Error fetching customer refund', 'ChooseItemsInvoice', e);
      }
    }
  }

  void _showInvoiceSummaryDialog() {
    final invoiceItems = _selected.values
        .map((r) => InvoiceItem(
              name: r.name,
              quantity: r.quantity.toInt(),
              price: r.rate,
            ))
        .toList();
    final totalAmount = _total;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_isSales ? Icons.shopping_cart : Icons.inventory, color: _accent),
            SizedBox(width: 2.w),
            Text(_isSales ? 'Sales Invoice' : 'Purchase Invoice'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 50.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice Summary',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                const Divider(),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: invoiceItems
                        .map((i) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 1.h),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text(i.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500))),
                                  Expanded(
                                      child: Text('x${i.quantity}',
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      child: Text(
                                          '₹${i.price.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right)),
                                  Expanded(
                                      child: Text(
                                          '₹${(i.quantity * i.price).toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: _accent)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (_isSales) {
                _showCustomerInfoSheet(invoiceItems, totalAmount);
              } else {
                _showPaymentDetailsSheet(invoiceItems, totalAmount);
              }
            },
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCustomerInfoSheet(List<InvoiceItem> invoiceItems, double totalAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
            left: 4.w,
            right: 4.w,
            top: 2.h,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10.w,
                  height: 0.5.h,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text('Customer Information',
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 2.h),
                CustomerInputWidget(
                  initialName: _customerName,
                  initialPhone: _customerPhone,
                  onCustomerSelected: (name, phone, customerId) {
                    _onCustomerSelected(name, phone, customerId);
                    setModalState(() {});
                  },
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                          side: BorderSide(color: Colors.grey.shade400),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(modalCtx),
                        child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _customerPhone.isEmpty
                            ? null
                            : () async {
                                if (_customerId == null &&
                                    _customerPhone.isNotEmpty) {
                                  try {
                                    final c =
                                        await _customerService.addCustomer(
                                      _customerName.isEmpty
                                          ? 'Customer'
                                          : _customerName,
                                      _customerPhone,
                                    );
                                    _customerId = c.id;
                                  } catch (e) {
                                    AppLogger.error(
                                        'Error saving customer',
                                        'ChooseItemsInvoice',
                                        e);
                                  }
                                }
                                if (!mounted) return;
                                if (Navigator.of(modalCtx).canPop()) {
                                  Navigator.pop(modalCtx);
                                }
                                _showPaymentDetailsSheet(
                                    invoiceItems, totalAmount);
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_forward, size: 16),
                            SizedBox(width: 1.w),
                            Flexible(
                              child: Text('Continue to Payment',
                                  style: TextStyle(fontSize: 13.sp),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetailsSheet(
      List<InvoiceItem> invoiceItems, double totalAmount) {
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(parentContext).viewInsets.bottom,
          left: 4.w,
          right: 4.w,
          top: 2.h,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text('Payment Details',
                  style: TextStyle(
                      fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              EnhancedPaymentDetailsWidget(
                totalAmount: totalAmount,
                invoiceType: widget.invoiceType,
                pendingRefundAmount: _pendingRefundAmount,
                onPaymentDetailsSubmitted: (amountPaid, paymentMethod,
                    invoiceNumber, invoiceDate) async {
                  showDialog(
                    context: parentContext,
                    barrierDismissible: false,
                    builder: (_) => WillPopScope(
                      onWillPop: () async => false,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                  try {
                    if (_isSales &&
                        _customerPhone.isNotEmpty &&
                        _customerId == null) {
                      final c = await _customerService.addCustomer(
                        _customerName.isEmpty ? 'Customer' : _customerName,
                        _customerPhone,
                      );
                      _customerId = c.id;
                    }

                    String? returnNotes;
                    if (_isSales &&
                        _customerId != null &&
                        _pendingRefundAmount > 0) {
                      returnNotes =
                          'Return credit of ₹${_pendingRefundAmount.toStringAsFixed(2)} applied';
                      await _returnService.applyPendingReturnsToInvoice(
                          _customerId!, _pendingRefundAmount);
                    }

                    // Pre-create inventory items linked to catalogue picks so
                    // _processInvoiceInventory's name-match preserves linkage.
                    await _ensureCatalogueLinkedInventory();

                    final now = DateTime.now();
                    final invoiceId = invoiceNumber.replaceAll(
                        RegExp(r'[^A-Za-z0-9-_]'), '_');
                    final adjustedTotal = totalAmount - _pendingRefundAmount;

                    String invoiceStatus;
                    if ((amountPaid - adjustedTotal).abs() < 0.01) {
                      invoiceStatus = 'paid';
                    } else if (amountPaid > 0.01) {
                      invoiceStatus = 'partial';
                    } else {
                      invoiceStatus = 'posted';
                    }

                    final newInvoice = InvoiceModel(
                      id: invoiceId,
                      invoiceNumber: invoiceNumber,
                      clientName: _customerName,
                      customerPhone: _isSales ? _customerPhone : null,
                      customerId: _isSales ? _customerId : null,
                      date: invoiceDate,
                      refundAdjustment: _pendingRefundAmount,
                      revenue: totalAmount,
                      status: invoiceStatus,
                      items: invoiceItems,
                      notes: returnNotes,
                      createdAt: now,
                      updatedAt: now,
                      invoiceType: widget.invoiceType,
                      amountPaid: amountPaid,
                      paymentMethod: paymentMethod,
                    );

                    await _invoiceService.addInvoice(newInvoice);

                    if (!mounted) return;
                    context.read<CatalogueProvider>().invalidate();

                    if (Navigator.of(parentContext, rootNavigator: true)
                        .canPop()) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                          content: Text('Invoice created and saved!')),
                    );
                    if (Navigator.of(parentContext).canPop()) {
                      Navigator.of(parentContext).pop();
                    }
                    Navigator.of(parentContext).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    if (Navigator.of(parentContext, rootNavigator: true)
                        .canPop()) {
                      Navigator.of(parentContext, rootNavigator: true).pop();
                    }
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Error saving invoice: $e')),
                    );
                  }
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isSales ? 'Sales Invoice Items' : 'Purchase Invoice Items'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(3.w),
              child: ItemAutocompleteField(
                mode: _isSales
                    ? AutocompleteMode.sales
                    : AutocompleteMode.purchase,
                autofocus: true,
                onSelected: _handleSelection,
                onOutOfStockTapped: _isSales ? _handleOutOfStockTap : null,
                decoration: InputDecoration(
                  hintText: _isSales
                      ? 'Search items in stock'
                      : 'Search or add items',
                  prefixIcon: Icon(Icons.search, color: _accent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            Expanded(
              child: _selected.isEmpty
                  ? _EmptyState(isSales: _isSales)
                  : ListView(
                      children: _selected.entries
                          .map((e) => _SelectedRowTile(
                                key: ValueKey(e.key),
                                row: e.value,
                                accent: _accent,
                                isSales: _isSales,
                                onChanged: () => setState(() {}),
                                onRemove: () =>
                                    setState(() => _selected.remove(e.key)),
                              ))
                          .toList(),
                    ),
            ),
            if (_selected.isNotEmpty) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selected.length} item(s)',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                Text('₹${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: _accent)),
              ],
            ),
            SizedBox(height: 1.5.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _showInvoiceSummaryDialog,
                icon: const Icon(Icons.receipt_long),
                label: Text('Generate Invoice',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected-row tile
// ---------------------------------------------------------------------------

class _SelectedRow {
  _SelectedRow({
    required this.name,
    required this.sku,
    required this.unit,
    required this.rate,
    required this.quantity,
    this.inventoryItem,
    this.catalogueItem,
  });

  final String name;
  final String sku;
  final String unit;
  double rate;
  double quantity;
  final InventoryItem? inventoryItem;
  final ProductCatalogItem? catalogueItem;

  factory _SelectedRow.fromResult(ItemAutocompleteResult r) => _SelectedRow(
        name: r.name,
        sku: r.sku,
        unit: r.unit,
        rate: r.rate,
        quantity: 1,
        inventoryItem: r.inventoryItem,
        catalogueItem: r.catalogueItem,
      );
}

class _SelectedRowTile extends StatefulWidget {
  const _SelectedRowTile({
    super.key,
    required this.row,
    required this.accent,
    required this.isSales,
    required this.onChanged,
    required this.onRemove,
  });

  final _SelectedRow row;
  final Color accent;
  final bool isSales;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  State<_SelectedRowTile> createState() => _SelectedRowTileState();
}

class _SelectedRowTileState extends State<_SelectedRowTile> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: _fmt(widget.row.quantity));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _setQty(double v) {
    if (widget.isSales) {
      final stock = widget.row.inventoryItem?.currentStock ?? 0;
      if (v > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only ${stock.toInt()} in stock'),
            backgroundColor: Colors.red,
          ),
        );
        v = stock;
      }
    }
    if (v < 0) v = 0;
    setState(() {
      widget.row.quantity = v;
      _qtyCtrl.text = _fmt(v);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.row.quantity * widget.row.rate;
    final stock = widget.row.inventoryItem?.currentStock;
    final isNew = widget.row.inventoryItem == null;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
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
                      Text(
                        stock != null
                            ? '${widget.row.sku} • Stock: ${stock.toInt()} ${widget.row.unit}'
                            : '${widget.row.sku} • ${widget.row.unit}',
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.grey.shade600),
                      ),
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
                _qtyButton(Icons.remove,
                    () => _setQty((widget.row.quantity - 1).clamp(0, double.infinity))),
                SizedBox(
                  width: 16.w,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      widget.row.quantity = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                _qtyButton(Icons.add, () => _setQty(widget.row.quantity + 1)),
                SizedBox(width: 3.w),
                Text('@ ₹${widget.row.rate.toStringAsFixed(2)}',
                    style:
                        TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                const Spacer(),
                Text('₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: widget.accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
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

// ---------------------------------------------------------------------------
// "Seed opening stock" sheet for sales-mode out-of-stock taps
// ---------------------------------------------------------------------------

class _SeedStockResult {
  final double quantity;
  final double unitCost;
  _SeedStockResult(this.quantity, this.unitCost);
}

class _SeedStockSheet extends StatefulWidget {
  const _SeedStockSheet({required this.item});
  final ProductCatalogItem item;

  @override
  State<_SeedStockSheet> createState() => _SeedStockSheetState();
}

class _SeedStockSheetState extends State<_SeedStockSheet> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _costCtrl = TextEditingController(text: widget.item.rate.toString());
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 4.w,
        left: 4.w,
        right: 4.w,
        top: 2.h,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text('${widget.item.name} is not in stock',
              style:
                  TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          Text('Add opening stock so you can sell it.',
              style:
                  TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: TextField(
                  controller: _costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Unit cost (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final q = double.tryParse(_qtyCtrl.text) ?? 0;
                    final c = double.tryParse(_costCtrl.text) ?? 0;
                    if (q <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Quantity must be greater than zero')),
                      );
                      return;
                    }
                    Navigator.pop(context, _SeedStockResult(q, c));
                  },
                  child: const Text('Add Stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSales});
  final bool isSales;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSales ? Icons.shopping_cart_outlined : Icons.inventory_outlined,
            size: 18.w,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 2.h),
          Text(
            isSales
                ? 'Search for items you want to sell'
                : 'Search or add items to purchase',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
