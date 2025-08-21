# Inventory Integration System

## Overview
The InvoiceFlow app now has a comprehensive inventory management system that automatically and reliably updates stock levels in real-time based on invoice transactions, returns, and manual adjustments.

## Key Features

### 1. Automatic Stock Updates
- **Purchase Invoices**: Automatically increase stock for each line item when posted
- **Sales Invoices**: Automatically decrease stock for each line item when posted
- **Draft Invoices**: Do not affect inventory until posted
- **Status Changes**: Posting/unposting invoices triggers appropriate inventory changes

### 2. Returns Processing
- **Sales Returns**: Customer returns goods → stock increases
- **Purchase Returns**: Return goods to supplier → stock decreases
- **Proper Movement Tracking**: All returns are recorded with appropriate movement types

### 3. Manual Adjustments
- **Positive/Negative Adjustments**: Manual increase/decrease with reason tracking
- **Validation**: Prevents negative stock unless explicitly allowed
- **Audit Trail**: All adjustments recorded with timestamps and reasons

### 4. Real-Time UI Updates
- **Live Notifications**: Stock changes trigger UI updates immediately
- **Low Stock Alerts**: Automatic notifications when items reach reorder points
- **Metrics Updates**: Dashboard metrics refresh automatically

### 5. Data Integrity
- **Transaction Safety**: All stock operations are atomic
- **Validation**: Prevents overselling and invalid operations
- **Error Handling**: Comprehensive error messages and rollback capabilities

## Implementation Details

### Services Architecture

#### InvoiceService
- Enhanced `addInvoice()` to process inventory only for posted invoices
- Enhanced `updateInvoice()` to handle status changes (draft ↔ posted)
- Added `processReturnInventory()` for handling returns
- Added `processAdjustmentInventory()` for manual adjustments
- Added `_reverseInvoiceInventory()` for unposting invoices

#### InventoryService
- Enhanced `receiveStock()` with validation and real-time updates
- Enhanced `issueStock()` with insufficient stock prevention
- Enhanced `adjustStock()` with delta-based calculations
- Added `_updateItemCurrentStock()` for immediate UI updates
- Integrated `InventoryNotificationService` for real-time notifications

#### InventoryNotificationService (New)
- Stream-based notifications for UI components
- Separate streams for low stock, item updates, and metrics
- Broadcast streams for multiple listeners

### Database Layer

#### InventoryDatabase
- Fixed adjustment calculations to use delta quantities
- Enhanced movement tracking with proper type handling
- Atomic transaction support for complex operations
- Audit trail support with reversal tracking

### Movement Types
```dart
enum StockMovementType {
  IN,           // Purchase receipts
  OUT,          // Sales issues
  ADJUSTMENT,   // Manual adjustments
  RETURN_IN,    // Sales returns
  RETURN_OUT,   // Purchase returns
  REVERSAL_OUT, // Invoice cancellations
}
```

## Usage Examples

### 1. Creating a Purchase Invoice
```dart
final purchaseInvoice = InvoiceModel(
  // ... invoice details
  invoiceType: 'purchase',
  status: 'posted', // This triggers inventory increase
  items: [
    InvoiceItem(name: 'Product A', quantity: 10, price: 50.0),
  ],
);
await invoiceService.addInvoice(purchaseInvoice);
// Stock for 'Product A' automatically increases by 10
```

### 2. Processing a Sales Return
```dart
await invoiceService.processReturnInventory(
  'return_001',
  'sales_return',
  [InvoiceItem(name: 'Product A', quantity: 2, price: 50.0)],
);
// Stock for 'Product A' increases by 2
```

### 3. Manual Stock Adjustment
```dart
await inventoryService.adjustStock(
  'product_a_id',
  -3.0, // Decrease by 3
  'Damaged goods removal',
);
// Stock decreases by 3 with reason tracked
```

### 4. Listening to Real-Time Updates
```dart
InventoryNotificationService().itemUpdatedStream.listen((item) {
  // Update UI when item stock changes
  setState(() {
    // Refresh item display
  });
});
```

## Error Handling

### Insufficient Stock
```dart
try {
  await inventoryService.issueStock('item_id', 10.0, 'invoice:123');
} catch (e) {
  // Shows: "Insufficient stock for Product Name. Available: 5, Required: 10"
}
```

### Invalid Adjustments
```dart
try {
  await inventoryService.adjustStock('item_id', -20.0, 'test');
} catch (e) {
  // Shows: "Adjustment would result in negative stock for Product Name: -15"
}
```

## Testing

Comprehensive integration tests verify:
- Purchase invoices increase stock correctly
- Sales invoices decrease stock correctly
- Returns work in both directions
- Adjustments calculate properly
- Draft invoices don't affect inventory
- Posting drafts triggers inventory changes
- Insufficient stock prevents overselling

Run tests with:
```bash
flutter test test/inventory_integration_test.dart
```

## Benefits

1. **Reliability**: All inventory changes are automatic and consistent
2. **Real-Time**: UI updates immediately reflect stock changes
3. **Audit Trail**: Complete history of all stock movements
4. **Validation**: Prevents common errors like overselling
5. **Flexibility**: Supports all business scenarios (sales, purchases, returns, adjustments)
6. **Performance**: Efficient database operations with proper indexing
7. **User Experience**: Live notifications and immediate feedback

## Future Enhancements

- Barcode scanning integration
- Batch/lot tracking
- Expiry date management
- Multi-location inventory
- Advanced reporting and analytics
- Integration with external systems