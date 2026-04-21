# Business Rules: Customers

All rules extracted from `lib/services/customer_service.dart` and `lib/services/return_service.dart`.

---

## 1. Customer Creation

```
IF phoneNumber already exists for this user THEN
  reject creation (duplicate prevention)
ELSE:
  create customer with default stats: totalSpent=0, totalPaid=0, invoiceCount=0
  pendingReturnAmount = 0.0
```

**Phone number deduplication:** Lookup is by exact `phoneNumber` string match.
Format inconsistency (e.g. `+919876543210` vs `9876543210`) defeats this check — both would be created.

---

## 2. Stats Update on Invoice Events

**When a sales invoice is POSTED:**
```
customer.totalSpent    += invoice.adjustedTotal
customer.invoiceCount  += 1
customer.lastPurchaseDate = invoice.date
customer.updatedAt     = now()
```

**When payment is RECORDED on a sales invoice:**
```
customer.totalPaid += paymentAmount
customer.updatedAt = now()
```

**When a posted sales invoice is CANCELLED:**
```
customer.totalSpent    -= invoice.adjustedTotal
customer.invoiceCount  -= 1
customer.updatedAt     = now()
```

**⚠️ NOT reversed on cancellation:**
- `customer.totalPaid` is NOT decremented when an invoice with a prior payment is cancelled
- `customer.lastPurchaseDate` is NOT rolled back to the previous invoice date

---

## 3. Pending Return Amount Lifecycle

**Phase 1 — Return Created (sales return only):**
```
CustomerService.addPendingReturn(customerId, refundAmount):
  customer.pendingReturnAmount += refundAmount
  ReturnModel.isApplied = false
```

**Phase 2 — Return Applied to New Invoice:**
```
ReturnService.applyPendingReturnsToInvoice(customerId, invoice):
  amountToApply = customer.pendingReturnAmount  // ⚠️ no min() guard
  invoice.refundAdjustment = amountToApply
  invoice.adjustedTotal    = invoice.total - amountToApply
  invoice.modifiedFlag     = true
  customer.pendingReturnAmount = 0.0
  return.isApplied = true
```

**Purchase returns do NOT affect `pendingReturnAmount`** — they are vendor-side, not customer-side.

---

## 4. Outstanding Amount Calculation

```
customer.outstandingAmount (computed, not stored):
  = customer.totalSpent - customer.totalPaid
```

**Cases:**
- `> 0` → customer still owes money
- `= 0` → all invoices paid
- `< 0` → customer has overpaid (credit balance, no automatic refund mechanism)

---

## 5. WhatsApp Payment Reminder

When "Send Reminder" is triggered from the customer screen:
```
open WhatsApp URL: whatsapp://send?phone={customerPhone}&text={reminderMessage}
```

**Constraint:** Requires WhatsApp to be installed on the device. No in-app messaging.
Phone number must be in international format for WhatsApp URL scheme.
No format validation exists — reminder may fail silently if number format is wrong.

---

## 6. Follow-up Scheduling

```
invoice.followUpDate = user-selected date
```

Follow-up dates are stored on the invoice, not on the customer.
No automatic notification system pushes at the follow-up date — local notifications are scheduled
at invoice creation time if follow-up date is set.

---

## 7. Cache Invalidation

After any customer write:
```
AnalyticsService().invalidateCache()
```

Customer stats changes affect dashboard outstanding balance metric.
