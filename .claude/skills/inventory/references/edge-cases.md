# Edge Cases: Inventory

---

## EC-INV-STK-01: Return Quantity Exceeds Original Invoice Quantity (HIGH)
**Scenario:** Invoice has 5 units of "Rice Bag". Customer returns 8 units.
`ReturnService._processReturnInventory()` calls `receiveStock()` for 8 units.
No validation checks that return quantity ≤ quantity on original invoice.

**Impact:** Stock becomes inflated — business now shows more inventory than it actually has.
Customer gets a refund for items they never purchased.
**What should happen:** Validate `sum(returnItem.quantity) <= sum(matchingInvoiceItem.quantity)`
per item before creating the return.

---

## EC-INV-STK-02: Fuzzy Name Match Failure on Returns (HIGH)
**Scenario:** Invoice item name: `"Basmati Rice 5kg"`. Later, item is renamed in inventory to
`"Basmati Rice (5kg)"`. When return is processed, `getItemByName("Basmati Rice 5kg")` fails to match.

**Current behavior:** Fuzzy match returns `null`. Code does `if (inventoryItem != null)` check —
and silently skips inventory update. No error is thrown. No notification to user.
**Impact:** Return is recorded and refund is issued, but stock level is not restored.
Inventory shows less stock than physically exists.
**What should happen:** If item not found by name, match by last known item ID from invoice,
or surface a warning to the user to manually confirm the inventory update.

---

## EC-INV-STK-03: Reversal Movement Cannot Find Original (MEDIUM)
**Scenario:** Invoice is created, stock is deducted (OUT movement created). The OUT movement
document is then manually deleted from Firestore (or failed to write due to network error).
Invoice is later cancelled — reversal logic searches for the original OUT movement by `sourceRefId`.

**Current behavior:** If original movement not found, reversal logic may silently skip or error.
**Impact:** Invoice is marked cancelled but stock is NOT restored. Physical count doesn't match system.
**What should happen:** If original movement not found, create an ADJUSTMENT movement with a note,
and surface a warning in the admin audit log.

---

## EC-INV-STK-04: Concurrent Stock Deduction (MEDIUM)
**Scenario:** Two users on different devices both post invoices for the last 2 units of an item
at the same time. Each reads `currentStock = 2`, each deducts 2, both write `currentStock = 0`.
But physically, only 2 units existed — the system now shows 0 but actually -2 were "sold".

**Current behavior:** Firestore writes are last-write-wins without transactions.
Negative stock check happens before the write, but between the check and the write, another
device can deduct the same stock.
**What should happen:** Use a Firestore transaction for stock deductions:
`runTransaction → read currentStock → validate → decrement → commit`.

---

## EC-INV-STK-05: avgCost Not Updated on New Stock Receipt (MEDIUM)
**Scenario:** Item purchased at ₹10/unit. Later restocked at ₹15/unit via new purchase invoice.
`receiveStock()` updates `currentStock` but does not recalculate `avgCost`.

**Impact:** `inventoryValue` (= `currentStock * avgCost`) is understated.
Inventory valuation on dashboard is inaccurate once prices change.
**What should happen:** On each `receiveStock()`, recalculate weighted average:
`newAvgCost = (currentStock * avgCost + qty * unitCost) / (currentStock + qty)`.

---

## EC-INV-STK-06: Barcode Scanner Not Implemented (LOW)
**Scenario:** User taps "Scan Barcode" in the UI. Widget says "For demo, enter barcode manually."
No actual camera-based scanner is wired up.

**Impact:** Barcode field is manually entered — defeats the purpose. Lookups by barcode
may work in code, but usability for the field is broken.
**What should happen:** Integrate `mobile_scanner` or `flutter_barcode_scanner` package.
