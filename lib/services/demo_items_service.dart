import '../models/catalog_item.dart';
import 'items_service.dart';

class DemoItemsService {
  static List<ProductCatalogItem> get demoItems {
    return ItemCatalog.items.map((catalogItem) {
      return ProductCatalogItem(
        id: 'demo_${catalogItem.id}',
        name: catalogItem.name,
        category: _getCategoryForItem(catalogItem.name),
        sku: 'SKU${catalogItem.id.toString().padLeft(3, '0')}',
        rate: catalogItem.rate,
        unit: _getUnitForItem(catalogItem.name),
        barcode: '',
        description: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  static String _getCategoryForItem(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('bag') || name.contains('pouch') || name.contains('container')) {
      return 'Packaging';
    } else if (name.contains('phenyl') || name.contains('cleaner') || name.contains('acid') ||
               name.contains('liquid') || name.contains('sponge') || name.contains('mop') ||
               name.contains('brush') || name.contains('duster')) {
      return 'Cleaning Supplies';
    } else if (name.contains('glass') || name.contains('cup') || name.contains('plate') ||
               name.contains('spoon') || name.contains('straw')) {
      return 'Disposables';
    } else if (name.contains('foil') || name.contains('wrap')) {
      return 'Kitchen Supplies';
    } else if (name.contains('gloves') || name.contains('cap') || name.contains('apron') ||
               name.contains('goggle')) {
      return 'Safety & Apparel';
    } else if (name.contains('paper') || name.contains('tissue') || name.contains('marker') ||
               name.contains('pen')) {
      return 'Stationery';
    }
    return 'General';
  }

  static String _getUnitForItem(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('ltr') || name.contains('liquid')) {
      return 'ltr';
    } else if (name.contains('kg') || name.contains('gm')) {
      return 'kg';
    } else if (name.contains('set')) {
      return 'set';
    } else if (name.contains('packet')) {
      return 'packet';
    }
    return 'pcs';
  }

  static Future<void> importDemoItems(ItemsService itemsService) async {
    // Import items to catalog in batches for better performance
    await itemsService.addMultipleItems(demoItems);
  }
}
