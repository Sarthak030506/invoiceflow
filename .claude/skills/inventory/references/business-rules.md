# Business Rules: Inventory

All rules extracted from `lib/services/inventory_service.dart` and `lib/services/return_service.dart`.

---

## 1. Stock Update Rules

**Never touch `currentStock` directly.** All changes go through service methods:
- `InventoryService.receiveStock(itemId, qty, unitCost, sourceRef)` → creates `StockMovement.IN`
- `InventoryService.issueStock(itemId, qty, sourceRef)` → creates `StockMovement.OUT`

```
IF receiveStock called:
  currentStock += qty
  create StockMovement(type: IN, quantity: qty, sourceRefId: sourceRef)
  update lastUpdated = now()

IF issueStock called:
  IF currentStock - qty < 0 THEN raise validation error (no negative stock)
  ELSE:
    currentStock -= qty
    create StockMovement(type: OUT, quantity: qty, sourceRefId: sourceRef)
    update lastUpdated = now()
```

---

## 2. Movement Type Rules

| Trigger | Method Called | Movement Type |
|---|---|---|
| Sales invoice posted | `issueStock()` | `OUT` |
| Purchase invoice posted | `receiveStock()` | `IN` |
| Sales return processed | `receiveStock()` with `return:{returnNumber}` | `RETURN_IN` |
| Purchase return processed | `issueStock()` with `return:{returnNumber}` | `RETURN_OUT` |
| Sales invoice cancelled | Reversal logic | `REVERSAL_OUT` |
| Manual correction | Direct adjustment | `ADJUSTMENT` |

---

## 3. Reorder Alert Logic

```
IF currentStock <= reorderPoint THEN
  mark item as low-stock
  show alert in dashboard low-stock count
  (no automatic reorder order is created)
```

Low-stock count appears in analytics dashboard card.
`reorderPoint` defaults to `0.0` if not set at item creation — disabling the alert effectively.

---

## 4. Invoice Cancellation Stock Reversal

When a **posted** invoice is cancelled:
```
FOR EACH item in invoice.items:
  IF invoiceType == 'sales':
    create REVERSAL_OUT movement  ← restores stock that was deducted on sale
    reversalOfMovementId = original OUT movement id
    reversalFlag = true
  IF invoiceType == 'purchase':
    create OUT movement to remove stock that was added on purchase
  currentStock adjusts accordingly
```

**Constraint:** The original movement must be located by `sourceRefId = invoice.id`.
If the original movement cannot be found (e.g. it was deleted), reversal may be incomplete.

---

## 5. Return Inventory Rules

**Sales Return** (customer returning goods to the business):
```
FOR EACH returnItem in return.items:
  find inventoryItem by fuzzy name match (getItemByName)
  IF found:
    receiveStock(itemId, returnItem.quantity, returnItem.price, 'return:{returnNumber}')
    creates RETURN_IN movement
```

**Purchase Return** (business returning goods to vendor):
```
FOR EACH returnItem in return.items:
  find inventoryItem by fuzzy name match
  IF found:
    issueStock(itemId, returnItem.quantity, 'return:{returnNumber}')
    creates RETURN_OUT movement
```

**Warning:** Item lookup uses fuzzy name match. If item name changed since invoice was created,
the match may fail silently — no error is thrown, inventory is just not updated.

---

## 6. Inventory Valuation

```
inventoryValue (per item) = currentStock * avgCost
totalInventoryValue (dashboard) = SUM of all item inventoryValues
```

`avgCost` is set at item creation and not recalculated as stock comes in at different prices.
Weighted average cost recalculation is not implemented.

---

## 7. Hardcoded Constants (Magic Numbers)
- **Reorder lead time:** 7 days (hardcoded in `InventoryForecastService`)
- **Service level factor:** 1.65 (hardcoded in `InventoryForecastService` for safety stock)
- These should be moved to constants or user-configurable settings.
