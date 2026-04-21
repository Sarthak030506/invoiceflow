# InvoiceFlow Memory Index

Project memory for Claude. Read the file that covers the topic you need.

| File | Contents |
|---|---|
| `domain-model.md` | All 7 entities with actual field names, types, and Firestore paths |
| `business-rules.md` | Core rules in IF/THEN/ELSE format extracted from the codebase |
| `production-blockers.md` | The 3 CRITICAL issues that must be fixed before launch — exact file locations |
| `open-questions.md` | All 13 known issues categorized as Critical / High / Medium |
| `decisions.md` | Architecture and design decisions made during development (starts empty) |

## Quick Facts
- App: InvoiceFlow — Flutter + Firebase + Razorpay + Gemini
- All data: `users/{uid}/` (multi-tenant)
- State: Provider (ChangeNotifier)
- Currency: `double` — floating-point risk is known and unresolved
- Tax: hardcoded 0.0% — no tax system implemented
- Test mode: `_testPremiumMode = true` in `lib/providers/subscription_provider.dart:14` (PRODUCTION BLOCKER)
