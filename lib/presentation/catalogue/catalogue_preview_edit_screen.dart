import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../models/business_catalogue_template.dart';
import '../../providers/catalogue_provider.dart';
import '../../services/business_catalogue_service.dart';
import '../../services/business_profile_service.dart';

class CataloguePreviewEditScreen extends StatefulWidget {
  final List<String> selectedTemplateIds;
  final bool isCustomMode;
  final bool isFirstTimeSetup;
  final String? returnRoute;

  const CataloguePreviewEditScreen({
    super.key,
    required this.selectedTemplateIds,
    this.isCustomMode = false,
    this.isFirstTimeSetup = false,
    this.returnRoute,
  });

  @override
  State<CataloguePreviewEditScreen> createState() =>
      _CataloguePreviewEditScreenState();
}

class _CataloguePreviewEditScreenState
    extends State<CataloguePreviewEditScreen> {
  final BusinessCatalogueService _catalogueService =
      BusinessCatalogueService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<_EditableItem> _allItems = [];
  List<_EditableItem> _filteredItems = [];
  Map<String, List<_EditableItem>> _groupedItems = {};
  Set<String> _expandedCategories = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadTemplateItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Data loading -------------------------------------------------------

  void _loadTemplateItems() {
    setState(() => _isLoading = true);

    List<CatalogueTemplateItem> templateItems;
    if (widget.isCustomMode) {
      templateItems = _catalogueService.getPopularItems(limit: 100);
      _showSuggestions = true;
    } else {
      templateItems = _catalogueService.mergeTemplates(widget.selectedTemplateIds);
    }

    _allItems = templateItems
        .map((t) => _EditableItem(
              name: t.name,
              rate: t.rate,
              category: t.category,
              unit: t.unit,
              description: t.description,
              isSelected: !widget.isCustomMode,
            ))
        .toList();

    _filteredItems = List.from(_allItems);
    _buildGroups();
    _expandedCategories = _groupedItems.keys.toSet();

    setState(() => _isLoading = false);
  }

  void _buildGroups() {
    _groupedItems = {};
    for (final item in _filteredItems) {
      _groupedItems.putIfAbsent(item.category, () => []).add(item);
    }
  }

  void _filterItems() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = q.isEmpty
          ? List.from(_allItems)
          : _allItems
              .where((i) =>
                  i.name.toLowerCase().contains(q) ||
                  i.category.toLowerCase().contains(q))
              .toList();
      _buildGroups();
    });
  }

  // --- Save ---------------------------------------------------------------

  Future<void> _save() async {
    final selected = _allItems.where((i) => i.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<CatalogueProvider>();

      // findOrCreate deduplicates by normalised name — safe to call for all.
      for (final item in selected) {
        await provider.findOrCreate(
          name: item.name,
          rate: item.rate,
          category: item.category,
          unit: item.unit,
          description: item.description,
        );
      }

      await BusinessProfileService.instance.markOnboardingComplete();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${selected.length} items to your catalogue'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.isFirstTimeSetup) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving catalogue: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isCustomMode
            ? 'Suggested Items'
            : 'Review & Edit Catalogue'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _toggleSelectAll,
              icon: Icon(
                _selectedCount == _allItems.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: Colors.white,
                size: 5.w,
              ),
              label: Text(
                _selectedCount == _allItems.length
                    ? 'Deselect All'
                    : 'Select All',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showSuggestions) _buildInfoBanner(),
                _buildSearchBar(),
                _buildStats(),
                Expanded(child: _buildList()),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  int get _selectedCount => _allItems.where((i) => i.isSelected).length;

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: Colors.amber[50],
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'These are suggested items. Select what you need.',
              style: TextStyle(fontSize: 10.sp, color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search items or categories...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _searchController.clear,
                )
              : null,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!)),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.blue[700], size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedCount of ${_allItems.length} items selected',
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900]),
                ),
                Text(
                  '${_groupedItems.length} categories',
                  style: TextStyle(fontSize: 10.sp, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_groupedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 15.w, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text('No items found',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
          ],
        ),
      );
    }
    final categories = _groupedItems.keys.toList()..sort();
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final items = _groupedItems[cat]!;
        return _CategorySection(
          category: cat,
          items: items,
          isExpanded: _expandedCategories.contains(cat),
          onToggleExpand: () => setState(() {
            if (_expandedCategories.contains(cat)) {
              _expandedCategories.remove(cat);
            } else {
              _expandedCategories.add(cat);
            }
          }),
          onToggleCategorySelect: () {
            final sel = items.where((i) => i.isSelected).length;
            final toSelect = sel < items.length;
            setState(() {
              for (final item in items) { item.isSelected = toSelect; }
            });
          },
          onItemChanged: () => setState(() {}),
          onEditName: (item) => _editName(item),
          onEditRate: (item) => _editRate(item),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final canSave = _selectedCount > 0 && !_isSaving;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back', style: TextStyle(fontSize: 12.sp)),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 4.w,
                        width: 4.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 5.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Save $_selectedCount Items',
                            style: TextStyle(
                                fontSize: 12.sp, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ------------------------------------------------------------

  void _toggleSelectAll() {
    final toSelect = _selectedCount < _allItems.length;
    setState(() {
      for (final item in _allItems) { item.isSelected = toSelect; }
    });
  }

  Future<void> _editName(_EditableItem item) async {
    final ctrl = TextEditingController(text: item.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Item Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.trim().isNotEmpty) {
      setState(() => item.name = result.trim());
    }
  }

  Future<void> _editRate(_EditableItem item) async {
    final ctrl = TextEditingController(text: item.rate.toStringAsFixed(2));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Rate'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Rate (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) {
      final r = double.tryParse(result);
      if (r != null && r > 0) setState(() => item.rate = r);
    }
  }
}

// ---------------------------------------------------------------------------
// Mutable item for in-screen editing before save
// ---------------------------------------------------------------------------

class _EditableItem {
  String name;
  double rate;
  final String category;
  final String unit;
  final String? description;
  bool isSelected;

  _EditableItem({
    required this.name,
    required this.rate,
    required this.category,
    required this.unit,
    this.description,
    this.isSelected = false,
  });
}

// ---------------------------------------------------------------------------
// Category collapsible section (extracted for clarity)
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.items,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleCategorySelect,
    required this.onItemChanged,
    required this.onEditName,
    required this.onEditRate,
  });

  final String category;
  final List<_EditableItem> items;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleCategorySelect;
  final VoidCallback onItemChanged;
  final void Function(_EditableItem) onEditName;
  final void Function(_EditableItem) onEditRate;

  @override
  Widget build(BuildContext context) {
    final selectedCount = items.where((i) => i.isSelected).length;
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue[700], size: 6.w),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category,
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900])),
                        Text('$selectedCount of ${items.length} selected',
                            style: TextStyle(
                                fontSize: 9.sp, color: Colors.blue[700])),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onToggleCategorySelect,
                    child: Text(
                      selectedCount == items.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (_, i) => _ItemTile(
                item: items[i],
                onChanged: onItemChanged,
                onEditName: () => onEditName(items[i]),
                onEditRate: () => onEditRate(items[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.onChanged,
    required this.onEditName,
    required this.onEditRate,
  });

  final _EditableItem item;
  final VoidCallback onChanged;
  final VoidCallback onEditName;
  final VoidCallback onEditRate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.isSelected,
        onChanged: (v) {
          item.isSelected = v ?? false;
          onChanged();
        },
      ),
      title: InkWell(
        onTap: onEditName,
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: item.isSelected ? Colors.black87 : Colors.grey[500],
                ),
              ),
            ),
            Icon(Icons.edit, size: 4.w, color: Colors.grey[400]),
          ],
        ),
      ),
      subtitle:
          Text(item.unit, style: TextStyle(fontSize: 9.sp, color: Colors.grey[600])),
      trailing: InkWell(
        onTap: onEditRate,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${item.rate.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700])),
              SizedBox(width: 1.w),
              Icon(Icons.edit, size: 3.5.w, color: Colors.green[700]),
            ],
          ),
        ),
      ),
    );
  }
}
