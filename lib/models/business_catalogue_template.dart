import 'package:flutter/material.dart';

class BusinessCatalogueTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<CatalogueTemplateItem> items;

  const BusinessCatalogueTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class CatalogueTemplateItem {
  final String name;
  final double rate;
  final String category;
  final String unit;
  final String? description;

  const CatalogueTemplateItem({
    required this.name,
    required this.rate,
    required this.category,
    this.unit = 'pcs',
    this.description,
  });

  // Convert to ProductCatalogItem for saving
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rate': rate,
      'category': category,
      'unit': unit,
      'description': description,
    };
  }
}
