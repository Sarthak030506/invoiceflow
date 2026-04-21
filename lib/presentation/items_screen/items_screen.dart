import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/catalogue_provider.dart';
import '../../services/items_service.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ItemsService _itemsService = ItemsService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogueProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductCatalogItem> _filter(List<ProductCatalogItem> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where((i) =>
            i.name.toLowerCase().contains(q) ||
            i.sku.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogueProvider>();
    final filtered = _filter(provider.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(8.h),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: provider.isLoading && provider.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCountBar(filtered.length, provider.items.length),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () =>
                              provider.load(force: true),
                          child: ListView.builder(
                            padding: EdgeInsets.all(3.w),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _ItemCard(
                              item: filtered[i],
                              onEdit: () => _showEditDialog(filtered[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCountBar(int shown, int total) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, size: 5.w, color: Colors.blue),
          SizedBox(width: 2.w),
          Text(
            _query.isEmpty
                ? '$shown ${shown == 1 ? 'item' : 'items'}'
                : '$shown of $total items',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _query.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 2.h),
          Text(
            _query.isEmpty
                ? 'No catalogue items yet'
                : 'No items match "$_query"',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
          if (_query.isEmpty) ...[
            SizedBox(height: 1.h),
            Text('Tap + to add your first item',
                style: TextStyle(
                    fontSize: 12.sp, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  // --- Add / edit ---------------------------------------------------------

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General');
    final unitCtrl = TextEditingController(text: 'pcs');
    final barcodeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Item name *',
                    validator: _required('Item name is required')),
                SizedBox(height: 2.h),
                _field(rateCtrl, 'Rate *',
                    prefixText: '₹',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rate is required';
                      final r = double.tryParse(v);
                      if (r == null || r <= 0) return 'Enter a valid rate';
                      return null;
                    }),
                SizedBox(height: 2.h),
                _field(categoryCtrl, 'Category *',
                    validator: _required('Category is required')),
                SizedBox(height: 2.h),
                _field(unitCtrl, 'Unit *',
                    hint: 'e.g. pcs, kg, ltr',
                    validator: _required('Unit is required')),
                SizedBox(height: 2.h),
                _field(barcodeCtrl, 'Barcode', hint: 'Optional'),
                SizedBox(height: 2.h),
                _field(descCtrl, 'Description',
                    hint: 'Optional', maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (save == true && mounted) {
      try {
        await context.read<CatalogueProvider>().findOrCreate(
              name: nameCtrl.text.trim(),
              rate: double.parse(rateCtrl.text.trim()),
              category: categoryCtrl.text.trim(),
              unit: unitCtrl.text.trim(),
              barcode:
                  barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
              description:
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${nameCtrl.text.trim()}" added'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    nameCtrl.dispose();
    rateCtrl.dispose();
    categoryCtrl.dispose();
    unitCtrl.dispose();
    barcodeCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _showEditDialog(ProductCatalogItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final rateCtrl = TextEditingController(text: item.rate.toString());
    final categoryCtrl = TextEditingController(text: item.category);
    final unitCtrl = TextEditingController(text: item.unit);
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${item.name}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Item name *',
                    validator: _required('Item name is required')),
                SizedBox(height: 2.h),
                _field(rateCtrl, 'Rate *',
                    prefixText: '₹',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Rate is required';
                      final r = double.tryParse(v);
                      if (r == null || r <= 0) return 'Enter a valid rate';
                      return null;
                    }),
                SizedBox(height: 2.h),
                _field(categoryCtrl, 'Category *',
                    validator: _required('Category is required')),
                SizedBox(height: 2.h),
                _field(unitCtrl, 'Unit *',
                    validator: _required('Unit is required')),
                SizedBox(height: 1.h),
                Text('SKU: ${item.sku}',
                    style: TextStyle(
                        fontSize: 11.sp, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true && mounted) {
      try {
        final updated = item.copyWith(
          name: nameCtrl.text.trim(),
          rate: double.parse(rateCtrl.text.trim()),
          category: categoryCtrl.text.trim(),
          unit: unitCtrl.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _itemsService.updateItem(updated);
        if (!mounted) return;
        await context.read<CatalogueProvider>().load(force: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${updated.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    nameCtrl.dispose();
    rateCtrl.dispose();
    categoryCtrl.dispose();
    unitCtrl.dispose();
  }

  // --- Form helpers -------------------------------------------------------

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String? Function(String?) _required(String msg) =>
      (v) => (v == null || v.trim().isEmpty) ? msg : null;
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onEdit});

  final ProductCatalogItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2,
                    color: Colors.blue.shade600, size: 6.w),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${item.sku} • ${item.category} • ${item.unit}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.currency_rupee,
                            size: 3.w, color: Colors.grey.shade600),
                        Text(
                          item.rate.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(' per ${item.unit}',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade700),
                  onPressed: onEdit,
                  tooltip: 'Edit item',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
