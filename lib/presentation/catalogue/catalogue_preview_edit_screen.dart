import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/business_catalogue_service.dart';
import '../../services/items_service.dart';
import '../../services/catalog_service.dart';
import '../../models/business_catalogue_template.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../home_dashboard/home_dashboard.dart';

class CataloguePreviewEditScreen extends StatefulWidget {
  final List<String> selectedTemplateIds;
  final bool isCustomMode;
  final bool isFirstTimeSetup;
  final String? returnRoute;

  const CataloguePreviewEditScreen({
    Key? key,
    required this.selectedTemplateIds,
    this.isCustomMode = false,
    this.isFirstTimeSetup = false,
    this.returnRoute,
  }) : super(key: key);

  @override
  State<CataloguePreviewEditScreen> createState() =>
      _CataloguePreviewEditScreenState();
}

class _CataloguePreviewEditScreenState
    extends State<CataloguePreviewEditScreen> {
  final BusinessCatalogueService _catalogueService =
      BusinessCatalogueService.instance;
  final ItemsService _itemsService = ItemsService();
  final CatalogService _catalogService = CatalogService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<EditableCatalogueItem> _allItems = [];
  List<EditableCatalogueItem> _filteredItems = [];
  Map<String, List<EditableCatalogueItem>> _groupedItems = {};
  Set<String> _expandedCategories = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadItems() {
    setState(() {
      _isLoading = true;
    });

    List<CatalogueTemplateItem> templateItems;

    if (widget.isCustomMode) {
      // Show popular/suggested items for custom mode
      templateItems = _catalogueService.getPopularItems(limit: 100);
      _showSuggestions = true;
    } else {
      // Merge selected templates
      templateItems =
          _catalogueService.mergeTemplates(widget.selectedTemplateIds);
    }

    // Convert to editable items
    _allItems = templateItems
        .map((item) => EditableCatalogueItem(
              originalName: item.name,
              name: item.name,
              rate: item.rate,
              category: item.category,
              unit: item.unit,
              description: item.description,
              isSelected: !widget.isCustomMode, // Pre-select if not custom mode
            ))
        .toList();

    _filteredItems = List.from(_allItems);
    _groupItems();

    // Expand all categories by default
    _expandedCategories = _groupedItems.keys.toSet();

    setState(() {
      _isLoading = false;
    });
  }

  void _groupItems() {
    _groupedItems = {};
    for (var item in _filteredItems) {
      if (!_groupedItems.containsKey(item.category)) {
        _groupedItems[item.category] = [];
      }
      _groupedItems[item.category]!.add(item);
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems
            .where((item) =>
                item.name.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query))
            .toList();
      }
      _groupItems();
    });
  }

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
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _toggleSelectAll,
              icon: Icon(
                _allSelectedCount() == _allItems.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: Colors.white,
                size: 5.w,
              ),
              label: Text(
                _allSelectedCount() == _allItems.length
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
                _buildInfoBanner(),
                _buildSearchBar(),
                _buildStats(),
                Expanded(child: _buildItemsList()),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInfoBanner() {
    if (!_showSuggestions) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(3.w),
      color: Colors.amber[50],
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'These are suggested items. Select what you need or search for more.',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.amber[900],
              ),
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
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final selectedCount = _allSelectedCount();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
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
                  '$selectedCount of ${_allItems.length} items selected',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                Text(
                  '${_groupedItems.length} categories',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_groupedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 15.w, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No items found',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final sortedCategories = _groupedItems.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final items = _groupedItems[category]!;
        final isExpanded = _expandedCategories.contains(category);

        return _buildCategorySection(category, items, isExpanded);
      },
    );
  }

  Widget _buildCategorySection(
      String category, List<EditableCatalogueItem> items, bool isExpanded) {
    final selectedInCategory = items.where((item) => item.isSelected).length;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleCategoryExpansion(category),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue[700],
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          '$selectedInCategory of ${items.length} selected',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _toggleCategorySelection(category, items),
                    child: Text(
                      selectedInCategory == items.length
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
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) => _buildItemTile(items[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildItemTile(EditableCatalogueItem item) {
    return ListTile(
      leading: Checkbox(
        value: item.isSelected,
        onChanged: (value) {
          setState(() {
            item.isSelected = value ?? false;
          });
        },
      ),
      title: InkWell(
        onTap: () => _editItemName(item),
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
      subtitle: Text(
        '${item.unit}',
        style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
      ),
      trailing: InkWell(
        onTap: () => _editItemRate(item),
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
              Text(
                '₹${item.rate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(width: 1.w),
              Icon(Icons.edit, size: 3.5.w, color: Colors.green[700]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = _allSelectedCount();
    final canSave = selectedCount > 0 && !_isSaving;

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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Back', style: TextStyle(fontSize: 12.sp)),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canSave ? _saveCatalogue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 4.w,
                        width: 4.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 5.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Save $selectedCount Items',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
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

  int _allSelectedCount() {
    return _allItems.where((item) => item.isSelected).length;
  }

  void _toggleSelectAll() {
    final shouldSelectAll = _allSelectedCount() < _allItems.length;
    setState(() {
      for (var item in _allItems) {
        item.isSelected = shouldSelectAll;
      }
    });
  }

  void _toggleCategorySelection(
      String category, List<EditableCatalogueItem> items) {
    final selectedCount = items.where((item) => item.isSelected).length;
    final shouldSelectAll = selectedCount < items.length;

    setState(() {
      for (var item in items) {
        item.isSelected = shouldSelectAll;
      }
    });
  }

  void _toggleCategoryExpansion(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  void _editItemName(EditableCatalogueItem item) async {
    final controller = TextEditingController(text: item.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Item Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        item.name = result.trim();
      });
    }

    controller.dispose();
  }

  void _editItemRate(EditableCatalogueItem item) async {
    final controller =
        TextEditingController(text: item.rate.toStringAsFixed(2));

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item Rate'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Rate (₹)',
            border: OutlineInputBorder(),
            prefixText: '₹ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newRate = double.tryParse(result);
      if (newRate != null && newRate > 0) {
        setState(() {
          item.rate = newRate;
        });
      }
    }

    controller.dispose();
  }

  Future<void> _saveCatalogue() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Ensure user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Wait a moment for auth to initialize
        await Future.delayed(const Duration(milliseconds: 500));

        // Check again
        final retryUser = FirebaseAuth.instance.currentUser;
        if (retryUser == null) {
          throw Exception('Please sign in again to continue');
        }
      }

      // Get selected items
      final selectedItems =
          _allItems.where((item) => item.isSelected).toList();

      if (selectedItems.isEmpty) {
        throw Exception('No items selected');
      }

      // Convert to ProductCatalogItem format
      final products = <dynamic>[];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < selectedItems.length; i++) {
        final item = selectedItems[i];
        products.add({
          'id': '${timestamp}_cat_$i',
          'name': item.name,
          'sku': 'ITEM${(timestamp + i).toString().substring(8)}',
          'category': item.category,
          'unit': item.unit,
          'rate': item.rate,
          'barcode': '',
          'description': item.description ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      // Save to Firestore
      await _itemsService.addMultipleItemsFromMaps(products);

      // Clear catalog cache to force reload of new items
      _catalogService.clearCache();

      // Mark onboarding as complete if first time
      if (widget.isFirstTimeSetup && mounted) {
        context.read<app_auth.AuthProvider>().completeOnboarding();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added ${products.length} items to your catalogue!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate based on context
        if (widget.isFirstTimeSetup) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  const HomeDashboard(csvPath: 'assets/images/data/invoices.csv'),
            ),
            (route) => false,
          );
        } else if (widget.returnRoute != null) {
          // Pop back to the return route
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Just pop this screen
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving catalogue: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

// Helper class for editable catalogue items
class EditableCatalogueItem {
  final String originalName;
  String name;
  double rate;
  final String category;
  final String unit;
  final String? description;
  bool isSelected;

  EditableCatalogueItem({
    required this.originalName,
    required this.name,
    required this.rate,
    required this.category,
    this.unit = 'pcs',
    this.description,
    this.isSelected = false,
  });
}
