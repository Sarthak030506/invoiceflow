import 'package:flutter/material.dart';
import '../models/business_catalogue_template.dart';
import '../data/catalogues/grocery_catalogue.dart';
import '../data/catalogues/pharmacy_catalogue.dart';
import '../data/catalogues/electronics_catalogue.dart';
import '../data/catalogues/clothing_catalogue.dart';
import '../data/catalogues/stationery_catalogue.dart';
import '../data/catalogues/bakery_catalogue.dart';
import '../data/catalogues/hardware_catalogue.dart';
import '../models/catalog_item.dart';

class BusinessCatalogueService {
  // Singleton implementation
  static BusinessCatalogueService? _instance;

  BusinessCatalogueService._internal();

  static BusinessCatalogueService get instance {
    _instance ??= BusinessCatalogueService._internal();
    return _instance!;
  }

  // All available business catalogue templates
  static final List<BusinessCatalogueTemplate> allTemplates = [
    BusinessCatalogueTemplate(
      id: 'grocery',
      name: 'Grocery & General Store',
      description: 'Groceries, staples, spices, beverages, and household items',
      icon: Icons.shopping_basket,
      color: Colors.green,
      items: groceryCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'pharmacy',
      name: 'Pharmacy & Medical Store',
      description: 'Medicines, supplements, medical supplies, and first aid items',
      icon: Icons.medical_services,
      color: Colors.red,
      items: pharmacyCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'electronics',
      name: 'Electronics & Mobile Shop',
      description: 'Mobile accessories, computers, cables, chargers, and gadgets',
      icon: Icons.phonelink,
      color: Colors.blue,
      items: electronicsCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'clothing',
      name: 'Clothing & Fashion Store',
      description: 'Garments, fabrics, accessories, textiles for men, women & kids',
      icon: Icons.checkroom,
      color: Colors.purple,
      items: clothingCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'stationery',
      name: 'Stationery & Books',
      description: 'School supplies, office items, art materials, and printing',
      icon: Icons.edit_note,
      color: Colors.orange,
      items: stationeryCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'bakery',
      name: 'Bakery & Sweet Shop',
      description: 'Breads, cakes, pastries, sweets, cookies, and snacks',
      icon: Icons.cake,
      color: Colors.pink,
      items: bakeryCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'hardware',
      name: 'Hardware & Tools',
      description: 'Construction materials, plumbing, electrical, paint supplies',
      icon: Icons.handyman,
      color: Colors.brown,
      items: hardwareCatalogueItems,
    ),
    BusinessCatalogueTemplate(
      id: 'demo',
      name: 'Demo Catalogue',
      description: 'Hotel, restaurant, catering supplies with 133+ items',
      icon: Icons.restaurant,
      color: Colors.teal,
      items: ItemCatalog.items
          .map((item) => CatalogueTemplateItem(
                name: item.name,
                rate: item.rate,
                category: _getCategoryForDemoItem(item.name),
                unit: 'pcs',
              ))
          .toList(),
    ),
  ];

  // Get category for demo catalogue items
  static String _getCategoryForDemoItem(String itemName) {
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

  // Get template by ID
  BusinessCatalogueTemplate? getTemplateById(String id) {
    try {
      return allTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get multiple templates by IDs
  List<BusinessCatalogueTemplate> getTemplatesByIds(List<String> ids) {
    return allTemplates.where((template) => ids.contains(template.id)).toList();
  }

  // Merge multiple templates into one list
  List<CatalogueTemplateItem> mergeTemplates(List<String> templateIds) {
    final allItems = <String, CatalogueTemplateItem>{}; // Use map to avoid duplicates by name

    for (String id in templateIds) {
      final template = getTemplateById(id);
      if (template != null) {
        for (var item in template.items) {
          // If item doesn't exist, add it. If it exists, keep the first one
          if (!allItems.containsKey(item.name.toLowerCase())) {
            allItems[item.name.toLowerCase()] = item;
          }
        }
      }
    }

    return allItems.values.toList()..sort((a, b) => a.category.compareTo(b.category));
  }

  // Group items by category
  Map<String, List<CatalogueTemplateItem>> groupItemsByCategory(
      List<CatalogueTemplateItem> items) {
    final Map<String, List<CatalogueTemplateItem>> grouped = {};

    for (var item in items) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }

    // Sort items within each category by name
    grouped.forEach((key, value) {
      value.sort((a, b) => a.name.compareTo(b.name));
    });

    return grouped;
  }

  // Get popular items across all catalogues (for "Other/Custom" option)
  List<CatalogueTemplateItem> getPopularItems({int limit = 100}) {
    // Collect items that appear in multiple catalogues or are commonly used
    final popularItemNames = {
      // Common across multiple businesses
      'Salt (1kg)',
      'Sugar (1kg)',
      'Mineral Water (1ltr)',
      'Tissue Paper',
      'Plastic Bag',
      'Paper Bag',
      'Pen',
      'Notebook',
      'Battery AA',
      'Battery AAA',
      'Adhesive Tape',
      'Stapler',
      'Scissors',
      'Glue',
      'Marker Pen',
      'Cleaning Cloth',
      'Hand Sanitizer',
      'Face Mask',
      'Thermometer',
      'Calculator',
      'Torch Light',
      'Extension Cord',
      'Bulb LED 9W',
      'Wire',
      'Adapter',
      'Charger',
      'Cable',
      'Container',
      'Box',
    };

    final items = <CatalogueTemplateItem>[];

    // Collect matching items from all templates
    for (var template in allTemplates) {
      for (var item in template.items) {
        if (popularItemNames.any((name) => item.name.toLowerCase().contains(name.toLowerCase()))) {
          // Check for duplicates
          if (!items.any((existing) => existing.name.toLowerCase() == item.name.toLowerCase())) {
            items.add(item);
            if (items.length >= limit) break;
          }
        }
      }
      if (items.length >= limit) break;
    }

    return items;
  }

  // Search items across all templates
  List<CatalogueTemplateItem> searchItems(String query) {
    final results = <CatalogueTemplateItem>[];
    final lowerQuery = query.toLowerCase();

    for (var template in allTemplates) {
      for (var item in template.items) {
        if (item.name.toLowerCase().contains(lowerQuery) ||
            item.category.toLowerCase().contains(lowerQuery)) {
          // Avoid duplicates
          if (!results.any((existing) => existing.name.toLowerCase() == item.name.toLowerCase())) {
            results.add(item);
          }
        }
      }
    }

    return results;
  }

  // Convert template item to ProductCatalogItem for saving
  static Future<List<dynamic>> convertToProductCatalogItems(
      List<CatalogueTemplateItem> items) async {
    final products = <Map<String, dynamic>>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      products.add({
        'id': '${timestamp}_template_$i',
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

    return products;
  }

  // Get statistics about a selection
  Map<String, dynamic> getSelectionStats(List<String> templateIds) {
    final items = mergeTemplates(templateIds);
    final grouped = groupItemsByCategory(items);

    return {
      'totalItems': items.length,
      'totalCategories': grouped.length,
      'categoryBreakdown': grouped.map((key, value) => MapEntry(key, value.length)),
      'templates': templateIds.map((id) => getTemplateById(id)?.name ?? '').toList(),
    };
  }
}
