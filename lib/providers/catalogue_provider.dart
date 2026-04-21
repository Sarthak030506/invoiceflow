import 'package:flutter/foundation.dart';

import '../services/items_service.dart';

/// In-memory cache + search over the per-user `items_catalog` collection.
/// Autocomplete needs sub-ms search across keystrokes; one Firestore round-trip
/// per type would be slow and costly, so we hold the catalogue locally with a
/// short TTL and let writes invalidate it.
class CatalogueProvider extends ChangeNotifier {
  CatalogueProvider({ItemsService? service})
      : _service = service ?? ItemsService();

  final ItemsService _service;

  static const Duration _ttl = Duration(minutes: 5);

  List<ProductCatalogItem> _items = const [];
  DateTime? _loadedAt;
  bool _isLoading = false;
  Object? _lastError;

  List<ProductCatalogItem> get items => _items;
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;
  bool get isStale =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > _ttl;

  /// Load (or refresh) the catalogue. No-op if cache is fresh unless [force].
  Future<void> load({bool force = false}) async {
    if (!force && !isStale && _items.isNotEmpty) return;
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      _items = await _service.getAllItems();
      _loadedAt = DateTime.now();
    } catch (e) {
      _lastError = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronous in-memory search over the cached catalogue.
  /// Matches name, sku, or category (case-insensitive contains).
  List<ProductCatalogItem> search(String query, {int limit = 20}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <ProductCatalogItem>[];
    for (final item in _items) {
      if (item.name.toLowerCase().contains(q) ||
          item.sku.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q)) {
        out.add(item);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  /// Exact case-insensitive name lookup against the local cache.
  ProductCatalogItem? findByNormalizedNameCached(String name) {
    final n = ProductCatalogItem.normalize(name);
    for (final item in _items) {
      if (item.nameNormalized == n) return item;
    }
    return null;
  }

  /// Find existing catalogue entry or create one. Returns the item and ensures
  /// the local cache reflects the new state.
  Future<ProductCatalogItem> findOrCreate({
    required String name,
    required double rate,
    String category = 'General',
    String unit = 'pcs',
    String? barcode,
    String? description,
  }) async {
    final cached = findByNormalizedNameCached(name);
    if (cached != null) return cached;

    final item = await _service.findOrCreateByName(
      name: name,
      rate: rate,
      category: category,
      unit: unit,
      barcode: barcode,
      description: description,
    );

    if (!_items.any((i) => i.id == item.id)) {
      _items = [..._items, item];
      notifyListeners();
    }
    return item;
  }

  /// Drop the cache so the next read goes to Firestore.
  void invalidate() {
    _loadedAt = null;
    notifyListeners();
  }
}
