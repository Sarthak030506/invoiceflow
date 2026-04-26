# Production Blockers

These 3 issues MUST be fixed before any live users touch the app.
Verified against actual source code.

---

## BLOCKER 1 — Free Premium for Everyone

**File:** `lib/providers/subscription_provider.dart`
**Line:** 14

```dart
// TODO: Set to false before production release
static const bool _testPremiumMode = true;
```

**Line 22 — how it's used:**
```dart
bool get isPremium => _testPremiumMode || (_subscription?.isPremium ?? false);
```

**Effect:** `_testPremiumMode = true` short-circuits the OR. Every user gets `isPremium = true`.
Every AI feature gate passes. Every OCR scan limit is bypassed. Subscription revenue = ₹0.

**Fix required:** Set `_testPremiumMode = false`. Verify that `isPremium` correctly returns
`false` for a free-tier user with no active subscription.

**Risk of fix:** Existing test users who relied on free premium will lose access. Test the
full subscription flow (Razorpay → webhook → Firestore update → UI refresh) end-to-end.

---

## BLOCKER 2 — Hardcoded Razorpay Test Keys

**File:** `lib/services/payment_service.dart`
**Lines:** 26–27

```dart
static const String _razorpayKeyId = 'rzp_test_1234567890'; // REPLACE THIS
static const String _razorpayKeySecret = 'YOUR_SECRET_KEY'; // REPLACE THIS
```

**Effect:** Payment flow opens with test keys. Test keys never charge real money.
Even if a user completes the Razorpay checkout, no real payment is captured.

**Fix required:**
1. Obtain production keys from Razorpay dashboard
2. Do NOT hardcode them in Dart source (they'll be in the compiled binary)
3. Recommended approach: Firebase Remote Config or environment-specific build config
4. `_razorpayKeySecret` is used for signature verification — store server-side only

**Risk:** Production keys in client code are extractable from the APK.
The key ID (`rzp_live_...`) must be in the client. The key secret must NEVER be in the client.

---

## BLOCKER 3 — No Server-Side Payment Verification

**File:** `lib/services/payment_service.dart`
**Line:** 135 (inside `verifyAndUpgradeSubscription()`)

```dart
// In production, you should verify the payment signature with your backend
// For now, we'll trust the client-side success callback
// TODO: Add server-side verification

// Upgrade subscription
await SubscriptionService.instance.upgradeToPremium(paymentId, plan: plan);
```

**Effect:** Any call to `verifyAndUpgradeSubscription(paymentId: 'fake_id', plan: 'yearly')`
will upgrade the user to premium with no real payment. A motivated user can intercept
the Dart code or call this directly.

**Fix required:**
1. Create a Firebase Cloud Function `verifyRazorpayPayment(paymentId, orderId, signature)`
2. In the function, compute: `HMAC-SHA256(orderId + '|' + paymentId, razorpayKeySecret)`
3. Compare computed hash to `signature` from Razorpay callback
4. Only call `upgradeToPremium()` from the Cloud Function after successful verification
5. Never call `upgradeToPremium()` from client code directly

**Razorpay signature verification spec:**
```
generated_signature = HMAC-SHA256(razorpay_order_id + "|" + razorpay_payment_id, key_secret)
IF generated_signature == razorpay_signature: payment is authentic
```

---

## Current Status

| Blocker | Status | Resolved |
|---|---|---|
| BLOCKER 1 — testPremiumMode | **RESOLVED** | 2026-04-15 |
| BLOCKER 2 — Razorpay test keys | **RESOLVED** | 2026-04-15 |
| BLOCKER 3 — No server verification | **RESOLVED** | 2026-04-15 |

**Original 3 blockers resolved. Analytics audit on 2026-04-26 found 7 new launch blockers (see below).**

---

## Resolution Details

### BLOCKER 1 — RESOLVED 2026-04-15
- `_testPremiumMode` set to `false` in `lib/providers/subscription_provider.dart:13`
- Verified: Free Plan shown correctly in app. Subscription gate enforced.

### BLOCKER 2 — RESOLVED 2026-04-15
- `_razorpayKeyId` replaced with `String.fromEnvironment('RAZORPAY_KEY_ID')` — injected via `--dart-define` at build time (`scripts/build.sh`)
- `_razorpayKeySecret` removed from client entirely — stored in Firebase Secret Manager as `RAZORPAY_KEY_SECRET`
- `RAZORPAY_KEY_ID` also stored in Secret Manager for server-side Razorpay Orders API calls

### BLOCKER 3 — RESOLVED 2026-04-15
- `createRazorpayOrder` Cloud Function: creates Razorpay Order server-side before checkout opens, returns `orderId`
- `verifyRazorpayPayment` Cloud Function: verifies `HMAC-SHA256(orderId|paymentId)` using `RAZORPAY_KEY_SECRET` from Secret Manager; writes subscription upgrade via Admin SDK on success
- Firestore rule `allow write: if false` on subscription documents enforces server-only writes
- Verified end-to-end: test payment via netbanking completed, subscription upgraded in Firestore

---

## Analytics Blockers — Found 2026-04-26

Audit of `lib/services/analytics_service.dart` revealed 7 new launch blockers.

### BLOCKER 4 — Named-Customer PII in Device Log

**File:** `lib/services/analytics_service.dart`
**Lines:** 727–732

Hardcoded debug filter: if customer name contains `"dadu"` or `"tejas"`, emits the customer's
invoice number, total, refundAdjustment, amountPaid, adjustedTotal, and running outstanding
balance to the Android log on every `getCustomerWiseRevenue` call.
Other apps with READ_LOGS permission can read this. Must be deleted entirely.

### BLOCKER 5 — All Top-5 Customers' Financials Logged on Every Call

**File:** `lib/services/analytics_service.dart`
**Line:** 775

Every call to `getCustomerWiseRevenue` prints the name, invoice count, revenue, paid amount,
outstanding amount, and pending refunds for every customer in the result set. PII leak to
device log in production. Delete this `print()` call.

### BLOCKER 6 — Analytics Cache Not UID-Scoped (Cross-User Data Leak)

**File:** `lib/services/analytics_service.dart`
**Line:** ~37, ~115 (cache key construction)

Cache keys are `analytics_cache_filtered_analytics_${dateRange}_${salesOnly}` with no UID
segment. On a shared/family device: User A's cached revenue/client data is served to User B
for up to 30 minutes after sign-in. Fix: prepend current UID to every cache key. Also call
`invalidateCache()` on sign-out in AuthProvider.

### BLOCKER 7 — Item Revenue Ignores refundAdjustment (Pre-Refund Overstating)

**File:** `lib/services/analytics_service.dart`
**Lines:** ~173, ~191 (`_computeFilteredAnalytics`)

Item-level revenue uses `price * quantity` (gross). The `refundAdjustment` on the invoice is
never deducted. Top-selling-items table shows inflated revenue on any invoice with a refund.
Invoice-level totals use `effectiveRevenue` (correct); item-level does not — the numbers do
not reconcile.

### BLOCKER 8 — Returns Processing Commented Out with Debug Print

**File:** `lib/services/analytics_service.dart`
**Lines:** ~203–204

```dart
// Skip returns processing for now to debug average price issue
print('Skipping returns processing for debugging');
```

The returns-deduction block in `_computeFilteredAnalytics` is permanently disabled. Item
analytics never subtracts returns. Every business using returns sees overstated item revenue.
This is a committed debug bypass.

### BLOCKER 9 — Offline Firestore Exception Cached as Empty Result

**File:** `lib/services/analytics_service.dart`
**Line:** ~231 (`catch (e)` in `_computeFilteredAnalytics`)

If Firestore throws on a network failure, `[]` is returned and written to SharedPreferences
as a valid fresh cache entry. For the next 30 minutes, analytics returns zero revenue even
after connectivity is restored. Fix: do not cache on exception; let the prior cache entry
survive until TTL expires.

### BLOCKER 10 — Division by Zero in Overdue Buckets

**File:** `lib/services/analytics_service.dart`
**Line:** ~871

```dart
itemAmount = (item.price * item.quantity) * (remainingAmount / invoice.total);
```

If `invoice.total == 0` (zero-value invoice or malformed import), this produces `Infinity`
or `NaN` which flows into the aging bucket totals and corrupts all subsequent arithmetic in
that bucket. Fix: guard with `if (invoice.total == 0) continue;` or skip the per-item
apportionment and assign the full `remainingAmount` to the first item.

---

## Analytics Blockers Status

| Blocker | Status | Resolved |
|---|---|---|
| BLOCKER 4 — Named-customer PII log (dadu/tejas) | **RESOLVED** | 2026-04-26 |
| BLOCKER 5 — Top-5 customers' financials logged | **RESOLVED** | 2026-04-26 |
| BLOCKER 6 — Cache not UID-scoped | **RESOLVED** | 2026-04-26 |
| BLOCKER 7 — Item revenue ignores refundAdjustment | **RESOLVED** | 2026-04-26 |
| BLOCKER 8 — Returns processing disabled (debug bypass) | **RESOLVED** | 2026-04-26 |
| BLOCKER 9 — Offline exception cached as empty | **RESOLVED** | 2026-04-26 |
| BLOCKER 10 — Div-by-zero in overdue buckets | **RESOLVED** | 2026-04-26 |

## Resolution Details — Analytics Blockers (2026-04-26)

All fixes in `lib/services/analytics_service.dart`.

- **B4**: Deleted `if (contains('dadu') || contains('tejas'))` debug block (~lines 726–732)
- **B5**: Deleted `for (final customer in filteredResult.take(5)) { print(...) }` block (~line 773)
- **B6**: Added `_uidCachePrefix` getter using `FirebaseAuth.instance.currentUser?.uid`. All cache storage keys now scoped to `analytics_cache_${uid}_`. `invalidateCache()` now clears only the current user's keys.
- **B7**: `_computeFilteredAnalytics` now computes `refundScale = (adjustedTotal / total).clamp(0,1)` per invoice and multiplies each item's revenue by it, so item-level totals account for refund adjustments.
- **B8**: Re-enabled returns deduction block in `_computeFilteredAnalytics` (was disabled with "Skip returns processing for debugging" comment). Fetches `getReturns()`, filters to date range, subtracts `returnItem.totalValue` and `quantity` from matching item entries.
- **B9**: Removed outer `try/catch` from `_computeFilteredAnalytics` (exceptions now propagate). `_getCached` now wraps `compute()` in its own try/catch and returns `null` on failure without writing to cache.
- **B10**: Added `if (invoice.total == 0) continue;` guard in `getOverduePaymentsBuckets` item loop before `remainingAmount / invoice.total`.

**Remaining post-launch items** (not blockers, pre-existing):
- `allCustomers` fetched but unused in `getCustomerWiseRevenue` (line ~701)
- Dead null-aware expression in overdue buckets (line ~900)
- Sign-out does not call `invalidateCache()` in AuthProvider — stale data stays in SharedPreferences until TTL (not a security issue after B6 fix, but wastes storage)
