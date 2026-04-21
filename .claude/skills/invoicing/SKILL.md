# Skill: Invoicing

## Trigger Phrases — Load When Discussing
Invoice creation, invoice status transitions (draft / posted / cancelled), payment recording,
partial payments, overpayments, invoice cancellation with inventory reversal, return refund
adjustments applied to an invoice, tax calculation, `adjustedTotal` vs `revenue`, invoice type
(sales vs purchase), follow-up dates, or PDF export.

## Domain Summary
InvoiceFlow tracks two invoice types: **sales** (to customers) and **purchase** (from vendors).
An invoice's true payable amount is `adjustedTotal = total - refundAdjustment`, not `revenue`.
Payment can be partial, full, or over the invoice amount. Status is a simple one-way flow:
draft → posted. Cancelled is a terminal state reached from either draft or posted.
All inventory movements must be reversed when a posted invoice is cancelled.

## Critical Rules to Always Respect
- `taxRate` is hardcoded at `0.0` in `InvoiceModel` — there is no tax system yet
- `isFullyPaid` uses epsilon: `(adjustedTotal - amountPaid).abs() < 0.01` — do not use `==`
- `revenue` field is written at creation time and not kept in sync — use `effectiveRevenue` for analytics
- `amountPaid` accumulates across multiple payment calls — it is not replaced, it grows
- `modifiedFlag = true` + `refundAdjustment > 0` signals a return has been applied to this invoice
- Cancellation requires checking for dependent returns before proceeding; admin override exists but must be logged

## Files
| File | Purpose |
|---|---|
| `lib/models/invoice_model.dart` | Entity, all computed getters, InvoiceItem |
| `lib/services/invoice_service.dart` | CRUD, status transitions, payment recording |
| `lib/services/edit_invoice_service.dart` | Edit with inventory reversal |
| `lib/services/firestore_service.dart` | Firestore upsert patterns |
| `lib/services/csv_invoice_service.dart` | CSV import / migration |

## Reference Docs in This Skill
- `references/domain-model.md` — complete field list with types and defaults
- `references/business-rules.md` — status transitions and payment recording in IF/THEN/ELSE
- `references/edge-cases.md` — return over-application, partial payment edge cases, floating-point currency risk
