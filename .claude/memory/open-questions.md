# Open Questions & Known Issues

All 13 issues from the initial exploration audit. Categorized by severity.
Update status as issues are resolved. Add new issues as discovered.

---

## CRITICAL (3 issues)

### CRIT-01 — testPremiumMode Bypasses All Subscription Checks
- **File:** `lib/providers/subscription_provider.dart:13`
- **Code:** `static const bool _testPremiumMode = false;`
- **Impact:** All users get unlimited premium access. Zero subscription revenue.
- **Status:** FIXED
- **Review started:** 2026-04-14
- **Fixed:** 2026-04-15
- **Fix summary:** Changed `_testPremiumMode` from `true` → `false`. Full app rebuild required before release.

### CRIT-02 — Hardcoded Razorpay Test Keys
- **File:** `lib/services/payment_service.dart:28`
- **Code:** `_razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID')` — key secret removed from client entirely
- **Impact:** No real payments ever captured. App unusable for revenue.
- **Status:** FIXED
- **Review started:** 2026-04-14
- **Fixed:** 2026-04-15
- **Fix summary:** Key ID injected via `--dart-define=RAZORPAY_KEY_ID` at build time (see `scripts/build.sh`). Key secret moved server-side to Firebase Secret Manager; never sent to client.

### CRIT-03 — No Server-Side Payment Verification
- **File:** `lib/services/payment_service.dart` — `verifyAndUpgradeSubscription()`
- **Code:** Calls `verifyRazorpayPayment` Cloud Function with `paymentId`, `orderId`, `signature`, `plan`
- **Impact:** Anyone can claim payment succeeded and get premium for free.
- **Status:** FIXED
- **Review started:** 2026-04-14
- **Fixed:** 2026-04-15
- **Fix summary:** `verifyRazorpayPayment` Cloud Function added — verifies HMAC-SHA256(`orderId|paymentId`) against Razorpay signature using secret stored in Secret Manager. Subscription write now happens server-side via Admin SDK only on verified payment.

---

## HIGH (5 issues)

### HIGH-01 — Currency Stored as double
- **Scope:** All model files — all monetary fields are `double`
- **Risk:** Floating-point arithmetic drift accumulates with many payment additions
- **Example:** 50 payments of ₹0.1 each may not sum to exactly ₹5.00
- **Mitigation exists:** `isFullyPaid` uses epsilon `0.01` — partially masks the issue
- **Status:** IN REVIEW — EC-FLT-01
- **Fixed:** 2026-04-16
- **Fix summary:** Epsilon changed `< 0.01` → `<= 0.01` in all three places in `invoice_model.dart`. WhatsApp reminder now uses `adjustedTotal` instead of `total`. `CustomerService.roundMoney()` helper added — rounds to 2 decimal places after every monetary operation.

### HIGH-02 — Customer Stat Updates Not in Firestore Transaction
- **Scope:** Invoice write + customer stat update are two separate `await` calls
- **Risk:** Network failure between step 1 and step 2 leaves stats inconsistent
- **Result:** `totalSpent`, `totalPaid`, or `invoiceCount` can drift over time
- **Status:** IN REVIEW — EC-STATS-01
- **Fixed:** 2026-04-16
- **Fix summary:** Silent catch blocks in `addInvoice()` and `updateInvoice()` now log + rethrow. `cancelInvoice()` calls `updateCustomerStats()` post-cancellation (EC-PAY-01). Full atomic batch requires incremental stats design; accepted as eventual-consistent with visible failures.

### HIGH-03 — Return Quantity Not Validated Against Invoice
- **File:** `lib/services/return_service.dart` — `createReturn()`
- **Risk:** Customer can return 10 units when they only bought 5. Stock inflated, fraudulent refund.
- **Status:** IN REVIEW — EC-RET-01
- **Fixed:** 2026-04-16
- **Fix summary:** `createReturn()` fetches original invoice, validates each return item qty ≤ invoiced qty, and `refundAmount ≤ invoice.adjustedTotal`. Throws `ReturnValidationException` on failure — aborts before any write.

### HIGH-04 — applyPendingReturnsToInvoice Missing min() Guard
- **File:** `lib/services/return_service.dart` — `applyPendingReturnsToInvoice()`
- **Risk:** `refundAdjustment` can exceed `invoice.total` → `adjustedTotal` goes negative
- **Code gap:** `amountToApply = customer.pendingReturnAmount` with no cap
- **Status:** IN REVIEW — EC-RET-02
- **Fixed:** 2026-04-16
- **Fix summary:** `amountApplied` field added to `ReturnModel` (serialized in all 4 codec paths + Firestore). `applyPendingReturnsToInvoice()` tracks partial application; `isApplied` only set `true` when `amountApplied >= refundAmount`. Return update + customer `pendingReturnAmount` written atomically via `FirestoreService.applyReturnBatch()`.

### HIGH-05 — totalPaid Not Reversed on Invoice Cancellation
- **File:** `lib/services/invoice_service.dart` — cancellation logic
- **Risk:** If invoice had a payment recorded before cancellation, `customer.totalPaid` stays
  inflated. `outstandingAmount` goes negative. Customer appears to have credit they don't have.
- **Status:** IN REVIEW — EC-PAY-01
- **Fixed:** 2026-04-16
- **Fix summary:** `cancelInvoice()` calls `CustomerService.instance.updateCustomerStats()` after upsert. `updateCustomerStats()` filters `status != 'cancelled'` in both the accumulation loop and `invoiceCount` — cancelled invoices no longer inflate any stat.

### HIGH-06 — PAY-02: Orphaned Return Credit After Invoice Cancellation
- **File:** `lib/services/invoice_service.dart` — `cancelInvoice()` / `lib/services/customer_service.dart` — `updateCustomerStats()`
- **Risk:** When an invoice is cancelled and it has an unapplied sales return, `cancelInvoice()` calls `updateCustomerStats()` which correctly zeros `totalSpent` / `totalPaid` but does NOT touch `pendingReturnAmount`. The return credit (`customer.pendingReturnAmount`) remains non-zero. The customer receives free credit on their next invoice for goods returned from an order that was voided.
- **Example:** Invoice A posted ₹1000 → Return R1 created ₹200 credit → Invoice A cancelled → `pendingReturnAmount` still shows ₹200 → Next Invoice B reduced by ₹200 for free.
- **Fix needed:** `cancelInvoice()` must query unapplied returns linked to the cancelled invoice and subtract their `refundAmount - amountApplied` from `customer.pendingReturnAmount`, or call a new `cancelPendingReturnsForInvoice()` helper.
- **Status:** DEFERRED — post-launch
- **Discovered:** 2026-04-17 (edge-case review of NEW-PAY-01 fix)
- **Decision:** Deferred 2026-04-19. Edge case — requires the user to: (1) create a return, (2) not apply it, (3) cancel the original invoice, all before the next invoice is raised. Fix deferred to avoid introducing new cancellation flow complexity before release. Address in first post-launch patch.

### HIGH-07 — RET-06: TOCTOU Race on applyPendingReturnsToInvoice
- **File:** `lib/services/return_service.dart` — `applyPendingReturnsToInvoice()`
- **Risk:** The read (`getPendingReturnsByCustomerId`, `getCustomerById`) and the write (`applyAllReturnsBatch`) are not inside a Firestore transaction. Two devices creating invoices concurrently for the same customer both fetch the same pending returns with the same `amountApplied`, compute independent updates, and race to commit. Last write wins — the other device's `amountApplied` changes are silently discarded. The winning device's customer `pendingReturnAmount` is set without accounting for the other device's deduction.
- **Impact:** Same return credit can be double-spent across two simultaneous invoices. Customer gets 2× the credit they are owed.
- **Status:** FIXED
- **Fixed:** 2026-04-18
- **Fix summary:** (1) `_applyInProgress` boolean guard on `ReturnService` prevents same-device concurrent calls; resets in `finally` so failed calls remain retryable. (2) `applyAllReturnsBatch` (WriteBatch) replaced by `applyAllReturnsTransaction` (Firestore Transaction) in `FirestoreService` — all return documents and the customer document are read via `transaction.get()` inside the transaction; any concurrent write causes SDK auto-abort and retry. Computation callback pattern keeps business logic in `ReturnService`, transaction boundary in `FirestoreService`.

---

## MEDIUM (5 issues)

### MED-01 — No Pagination on getAllCustomers / getAllItems
- **File:** `lib/services/customer_service.dart`, `lib/services/inventory_service.dart`
- **Risk:** With 1000+ records, fetches the entire collection. Slow + high Firestore read cost.
- **Status:** OPEN
- **Discussed:** No
- **Decision:** —

### MED-02 — 30-Minute Analytics Cache Too Long for Multi-Device
- **File:** `lib/services/analytics_service.dart:13` — `_cacheExpiryMinutes = 30`
- **Risk:** Changes on Device B are invisible on Device A for up to 30 minutes.
- **Context:** Cache is in SharedPreferences — device-local, not shared.
- **Status:** OPEN
- **Discussed:** No
- **Decision:** —

### MED-03 — No Dev / Staging / Prod Environment Separation
- **Scope:** No build flavors, no .env files, test mode hardcoded in Dart constant
- **Risk:** Easy to ship test configuration to production. Already happened (CRIT-01).
- **Status:** OPEN
- **Discussed:** No
- **Decision:** —

### MED-04 — Inconsistent Error Handling Across Services
- **Scope:** `ReturnService` returns empty lists on error; `InvoiceService` throws; others vary
- **Risk:** Silent failures hide bugs. UI shows empty state instead of error message.
- **Status:** OPEN
- **Discussed:** No
- **Decision:** —

### MED-05 — Demo Code in Production Build
- **Files:** `lib/services/demo_items_service.dart`, demo catalogue templates
- **Risk:** Demo data can appear in production. Increases APK size unnecessarily.
- **Status:** OPEN
- **Discussed:** No
- **Decision:** —

### MED-08 — App Check: Firebase Console Enforcement Not Yet Enabled
- **Scope:** All Cloud Functions + Firestore + Firebase Storage
- **Risk:** `context.app` checks are wired in all 9 callable Cloud Functions, and the Flutter client activates App Check on startup. But Firebase infrastructure will NOT automatically reject requests with missing or invalid tokens until enforcement is explicitly turned ON in the Firebase Console for each product (Functions, Firestore, Storage). Until enforcement is on, the `context.app` check is the only gate — a call that bypasses App Check reaches the function and the check there rejects it, but the defence-in-depth is incomplete.
- **Fix:** After all clients have shipped the App Check update, go to Firebase Console → App Check → Apps → enable enforcement for Cloud Functions, Firestore, and Storage. **Do not enforce before the update is live on >95% of active devices** — old clients without App Check will be locked out.
- **Status:** OPEN — intentional rollout sequencing
- **Discovered:** 2026-04-21 (App Check wiring)
- **Decision:** —

### MED-09 — App Check: iOS DeviceCheck Requires Xcode Entitlement + Apple Portal Setup
- **Scope:** `ios/Runner/` Xcode project
- **Risk:** `DeviceCheck` is set as the iOS App Check provider in `main.dart`. DeviceCheck requires: (1) `com.apple.developer.devicecheck` capability in the Xcode project entitlements, (2) a DeviceCheck Key registered in Apple Developer Portal (Key ID + .p8 file), (3) that key registered in Firebase Console → App Check → Apps → iOS → DeviceCheck. Without this setup, `FirebaseAppCheck.instance.activate()` silently falls back or returns null tokens — every Cloud Function call fails the `context.app` check.
- **Fix:** In Xcode: Signing & Capabilities → + Capability → DeviceCheck. Register a DeviceCheck key at developer.apple.com, upload to Firebase Console. Alternatively use App Attest (stronger, requires iOS 14+) via `AppleProvider.appAttest`.
- **Status:** OPEN — requires manual Xcode + Apple portal work
- **Discovered:** 2026-04-21 (App Check wiring)
- **Decision:** —

### MED-10 — App Check: Play Integrity Requires Google Play Registration
- **Scope:** Android release builds
- **Risk:** `AndroidProvider.playIntegrity` is set for non-debug Android builds. Play Integrity only works when the app is distributed through Google Play and registered in Google Play Console. Sideloaded APKs (internal testing outside Play, CI builds, direct installs) will fail Play Integrity attestation — all Cloud Function calls fail `context.app` check on those devices.
- **Fix:** For pre-Play-Store testing: use `--dart-define=APP_CHECK_DEBUG=true` + add the debug token (printed to logcat on first run) to Firebase Console → App Check → Apps → Android → Debug tokens. For production: ensure the release APK/AAB is distributed via Google Play.
- **Status:** OPEN — requires Play Console setup before production release
- **Discovered:** 2026-04-21 (App Check wiring)
- **Decision:** —

### MED-07 — DIALOG-02: Admin Override Button Never Appears for Negative-Stock Case
- **File:** `lib/widgets/invoice_cancellation_dialog.dart` — `_buildActions()`
- **Risk:** `_showAdminOverride` is `true` only when `canCancel == false` (blocked). The button guard is `_showAdminOverride && !hasNegativeStock`. When the block IS negative stock, `hasNegativeStock` is also `true`, suppressing the button entirely. The admin override text field renders in `_buildContent()` but the "Override & Cancel" button is never shown for the negative-stock case — the only scenario where a stock-aware admin override makes sense.
- **Fix needed:** Rethink the override UX flow. Options: (A) Show override button when `_showAdminOverride` regardless of `hasNegativeStock`, accepting that admin can force-cancel past negative stock. (B) Separate the two blocking conditions (negative stock vs. dependent documents) into distinct UI paths, each with its own override button logic.
- **Status:** OPEN
- **Discovered:** 2026-04-18 (production-auditor review of DIALOG-01 fix)
- **Decision:** —

### MED-06 — BATCH-01: applyAllReturnsBatch Hits Firestore 500-Op Limit at ≥499 Returns
- **File:** `lib/services/firestore_service.dart` — `applyAllReturnsBatch()`
- **Risk:** The method writes one document per return plus one customer document in a single `WriteBatch`. Firestore's hard limit is 500 operations per batch. A customer with 499+ pending returns causes `batch.commit()` to throw. The exception propagates — no state is corrupted (clean failure), but the customer's returns can never be applied to any future invoice until the count drops below 499.
- **Fix needed:** Chunk `updatedReturns` into groups of ≤450 (matching the existing `_writeInBatches` pattern in `FirestoreService`), committing each chunk separately. Note: chunking breaks all-or-nothing atomicity across chunks.
- **Status:** OPEN
- **Discovered:** 2026-04-17 (edge-case review of NEW-RET-04 fix)
- **Decision:** —

---

## LOW (3 issues)

### LOW-01 — createReturn() Has Two Non-Transactional Writes
- **File:** `lib/services/return_service.dart` — `createReturn()`
- **Risk:** `createReturn()` writes the ReturnModel document (`_fsService.createReturn()`) and then separately calls `_customerService.addPendingReturn()` to increment `customer.pendingReturnAmount`. These are two independent `await` calls with no transaction wrapping them. If the process crashes or the network drops between the two writes, the return document exists in Firestore but `pendingReturnAmount` is not incremented — the customer has a return with no corresponding credit, or vice versa.
- **Impact:** Rare partial-failure state. The return document exists but the credit is never consumable. Requires manual reconciliation to detect.
- **Fix needed:** Wrap `_fsService.createReturn()` and `addPendingReturn()` in a `WriteBatch` or atomic operation. Lower priority than RET-06 because this requires a network failure at a specific millisecond, not just concurrent usage.
- **Status:** OPEN
- **Discovered:** 2026-04-18 (noted during RET-06 fix planning)
- **Decision:** —

### LOW-02 — ~124 print() Statements Leak Data in Production Builds
- **Scope:** `lib/services/analytics_service.dart` (44), `lib/presentation/analytics/modals/itemwise_revenue_modal.dart` (18), `lib/presentation/invoice_detail_screen/widgets/edit_invoice_dialog.dart` (22), and ~40 more across services/screens
- **Risk:** `print()` output is visible in Android logcat and iOS device console — any third-party app with `READ_LOGS` permission, or a developer with USB debugging, can read invoice amounts, customer names, and business analytics in plain text.
- **Fix:** Replace all `print()` calls with `AppLogger.debug()` (already gated by `kDebugMode`). Zero output in release builds.
- **Status:** OPEN
- **Discovered:** 2026-04-21 (production artifact audit)
- **Decision:** Deferred — needs a dedicated cleanup pass across ~15 files.

### LOW-03 — database_service.dart + inventory_database.dart Are No-Op SQLite Stubs
- **Files:** `lib/services/database_service.dart`, `lib/database/inventory_database.dart`
- **Risk:** Both files are commented as "minimal no-op stub — SQLite removed". They add dead weight to the build and could confuse future contributors into thinking SQLite is still active.
- **Fix:** Delete both files; grep for any remaining imports and remove them.
- **Status:** OPEN
- **Discovered:** 2026-04-21 (production artifact audit)
- **Decision:** Not yet scheduled — verify no remaining imports before deletion.

---

## How to Update This File

When an issue is resolved:
1. Change `Status:` to `FIXED`
2. Add `Fixed in:` with commit hash or PR reference
3. Add `Fix summary:` with one line describing what was done

When a new issue is discovered:
1. Add it under the appropriate severity section
2. Use the next available number in its severity category
3. Fill in File, Risk, Status = OPEN, Discussed = No

---

## Full Issue Status Table

| ID | Title | Severity | Status |
|---|---|---|---|
| CRIT-01 | testPremiumMode bypasses all subscription checks | CRITICAL | FIXED |
| CRIT-02 | Hardcoded Razorpay test keys | CRITICAL | FIXED |
| CRIT-03 | No server-side payment verification | CRITICAL | FIXED |
| HIGH-01 | Currency stored as double | HIGH | IN REVIEW |
| HIGH-02 | Customer stat updates not in Firestore transaction | HIGH | IN REVIEW |
| HIGH-03 | Return quantity not validated against invoice | HIGH | IN REVIEW |
| HIGH-04 | applyPendingReturnsToInvoice missing min() guard | HIGH | IN REVIEW |
| HIGH-05 | totalPaid not reversed on invoice cancellation | HIGH | IN REVIEW |
| HIGH-06 | Orphaned return credit after invoice cancellation (PAY-02) | HIGH | DEFERRED |
| HIGH-07 | TOCTOU race on applyPendingReturnsToInvoice (RET-06) | HIGH | OPEN |
| MED-01 | No pagination on getAllCustomers / getAllItems | MEDIUM | OPEN |
| MED-02 | 30-minute analytics cache too long for multi-device | MEDIUM | OPEN |
| MED-03 | No dev / staging / prod environment separation | MEDIUM | OPEN |
| MED-04 | Inconsistent error handling across services | MEDIUM | OPEN |
| MED-05 | Demo code in production build | MEDIUM | FIXED (2026-04-21) |
| MED-06 | applyAllReturnsBatch hits Firestore 500-op limit (BATCH-01) | MEDIUM | OPEN |
| MED-07 | Admin override button hidden for negative-stock case (DIALOG-02) | MEDIUM | OPEN |
| MED-08 | App Check: Firebase Console enforcement not yet enabled | MEDIUM | OPEN |
| MED-09 | App Check: iOS DeviceCheck entitlement not configured | MEDIUM | OPEN |
| MED-10 | App Check: Play Integrity requires Google Play registration | MEDIUM | OPEN |
| LOW-01 | createReturn() has two non-transactional writes | LOW | OPEN |
| LOW-02 | ~124 print() statements leak data in production builds | LOW | OPEN |
| LOW-03 | database_service.dart + inventory_database.dart are no-op stubs | LOW | OPEN |
| HIGH-07 | TOCTOU race on applyPendingReturnsToInvoice (RET-06) | HIGH | FIXED |

Production readiness: 3/21 issues FIXED, 5/21 IN REVIEW (fixes applied, not yet released). Blockers remaining: 0 critical.
All 3 critical blockers verified working in production on 2026-04-15.
HIGH-01 through HIGH-05 fixes applied 2026-04-16 on branch feature/ai-premium-subscription.
3 new issues discovered 2026-04-17 during edge-case review of fix round 2.
HIGH-07 (RET-06) fixed 2026-04-18 — WriteBatch replaced with Firestore Transaction + same-device double-tap guard.
MED-05 fixed 2026-04-21 — demo/test artifacts purged (movement_service_stub, notification_test_helper, test notification methods, _testPremiumMode flag).
App Check wired 2026-04-21 — Flutter client (Play Integrity/DeviceCheck), all 9 Cloud Functions (context.app guard), OCR converted from direct HTTP to httpsCallable. MED-08/09/10 track remaining operational steps.

---

## RESOLVED (not in original 13)

### NEW-PAY-01 — Stats Stuck Forever After Partial cancelInvoice() Failure
- **File:** `lib/services/invoice_service.dart` — `cancelInvoice()`
- **Status:** FIXED
- **Fixed:** 2026-04-17
- **Fix summary:** Split the early-exit guard from `if (invoice == null || invoice.status == 'cancelled') return` into two separate checks. When invoice is already cancelled on entry (retry case), the function now calls `updateCustomerStats()` before returning, breaking the stuck-state loop.

### NEW-RET-01 — Partial Returns Over-Applied on Second Invoice
- **File:** `lib/services/return_service.dart` — `applyPendingReturnsToInvoice()`
- **Status:** FIXED
- **Fixed:** 2026-04-17
- **Fix summary:** `amountToApply` now uses `remainingCredit = refundAmount - amountApplied` instead of `refundAmount`. Prevents a partially-applied return from being over-credited on the next invoice.

### NEW-RET-02 — getTotalPendingReturnAmount Inflated for Partial Returns
- **File:** `lib/services/return_service.dart` — `getTotalPendingReturnAmount()`
- **Status:** FIXED
- **Fixed:** 2026-04-17
- **Fix summary:** Changed `fold` from `r.refundAmount` to `r.refundAmount - r.amountApplied`. Now reports remaining credit, not the original grant.

### NEW-RET-03 — deleteReturn Removes Wrong Amount from pendingReturnAmount
- **File:** `lib/services/return_service.dart` — `deleteReturn()`
- **Status:** FIXED
- **Fixed:** 2026-04-17
- **Fix summary:** Changed from `removePendingReturn(refundAmount)` to `removePendingReturn(refundAmount - amountApplied)`. Only the unconsumed credit is removed; amounts already applied to invoices were already deducted from `pendingReturnAmount` by earlier batch writes.

### NEW-RET-04 — Partial Batch Success Loses Credit With No Invoice Reduction
- **File:** `lib/services/return_service.dart` — `applyPendingReturnsToInvoice()` / `lib/services/firestore_service.dart`
- **Status:** FIXED
- **Fixed:** 2026-04-17
- **Fix summary:** Replaced per-iteration `applyReturnBatch` calls with a single `applyAllReturnsBatch` after the loop. All return state changes + customer `pendingReturnAmount` update committed in one `WriteBatch`. Either everything writes or nothing does. `try/catch` removed so failures propagate to the caller.

### AI-01 — Wrong Gemini Model Name in Cloud Functions
- **File:** `functions/src/index.ts` — all 4 `getGenerativeModel()` calls
- **Code was:** `gemini-1.5-flash` → `gemini-1.5-flash-latest` → `gemini-2.0-flash`
- **Status:** FIXED
- **Fixed:** 2026-04-15
- **Fix summary:** Model iterated twice during deploy debugging. Final value `gemini-2.0-flash` deployed to all 4 AI Cloud Functions (processOCR, generateBusinessInsights, predictPaymentRisk, forecastInventory).
