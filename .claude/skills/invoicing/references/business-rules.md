# Business Rules: Invoicing

All rules extracted from `lib/services/invoice_service.dart`, `lib/services/edit_invoice_service.dart`, and `lib/models/invoice_model.dart`.

---

## 1. Invoice Creation

**Sales Invoice:**
- IF `invoiceType = 'sales'` THEN deduct stock for each item (StockMovement.OUT) on post
- IF customer exists THEN increment `customer.totalSpent` and `customer.invoiceCount`
- IF customer exists THEN update `customer.lastPurchaseDate` = invoice date

**Purchase Invoice:**
- IF `invoiceType = 'purchase'` THEN add stock for each item (StockMovement.IN) on post
- Purchase invoices do NOT update customer stats (vendor-facing)

**Both types:**
- New invoice defaults to `status = 'draft'`
- Draft invoices do NOT trigger inventory movements
- Draft invoices set `isDeleted = false` by default
- `invoiceNumber` must be unique per user

---

## 2. Status Transitions

```
draft ──→ posted ──→ cancelled
  ↑                      ↑
  └──── cancelled ────────┘
```

**Draft → Posted:**
- IF `status = 'draft'` THEN allow transition to `'posted'`
- On posting: trigger inventory movements (OUT for sales, IN for purchases)
- On posting: update customer denormalized stats

**Posted → Cancelled:**
- BEFORE cancelling: check for dependent returns on this invoice
- IF dependent returns exist AND no admin override THEN block cancellation
- IF admin override THEN allow cancellation and log override reason
- On cancellation: create REVERSAL_OUT movements to undo original stock changes
- On cancellation: set `cancelledAt = DateTime.now()` and `cancelReason`
- On cancellation: reverse customer stat increments (`totalSpent`, `invoiceCount`)
- On cancellation: set `status = 'cancelled'`

**Draft → Cancelled:**
- Allowed without inventory reversal (draft never moved stock)
- Set `isDeleted = true` OR `status = 'cancelled'` (check implementation)

**No reverse transitions:**
- Posted invoice cannot return to draft
- Cancelled invoice cannot be un-cancelled

---

## 3. Payment Recording

```
IF new payment amount > 0:
  amountPaid += paymentAmount   // cumulative, not replacement
  paymentMethod = method        // updates to latest method
  IF pendingReturnAmount > 0:
    allow applying refundAdjustment to reduce adjustedTotal
```

**Payment status derivation:**
```
remaining = adjustedTotal - amountPaid

IF |remaining| < 0.01  → PaymentStatus.paidInFull
IF remaining > 0       → PaymentStatus.balanceDue (customer still owes)
IF remaining < 0       → PaymentStatus.refundDue  (customer overpaid)
```

**Overpayment:**
- IF `amountPaid > adjustedTotal` THEN `isOverpaid = true`
- Overpayment is allowed — no hard block
- Excess becomes a refundDue situation

**Partial payment:**
- Allowed at any time while `status = 'posted'`
- `remainingAmount` reflects balance still owed

---

## 4. Return Adjustments Applied to Invoice

When a sales return credit is applied to a new invoice:
```
invoice.refundAdjustment = min(customer.pendingReturnAmount, invoice.total)
invoice.adjustedTotal    = invoice.total - invoice.refundAdjustment
invoice.modifiedFlag     = true
invoice.modifiedReason   = "Return credit applied"
customer.pendingReturnAmount -= invoice.refundAdjustment
return.isApplied         = true
```

**Note:** No guard currently exists to prevent `refundAdjustment > total` — see edge-cases.md.

---

## 5. Invoice PDF Generation
- Generated from `InvoiceModel` fields
- Uses `pdf` + `printing` packages
- Tax line shown as 0 (because `taxRate = 0.0`)
- `adjustedTotal` used as the final amount shown, not `revenue`

---

## 6. Analytics Cache Invalidation Rule
After any invoice write (create, edit, payment, cancel):
```dart
await AnalyticsService().invalidateCache();
```
Failure to call this will leave stale data in the dashboard for up to 30 minutes.
