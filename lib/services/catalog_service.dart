import '../models/catalog_item.dart';
import './firestore_service.dart';
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

  // Cache for catalog items with custom rates
  Map<int, CatalogItem>? _catalogCache;
  DateTime? _lastCacheUpdate;
  static const _cacheValidityDuration = Duration(minutes: 5);

  // Get all catalog items (merges default catalog with custom rates from Firestore)
  Future<List<CatalogItem>> getAllItems() async {
    try {
      // Check cache validity
      if (_catalogCache != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration) {
        return _catalogCache!.values.toList();
      }

      // Get custom rates from Firestore
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

      return catalogMap.values.toList();
    } catch (e) {
      AppLogger.error('Failed to get all items', 'CatalogService', e);
      // Fallback to default catalog
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
