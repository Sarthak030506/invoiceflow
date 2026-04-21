# Business Rules — IF/THEN/ELSE Format

Extracted from actual service code. File references included for verification.

---

## Invoicing

**Creating an invoice:**
```
IF invoiceType == 'sales':
  THEN on post: issue stock for each item (StockMovement.OUT)
  THEN increment customer.totalSpent, invoiceCount, lastPurchaseDate
IF invoiceType == 'purchase':
  THEN on post: receive stock for each item (StockMovement.IN)
  (purchase invoices do NOT update customer stats)
```

**Status transitions:**
```
IF status == 'draft':
  THEN can transition to 'posted' (triggers inventory + customer updates)
  THEN can transition to 'cancelled' (no inventory reversal needed)
IF status == 'posted':
  THEN can transition to 'cancelled'
    IF dependent returns exist AND NOT admin override:
      THEN block cancellation
    ELSE:
      THEN create REVERSAL_OUT movements for all items
      THEN decrement customer.totalSpent and customer.invoiceCount
      THEN set cancelledAt, cancelReason, status = 'cancelled'
IF status == 'cancelled':
  THEN no further transitions allowed (terminal state)
```

**Payment recording:**
```
amountPaid += paymentAmount  (cumulative addition, not replacement)

remaining = adjustedTotal - amountPaid
IF |remaining| < 0.01:  THEN paymentStatus = paidInFull
IF remaining > 0:        THEN paymentStatus = balanceDue
IF remaining < 0:        THEN paymentStatus = refundDue (overpayment allowed)
```

**True payable amount:**
```
adjustedTotal = total - refundAdjustment
effectiveRevenue = adjustedTotal  (use this, NOT the 'revenue' field)
```

---

## Inventory

**Stock changes:**
```
NEVER edit currentStock directly.
IF receiving stock (purchase/return): InventoryService.receiveStock()
IF issuing stock (sale/return):       InventoryService.issueStock()

IF issueStock called AND currentStock - qty < 0:
  THEN raise validation error (negative stock blocked)
ELSE:
  THEN currentStock -= qty AND create StockMovement
```

**Low stock alert:**
```
IF currentStock <= reorderPoint:
  THEN flag as low-stock (shown in dashboard)
  (no automatic purchase order created)
```

**Returns inventory:**
```
IF returnType == 'sales':
  THEN receiveStock() for each return item (RETURN_IN movement)
IF returnType == 'purchase':
  THEN issueStock() for each return item (RETURN_OUT movement)
Item lookup: fuzzy name match via getItemByName()
IF item not found by name: THEN silently skip (inventory NOT updated)
```

---

## Customers

**Duplicate check:**
```
IF phoneNumber already exists for this uid:
  THEN reject customer creation
ELSE:
  THEN create customer with zeroed stats
```

**Stat updates:**
```
ON invoice posted (sales only):
  customer.totalSpent    += invoice.adjustedTotal
  customer.invoiceCount  += 1
  customer.lastPurchaseDate = invoice.date

ON payment recorded (sales only):
  customer.totalPaid += paymentAmount

ON invoice cancelled (sales only):
  customer.totalSpent    -= invoice.adjustedTotal
  customer.invoiceCount  -= 1
  # NOTE: totalPaid is NOT reversed — known gap (HIGH-05)
```

**Return credit lifecycle:**
```
ON sales return created:
  customer.pendingReturnAmount += return.refundAmount
  return.isApplied = false

ON return applied to invoice:
  amountToApply = customer.pendingReturnAmount  # ⚠️ no min() guard
  invoice.refundAdjustment = amountToApply
  invoice.modifiedFlag = true
  customer.pendingReturnAmount = 0.0
  return.isApplied = true
```

---

## Analytics

**Cache:**
```
TTL: 30 minutes (SharedPreferences, device-local)
Key prefix: 'analytics_cache_'

AFTER any invoice/return write:
  THEN AnalyticsService().invalidateCache()
  (failure to call this = stale dashboard for up to 30 min)
```

**Date ranges:**
```
'Today'        → DateTime(year, month, day)  (midnight)
'Last 7 days'  → now - 7 days
'Last 30 days' → now - 30 days
'Last 90 days' → now - 90 days
'This year'    → DateTime(year, 1, 1)
'All time'     → no date filter (fetches everything)
```

**AI feature gating:**
```
IF SubscriptionProvider._testPremiumMode == true:
  THEN grant access to all AI features  # PRODUCTION BLOCKER
ELSE IF subscription.isPremium == true:
  THEN grant access
ELSE:
  THEN show upgrade dialog

FOR OCR specifically:
  IF free tier AND ocrScansRemaining == 0:
    THEN block scan and show "used all 5 scans" message
  IF free tier AND ocrScansRemaining > 0:
    THEN allow scan AND decrement ocrScansRemaining
  IF premium:
    THEN always allow (ocrScansRemaining == -1)
```

---

## Subscription

**Trial:**
```
Duration: 7 days
Tier: premium during trial
Features: all AI features enabled
IF trialEndDate < now():
  THEN status = 'expired' (set by Cloud Function daily at UTC 02:00)
```

**Monthly reset (Cloud Function):**
```
Schedule: UTC 00:00 on 1st of each month (Asia/Kolkata)
Action: reset ocrScansRemaining = 5 for all free-tier users
```
