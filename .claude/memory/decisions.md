# Architecture & Design Decisions

Decisions made during development discussions. Add entries here as decisions are made.

---

## Format

```
## DEC-{NNN} — {Short Title}
- **Date:** YYYY-MM-DD
- **Context:** Why this decision was needed
- **Options considered:** What alternatives were evaluated
- **Decision:** What was chosen
- **Rationale:** Why this option was chosen over the others
- **Consequences:** What this decision closes off or requires
- **Status:** Active | Superseded by DEC-{NNN}
```

---

## DEC-001 — Razorpay Key Secret Stays Server-Side via Secret Manager
- **Date:** 2026-04-15
- **Context:** CRIT-02 required removing hardcoded `rzp_test_1234567890` / `YOUR_SECRET_KEY` from `payment_service.dart`. Two options: env file or Secret Manager.
- **Options considered:** (A) `.env` file with gitignore, (B) Firebase Secret Manager + `defineSecret()`
- **Decision:** Secret Manager for the key secret; `--dart-define` at build time for the public key ID.
- **Rationale:** Key secret must never reach the client binary. Secret Manager is the right boundary — server-only, auditable, no risk of accidental commit.
- **Consequences:** Deploy requires `firebase functions:secrets:set RAZORPAY_KEY_SECRET`. Key ID must be passed at every `flutter build` via `scripts/build.sh`.
- **Status:** Active

## DEC-002 — Payment Verification Happens Server-Side Only
- **Date:** 2026-04-15
- **Context:** CRIT-03 — client was calling `upgradeToPremium()` directly after Razorpay success callback, with no signature check.
- **Options considered:** (A) Verify signature on client using stored secret (insecure), (B) Cloud Function verifies HMAC-SHA256 and writes subscription
- **Decision:** `verifyRazorpayPayment` Cloud Function — verifies `HMAC-SHA256(orderId|paymentId)`, writes subscription via Admin SDK on success.
- **Rationale:** Client cannot be trusted. Signature verification requires the key secret, which must stay server-side. Admin SDK bypasses Firestore `allow write: if false` rule on subscription documents.
- **Consequences:** `upgradeToPremium()` on the client is now dead code (subscription write happens in CF). A Razorpay Order must be created server-side for `orderId` to be non-empty in the callback.
- **Status:** Active

## DEC-004 — Razorpay Order Must Be Created Server-Side Before Checkout
- **Date:** 2026-04-15
- **Context:** Payment test revealed `orderId` and `signature` were null after checkout. Without a pre-created Razorpay Order, the SDK does not return these fields.
- **Options considered:** (A) Skip order creation, verify payment ID only (insecure), (B) Create order server-side before opening checkout
- **Decision:** `createRazorpayOrder` Cloud Function POSTs to Razorpay Orders API with Basic Auth (`key_id:key_secret`), returns `orderId` to Flutter. Flutter passes `order_id` into checkout options before opening.
- **Rationale:** Razorpay only returns a verifiable `orderId` + `signature` pair when a pre-created order exists. Without it, HMAC verification is impossible. This is underdocumented in Razorpay's Flutter guide.
- **Consequences:** Every payment attempt makes two CF calls (createOrder + verifyPayment). Cold start latency adds ~1–2s before checkout opens.
- **Status:** Active

## DEC-005 — Secret Manager Values Must Be .trim()ed at Runtime
- **Date:** 2026-04-15
- **Context:** `createRazorpayOrder` returned "Authentication failed" from Razorpay despite correct credentials in Secret Manager. `verifyRazorpayPayment` returned 403 despite mathematically correct HMAC.
- **Options considered:** N/A — root cause investigation
- **Decision:** All `defineSecret().value()` reads now call `.trim()` before use.
- **Rationale:** Firebase Secret Manager stores secret values with hidden trailing whitespace. The raw value passes visual inspection but corrupts HMAC computation and Basic Auth headers. `echo -n | openssl dgst` confirmed the trimmed value produces the correct signature.
- **Consequences:** Any future function that reads a secret via `defineSecret().value()` must also call `.trim()`. This is a Firebase SDK behaviour, not a one-time fix.
- **Status:** Active

## DEC-003 — Gemini Model Pinned to gemini-2.0-flash
- **Date:** 2026-04-15
- **Context:** Original code used `gemini-1.5-flash` which was not found in API version `v1beta`. Changed to `gemini-1.5-flash-latest`, then again to `gemini-2.0-flash` per user direction.
- **Options considered:** gemini-1.5-flash, gemini-1.5-flash-latest, gemini-2.0-flash
- **Decision:** `gemini-2.0-flash` across all 4 AI Cloud Functions.
- **Rationale:** User confirmed `gemini-2.0-flash` as the target model. 2.0-flash is faster and cheaper than 1.5-pro while being capable enough for OCR, insights, risk, and forecasting tasks.
- **Consequences:** If Google deprecates this model ID, all 4 functions need updating and redeploy.
- **Status:** Active
