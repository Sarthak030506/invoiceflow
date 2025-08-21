import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InventoryDetailScreen extends StatelessWidget {
  final String itemId;
  
  const InventoryDetailScreen({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Item Details'),
      ),
      body: Center(
        child: Text('Details for item: $itemId'),
      ),
    );
  }
}
