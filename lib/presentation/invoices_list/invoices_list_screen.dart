import 'package:flutter/material.dart';

class InvoicesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Invoices'),
      ),
      body: ListView.builder(
        itemCount: 0, // TODO: Replace with actual invoice count
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Invoice #${index + 1}'),
          );
        },
      ),
    );
  }
}
