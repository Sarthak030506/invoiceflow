# Edge Cases: Customers

---

## EC-CUST-01: Denormalized Stats Drift on Failed Write (CRITICAL)
**Scenario:** Invoice is posted. `customer.totalSpent` is incremented successfully.
Network drops. Invoice document write fails and is retried — but the stat was already
incremented. On retry, `totalSpent` is incremented a second time for the same invoice.

**Current protection:** None. There is no idempotency check, no Firestore transaction
spanning both writes, and no reconciliation job.
**Impact:** Customer shows higher `outstandingAmount` than reality. Over time, stats drift
and customer balances become unreliable.
**What should happen:** Wrap invoice + customer writes in a Firestore batch write.
Or store a "reconciliation hash" on the customer: recompute stats from raw invoices
on-demand if drift is detected.

---

## EC-CUST-02: totalPaid Not Reversed on Invoice Cancellation (HIGH)
**Scenario:** Customer pays ₹300 on a ₹500 invoice. Invoice is later cancelled.
`customer.totalSpent` is decremented by ₹500 (correct).
`customer.totalPaid` is NOT decremented — it remains ₹300 higher than reality.

**Impact:** `outstandingAmount = totalSpent - totalPaid` goes negative, showing the
customer as having a credit when they don't. AI payment risk model may read this as
low risk (customer "paid more than they owe").
**What should happen:** On cancellation, also decrement `totalPaid` by the `amountPaid`
on the cancelled invoice.

---

## EC-CUST-03: Return Over-Application to Invoice (HIGH)
**Scenario:** Customer has `pendingReturnAmount = ₹500`. New invoice `total = ₹200`.
`applyPendingReturnsToInvoice()` applies entire ₹500 as `refundAdjustment`.
`adjustedTotal = 200 - 500 = -300`. Invoice has a negative payable amount.

**Current code:** `amountToApply = customer.pendingReturnAmount` — no `min()` guard.
**Impact:** Invoice shows a negative amount. Customer gets a ₹300 "credit overshoot".
The ₹300 excess is lost — neither applied to a future invoice nor tracked as new pendingReturnAmount.
**What should happen:**
```dart
amountToApply = min(customer.pendingReturnAmount, invoice.total);
remainingCredit = customer.pendingReturnAmount - amountToApply;
customer.pendingReturnAmount = remainingCredit; // preserve unused credit
```

---

## EC-CUST-04: Phone Number Format Inconsistency (MEDIUM)
**Scenario:** Customer created with phone `9876543210`. Same customer re-added with `+919876543210`.
Duplicate check is by exact string match — these are two different strings.
Two customer records are created for the same person.

**Impact:** Outstanding balance split across two customer records. AI risk scores computed
separately. WhatsApp reminders sent to wrong format. Merging later is manual.
**What should happen:** Normalize phone numbers at write time (strip +91, leading zeros).
Or validate that all phones follow one format (10-digit Indian mobile).

---

## EC-CUST-05: lastPurchaseDate Not Rolled Back on Cancellation (MEDIUM)
**Scenario:** Customer has `lastPurchaseDate = 2024-03-15` (from Invoice A).
Invoice B is created on `2024-04-01` → `lastPurchaseDate` updates to `2024-04-01`.
Invoice B is then cancelled → `lastPurchaseDate` remains `2024-04-01` (wrong).
Reality: last real purchase was `2024-03-15`.

**Impact:** Customer timeline looks more recent than it is. Analytics and follow-up
logic using `lastPurchaseDate` produces incorrect results.
**What should happen:** On cancellation, recompute `lastPurchaseDate` from remaining posted invoices.

---

## EC-CUST-06: Negative outstandingAmount — No Credit Handling (MEDIUM)
**Scenario:** Customer overpays (e.g. pays ₹600 on a ₹500 invoice). `totalPaid > totalSpent`.
`outstandingAmount` goes negative. No UI or logic treats this as a credit to carry forward.

**Impact:** Customer's ₹100 excess is invisible — no "store credit" system exists.
**What should happen:** Detect negative `outstandingAmount` and surface it as a credit balance
with an option to apply to next invoice (similar to `pendingReturnAmount` flow).
