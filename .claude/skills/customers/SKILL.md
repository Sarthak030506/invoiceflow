# Skill: Customers

## Trigger Phrases — Load When Discussing
Customer creation, duplicate prevention, customer balance tracking, outstanding amount,
`totalSpent` / `totalPaid` / `invoiceCount` denormalized stats, `pendingReturnAmount`,
applying a sales return credit to a future invoice, phone number validation, customer CRM,
WhatsApp reminders, follow-up scheduling, or customer-level payment risk.

## Domain Summary
CustomerModel uses denormalized stats for performance: `totalSpent`, `totalPaid`,
and `invoiceCount` are updated in-place every time an invoice is created, paid, or
cancelled. These stats can drift if a write partially fails — there is no reconciliation job.
`outstandingAmount = totalSpent - totalPaid` is computed, not stored.
`pendingReturnAmount` tracks unspent sales return credits owed to the customer.
When that credit is applied to a new invoice, it becomes `refundAdjustment` on the invoice
and `isApplied = true` on the return.

## Critical Rules to Always Respect
- Duplicate prevention is by phone number — same phone = same customer
- `outstandingAmount` is computed: `totalSpent - totalPaid` (not a stored field)
- `pendingReturnAmount` grows on sales return creation (via `CustomerService.addPendingReturn()`)
- `pendingReturnAmount` shrinks when applied to an invoice (via `applyPendingReturnsToInvoice()`)
- Phone number is stored as a free-form String — no format validation exists (gap)
- Customer stats must be updated atomically with invoice writes — no two-phase commit exists
- `lastPurchaseDate` is updated to invoice date when a new invoice is created

## Files
| File | Purpose |
|---|---|
| `lib/models/customer_model.dart` | CustomerModel entity + outstandingAmount getter |
| `lib/services/customer_service.dart` | CRUD, addPendingReturn(), stats updates |
| `lib/services/return_service.dart` | applyPendingReturnsToInvoice() lives here |
| `lib/models/payment_risk_model.dart` | AI payment risk output per customer |

## Reference Docs in This Skill
- `references/domain-model.md` — complete CustomerModel field list with types and defaults
- `references/business-rules.md` — stats update rules, pendingReturnAmount lifecycle
- `references/edge-cases.md` — stats drift risk, over-application of returns, phone validation gap
