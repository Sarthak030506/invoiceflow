# InvoiceFlow — Project Guide for Claude

## App Overview
Flutter business management app: invoicing, customer management, inventory tracking, analytics.
Paid tier adds Gemini AI features (OCR receipts, business insights, payment risk, inventory forecasting).
Revenue model: Razorpay subscriptions (₹299/month, ₹2999/year).

## Tech Stack
| Layer | Technology |
|---|---|
| Frontend | Flutter 3.6+, Dart, Provider (ChangeNotifier) |
| Database | Cloud Firestore (multi-tenant under `users/{uid}/`) |
| Auth | Firebase Auth + Google Sign-In |
| AI | Gemini 1.5-flash via Cloud Functions (Node.js 18, TypeScript) |
| Payments | Razorpay |
| PDF | pdf + printing packages |
| Charts | FL Charts |
| Cache | SharedPreferences (analytics only, 30-min TTL, key prefix `analytics_cache_`) |

## Architecture Patterns
- **Multi-tenant**: every Firestore collection lives under `users/{uid}/`
- **State**: Provider only — no Riverpod, no Bloc, no GetX
- **Services**: Singleton via `ServiceName.instance` — except `InventoryService` (instantiated with `new InventoryService()`)
- **Error handling**: inconsistent — some services throw, some return empty lists silently; this is a known issue

## 7 Core Entities
1. `InvoiceModel` → `lib/models/invoice_model.dart`
2. `CustomerModel` → `lib/models/customer_model.dart`
3. `InventoryItem` → `lib/models/inventory_item_model.dart`
4. `StockMovement` → `lib/models/stock_movement_model.dart`
5. `ReturnModel` → `lib/models/return_model.dart`
6. `SubscriptionModel` → `lib/models/subscription_model.dart`
7. AI Models → `lib/models/ai_insight_model.dart`, `payment_risk_model.dart`, `inventory_forecast_model.dart`

---

## ⚠️ 3 PRODUCTION BLOCKERS — Must Fix Before Any Live Users

| # | Issue | File | Line |
|---|---|---|---|
| 1 | `_testPremiumMode = true` — every user gets premium free | `lib/providers/subscription_provider.dart` | 14 |
| 2 | Hardcoded Razorpay test keys (`rzp_test_1234567890` / `YOUR_SECRET_KEY`) | `lib/services/payment_service.dart` | 26–27 |
| 3 | No server-side payment verification (TODO comment — client trusts itself) | `lib/services/payment_service.dart` | 135 |

---

## Rules for Working in This Codebase

1. **Read before suggesting.** Always read a file before proposing changes to it.
2. **Discuss business logic first.** Never write code that changes how money, stock, or customer balances are calculated without agreeing on the rule first.
3. **Load the relevant skill.** Before touching invoice / inventory / customer / analytics logic, check `.claude/skills/`.
4. **Currency is `double` — flag it.** All monetary amounts use `double`. Floating-point drift is a known risk. Flag it whenever discussing money calculations.
5. **Customer stats are denormalized.** `totalSpent`, `totalPaid`, `invoiceCount` are written on every invoice change. Any invoice write must update the customer doc too, or stats drift.
6. **Invalidate analytics cache after writes.** Call `AnalyticsService().invalidateCache()` after any operation that affects invoice or return data.
7. **`adjustedTotal` is the real amount.** `total - refundAdjustment = adjustedTotal`. Never use `revenue` for payment comparisons — it's a legacy field.

## Skills
- `.claude/skills/invoicing/` — invoice lifecycle, payments, cancellation, return adjustments
- `.claude/skills/inventory/` — stock movements, reorder logic, 6 movement types, audit trail
- `.claude/skills/customers/` — balance tracking, denormalized stats, pendingReturnAmount
- `.claude/skills/analytics/` — 30-min cache, date ranges, AI-powered insights

## Agents
- `.claude/agents/domain-analyst.md` — maps business logic, always ends with open questions
- `.claude/agents/system-architect.md` — data model and Firestore architecture decisions
- `.claude/agents/edge-case-hunter.md` — stress-tests every rule, surfaces severity-rated problems
- `.claude/agents/production-auditor.md` — tracks all 13 known issues, verifies fixes are complete
