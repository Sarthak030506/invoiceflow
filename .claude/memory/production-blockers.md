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

**All 3 blockers resolved. Verified working in production on 2026-04-15.**

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
