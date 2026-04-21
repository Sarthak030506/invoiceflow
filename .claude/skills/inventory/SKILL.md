# Skill: Inventory

## Trigger Phrases — Load When Discussing
Stock tracking, inventory movements, reorder points, low-stock alerts, stock valuation,
barcode lookup, SKU management, sales-triggered stock deductions (OUT), purchase-triggered
stock additions (IN), return stock adjustments (RETURN_IN / RETURN_OUT), invoice cancellation
stock reversal (REVERSAL_OUT), average cost calculation, or inventory forecasting.

## Domain Summary
Inventory tracks physical stock levels with a full audit trail of every change.
Every stock change creates a `StockMovement` record — there is no direct quantity edit.
When a sales invoice is posted, items are deducted (OUT). When cancelled, a REVERSAL_OUT
is created to undo the original movement. Returns add stock back (RETURN_IN for sales returns)
or remove it (RETURN_OUT for purchase returns). The reorder alert fires when
`currentStock <= reorderPoint`.

## Critical Rules to Always Respect
- Never edit `currentStock` directly — always go through `InventoryService.receiveStock()` or `issueStock()`
- Negative stock is blocked by validation — check before any deduction
- `inventoryValue = currentStock * avgCost` — computed, not stored
- `REVERSAL_OUT` movements link back to the original movement via `reversalOfMovementId`
- `reversalFlag = true` on the reversal movement; `reversalFlag = false` on all originals
- Item lookup for returns uses fuzzy name match — exact ID match is preferred when available
- `InventoryService` is NOT a singleton — instantiated with `new InventoryService()`

## Files
| File | Purpose |
|---|---|
| `lib/models/inventory_item_model.dart` | InventoryItem entity |
| `lib/models/stock_movement_model.dart` | StockMovement entity + StockMovementType enum |
| `lib/services/inventory_service.dart` | receiveStock(), issueStock(), getItemByName() |
| `lib/services/inventory_firestore_service.dart` | Firestore persistence for movements |
| `lib/models/inventory_forecast_model.dart` | Forecast output from Gemini AI |

## Reference Docs in This Skill
- `references/domain-model.md` — InventoryItem and StockMovement field lists
- `references/business-rules.md` — 6 movement types, when each fires, reorder logic
- `references/edge-cases.md` — return quantity > original invoice quantity, reversal ordering risks, negative stock
