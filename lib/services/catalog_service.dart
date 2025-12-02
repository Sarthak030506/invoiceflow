import '../models/catalog_item.dart';
import './firestore_service.dart';
import './items_service.dart';
import '../utils/app_logger.dart';

class CatalogService {
  // Singleton implementation
  static CatalogService? _instance;

  CatalogService._internal();

  static CatalogService get instance {
    _instance ??= CatalogService._internal();
    return _instance!;
  }

  final FirestoreService _fsService = FirestoreService.instance;
  final ItemsService _itemsService = ItemsService();

  // Cache for catalog items with custom rates
  Map<int, CatalogItem>? _catalogCache;
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(minutes: 5);

  // ID mapping: integer ID (hash) -> string ID (Firestore)
  final Map<int, String> _idMapping = {};

  // Get all catalog items (loads from ItemsService or falls back to default catalog)
  Future<List<CatalogItem>> getAllItems() async {
    try {
      // Check cache validity
      if (_catalogCache != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration) {
        return _catalogCache!.values.toList();
      }

      // Try to load from ItemsService (items_catalog collection)
      try {
        final productCatalogItems = await _itemsService.getAllItems();

        if (productCatalogItems.isNotEmpty) {
          // Convert ProductCatalogItem to CatalogItem
          // Use a hash of the ID to generate a consistent integer ID
          final catalogMap = <int, CatalogItem>{};
          _idMapping.clear(); // Clear old mappings

          for (final product in productCatalogItems) {
            // Use a hash of the string ID to create a consistent integer ID
            final intId = product.id.hashCode.abs();
            catalogMap[intId] = CatalogItem(
              id: intId,
              name: product.name,
              rate: product.rate,
            );
            // Store the mapping from int ID to string ID for updates
            _idMapping[intId] = product.id;
          }

          // Update cache
          _catalogCache = catalogMap;
          _lastCacheUpdate = DateTime.now();

          AppLogger.info('Loaded ${catalogMap.length} items from items_catalog', 'CatalogService');
          return catalogMap.values.toList();
        }
      } catch (e) {
        AppLogger.warning('Could not load from items_catalog, trying fallback', 'CatalogService');
      }

      // Fallback: Get custom rates from Firestore (old system)
      final customRates = await _fsService.getAllCatalogRates();

      // Create a map from default catalog
      final catalogMap = <int, CatalogItem>{};
      for (var item in ItemCatalog.items) {
        catalogMap[item.id] = item;
      }

      // Override with custom rates
      for (var customItem in customRates) {
        catalogMap[customItem.id] = customItem;
      }

      // Update cache
      _catalogCache = catalogMap;
      _lastCacheUpdate = DateTime.now();

      AppLogger.info('Loaded ${catalogMap.length} items from default catalog', 'CatalogService');
      return catalogMap.values.toList();
    } catch (e) {
      AppLogger.error('Failed to get all items', 'CatalogService', e);
      // Final fallback to default catalog
      return ItemCatalog.items;
    }
  }

  // Get a single item by ID
  Future<CatalogItem?> getItemById(int itemId) async {
    try {
      final items = await getAllItems();
      return items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      AppLogger.error('Failed to get item by ID', 'CatalogService', e);
      return null;
    }
  }

  // Update item rate
  Future<void> updateItemRate(int itemId, double newRate) async {
    try {
      // Validate rate
      if (newRate <= 0) {
        throw Exception('Rate must be positive');
      }

      // Get the original item
      final originalItem = ItemCatalog.items.firstWhere((item) => item.id == itemId);

      // Create updated item
      final updatedItem = CatalogItem(
        id: originalItem.id,
        name: originalItem.name,
        rate: newRate,
      );

      // Save to Firestore
      await _fsService.updateCatalogItemRate(updatedItem);

      // Clear cache to force refresh
      _catalogCache = null;
      _lastCacheUpdate = null;

      AppLogger.info('Item rate updated: ${originalItem.name} - ₹$newRate', 'CatalogService');
    } catch (e) {
      AppLogger.error('Failed to update item rate', 'CatalogService', e);
      rethrow;
    }
  }

  // Update item name and rate
  Future<void> updateItemNameAndRate(int itemId, String newName, double newRate) async {
    try {
      // Validate input
      if (newName.trim().isEmpty) {
        throw Exception('Item name cannot be empty');
      }
      if (newRate <= 0) {
        throw Exception('Rate must be positive');
      }

      // Get the Firestore string ID from the mapping
      final firestoreId = _idMapping[itemId];
      if (firestoreId == null) {
        throw Exception('Item not found in ID mapping');
      }

      // Get all items from ItemsService
      final allItems = await _itemsService.getAllItems();

      // Find the item to update using the Firestore ID
      final itemToUpdate = allItems.firstWhere(
        (item) => item.id == firestoreId,
        orElse: () => throw Exception('Item not found'),
      );

      // Create updated item
      final updatedItem = itemToUpdate.copyWith(
        name: newName.trim(),
        rate: newRate,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _itemsService.updateItem(updatedItem);

      // Clear cache to force refresh
      _catalogCache = null;
      _lastCacheUpdate = null;

      AppLogger.info('Item updated: $newName - ₹$newRate', 'CatalogService');
    } catch (e) {
      AppLogger.error('Failed to update item', 'CatalogService', e);
      rethrow;
    }
  }

  // Reset item rate to default
  Future<void> resetItemRate(int itemId) async {
    try {
      await _fsService.deleteCatalogItemRate(itemId);

      // Clear cache to force refresh
      _catalogCache = null;
      _lastCacheUpdate = null;

      AppLogger.info('Item rate reset to default', 'CatalogService');
    } catch (e) {
      AppLogger.error('Failed to reset item rate', 'CatalogService', e);
      rethrow;
    }
  }

  // Get default rate for an item
  double getDefaultRate(int itemId) {
    try {
      return ItemCatalog.items.firstWhere((item) => item.id == itemId).rate;
    } catch (e) {
      return 0.0;
    }
  }

  // Check if item has custom rate
  Future<bool> hasCustomRate(int itemId) async {
    try {
      final customRates = await _fsService.getAllCatalogRates();
      return customRates.any((item) => item.id == itemId);
    } catch (e) {
      return false;
    }
  }

  // Clear cache (useful for forcing refresh)
  void clearCache() {
    _catalogCache = null;
    _lastCacheUpdate = null;
    _idMapping.clear(); // Clear ID mapping when clearing cache
  }

  // Search items by name
  Future<List<CatalogItem>> searchItems(String query) async {
    try {
      final allItems = await getAllItems();
      final lowerQuery = query.toLowerCase();
      return allItems.where((item) =>
        item.name.toLowerCase().contains(lowerQuery)
      ).toList();
    } catch (e) {
      AppLogger.error('Failed to search items', 'CatalogService', e);
      return [];
    }
  }
}
