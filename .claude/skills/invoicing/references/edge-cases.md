# Edge Cases: Invoicing

---

## EC-INV-01: Return Over-Application (HIGH)
**Scenario:** Customer has `pendingReturnAmount = ₹500`. New invoice total = ₹200.
`applyPendingReturnsToInvoice()` applies the full ₹500 as `refundAdjustment`.
`adjustedTotal = 200 - 500 = -300`. Customer now has a negative payable amount.

**Current code:** No guard against `refundAdjustment > invoice.total`.
**Impact:** Invoice shows negative amount owed. Payment status logic (`remainingAmount < 0 → refundDue`)
is now wrong — it reads as "customer overpaid" when they actually got a discount larger than the invoice.
**What should happen:** `refundAdjustment = min(pendingReturnAmount, invoice.total)`.

---

## EC-INV-02: Floating-Point Currency Accumulation (HIGH)
**Scenario:** Customer makes 50 payments of ₹0.1 each. Due to IEEE 754 binary representation,
`0.1 * 50` in `double` arithmetic may not equal exactly `5.0`.
`amountPaid` accumulates via addition — each payment compounds the error.

**Current mitigation:** `isFullyPaid` uses epsilon `0.01`, which masks small errors.
**Unmitigated risk:** `remainingAmount` displayed to user may show ₹0.001 as outstanding.
**Root cause:** All monetary fields are `double`, not `int` paise or `Decimal`.
**What should happen:** Store amounts as integer paise (multiply by 100, store as int).

---

## EC-INV-03: Partial Payment on Cancelled Invoice (MEDIUM)
**Scenario:** Invoice is posted, customer pays ₹300 of ₹500. Invoice is then cancelled.
On cancellation, `amountPaid = 300` remains on the now-cancelled document.
`customer.totalPaid` was incremented by ₹300 but `customer.totalSpent` is now reversed.

**Impact:** Customer `outstandingAmount = totalSpent - totalPaid` becomes negative (credit).
No reconciliation logic handles the reversal of `totalPaid` on cancellation.
**What should happen:** On cancellation, reverse `totalPaid` increment too, and record a refund obligation.

---

## EC-INV-04: Duplicate Invoice Number (MEDIUM)
**Scenario:** Two devices create invoices simultaneously. Both generate the same `invoiceNumber`
(e.g. both read last number as INV-042 and create INV-043).

**Current code:** `invoiceNumber` uniqueness is not enforced at the Firestore security rules level.
**Impact:** Two invoices with the same number exist. PDF exports, customer references are ambiguous.
**What should happen:** Generate invoice numbers server-side or use a Firestore transaction.

---

## EC-INV-05: Status Mismatch Between Firestore and Model (MEDIUM)
**Scenario:** `InvoiceModel.fromJson()` has `status: json['status'] ?? 'pending'`.
`_parseStatus()` allows `'paid'`, `'pending'`, `'overdue'`, `'draft'` as valid statuses.
But `InvoiceStatus` enum uses `draft`, `posted`, `cancelled` — not `'pending'` or `'paid'`.

**Impact:** Firestore may contain `status: 'pending'` for invoices imported from CSV.
UI code that switches on `InvoiceStatus` values will fail to match these legacy strings.
**What should happen:** Add a migration or a mapping layer for legacy status strings.

---

## EC-INV-06: Return Applied to Draft Invoice (LOW)
**Scenario:** User creates a draft invoice, applies pending return credit. Draft is then deleted.
`refundAdjustment` was applied, `customer.pendingReturnAmount` was decremented,
but the draft never became a real invoice — the credit is consumed but no sale happened.

**What should happen:** Only allow return application on `posted` invoices, or restore the credit on draft deletion.

---

## EC-INV-07: Cancellation Race Condition (LOW)
**Scenario:** User A cancels invoice. Simultaneously, User B records a payment on the same invoice
(possible on multi-device). Firestore does not provide cross-document transactions by default here.

**Impact:** Invoice ends up cancelled with a final payment recorded after cancellation.
**What should happen:** Use a Firestore transaction to check status before recording payment.
