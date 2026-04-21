# Domain Model: Inventory

## InventoryItem
**File:** `lib/models/inventory_item_model.dart`

### Fields
| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Firestore document ID |
| `sku` | `String` | Stock Keeping Unit — should be unique per user |
| `name` | `String` | Display name — used for fuzzy matching on returns |
| `unit` | `String` | e.g. `'kg'`, `'pcs'`, `'box'` |
| `openingStock` | `double` | Stock at the time item was created |
| `currentStock` | `double` | Live stock level — DO NOT edit directly |
| `reorderPoint` | `double` | Alert fires when `currentStock <= reorderPoint` |
| `avgCost` | `double` | Weighted average cost per unit |
| `category` | `String` | Free-text category |
| `lastUpdated` | `DateTime` | Updated on every stock movement |
| `barcode` | `String?` | Optional barcode — manual entry only (no scanner yet) |

### Computed Getters
| Getter | Formula |
|---|---|
| `inventoryValue` | `currentStock * avgCost` |

### JSON Keys (Firestore)
Note: JSON uses snake_case keys for Firestore, but Dart fields are camelCase.
- `opening_stock` → `openingStock`
- `current_stock` → `currentStock`
- `reorder_point` → `reorderPoint`
- `avg_cost` → `avgCost`
- `last_updated` → `lastUpdated`

---

## StockMovement
**File:** `lib/models/stock_movement_model.dart`

### Fields
| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Firestore document ID |
| `itemId` | `String` | FK → inventory/{itemId} |
| `type` | `StockMovementType` | See enum below |
| `quantity` | `double` | Always positive — direction determined by type |
| `unitCost` | `double` | Cost per unit at time of movement |
| `sourceRefType` | `String` | e.g. `'invoice'`, `'return'`, `'adjustment'` |
| `sourceRefId` | `String` | ID of the source document |
| `createdAt` | `DateTime` | |
| `reversalOfMovementId` | `String?` | Points to original movement this reversal undoes |
| `reversalFlag` | `bool` | `true` = this is a reversal movement |
| `note` | `String?` | Free-text |

### StockMovementType Enum
| Value | Direction | Triggered By |
|---|---|---|
| `IN` | Stock increases | Purchase invoice posted |
| `OUT` | Stock decreases | Sales invoice posted |
| `ADJUSTMENT` | Either | Manual stock correction |
| `RETURN_IN` | Stock increases | Sales return processed (goods back in) |
| `RETURN_OUT` | Stock decreases | Purchase return processed (goods sent back) |
| `REVERSAL_OUT` | Stock increases | Invoice cancelled (undoes the original OUT) |

### Reversal Chain
```
Original movement:  StockMovement(id: 'mov-A', type: OUT, reversalFlag: false)
Reversal movement:  StockMovement(id: 'mov-B', type: REVERSAL_OUT, reversalFlag: true,
                                  reversalOfMovementId: 'mov-A')
```

---

## Firestore Paths
```
users/{uid}/inventory/{itemId}          ← InventoryItem
users/{uid}/stock_movements/{movId}     ← StockMovement
```
