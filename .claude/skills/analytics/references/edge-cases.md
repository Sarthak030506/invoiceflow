# Edge Cases: Analytics & AI

---

## EC-ANLY-01: Multi-Device Cache Staleness (HIGH)
**Scenario:** User opens the app on Phone A. Analytics cache loads at 10:00 AM.
User's partner records a new invoice on Phone B at 10:15 AM.
User returns to Phone A at 10:20 AM — analytics cache is still valid (10 min old < 30 min TTL).
Dashboard shows stale revenue and outstanding figures.

**Current behavior:** No real-time invalidation across devices. Each device has its own
SharedPreferences cache.
**Impact:** Business decisions made on outdated data for up to 30 minutes.
**What should happen:** Either reduce TTL (e.g. 5 minutes), or use a Firestore real-time
listener on the analytics summary document and invalidate the local cache on remote write.

---

## EC-ANLY-02: Subscription Expiry Race Condition (MEDIUM)
**Scenario:** User's premium subscription expires at midnight. App is open.
Daily Cloud Function runs at UTC 02:00 (IST 07:30) to mark subscription as expired.
Between midnight and 07:30, the app still shows premium features as available.

**Current behavior:** `SubscriptionProvider` listens to a Firestore stream, but expiry
is only set by the Cloud Function — not enforced client-side at the moment of expiry.
`SubscriptionModel.daysRemaining` is computed from `endDate` but the `status` field
remains `'active'` until the Function runs.
**Impact:** Users get 7.5 hours of free premium access after expiry.
**What should happen:** Client-side check: if `endDate != null && DateTime.now().isAfter(endDate)`,
treat as expired regardless of `status` field.

---

## EC-ANLY-03: Client-Side Filtering at Scale (MEDIUM)
**Scenario:** Business has 5,000 invoices over 3 years. User selects "All time" analytics.
`AnalyticsService.getFilteredAnalytics('All time')` fetches ALL 5,000 invoices from Firestore,
transfers them over the network, then filters in Dart.

**Current behavior:** `getAllInvoices()` has no limit or pagination.
**Impact:** Slow load times, high Firestore read costs, potential OOM on low-end Android devices.
**What should happen:** Use Firestore server-side date filters and aggregate queries.
Or paginate in batches of 100 for "All time" range.

---

## EC-ANLY-04: Gemini API Timeout During High Load (MEDIUM)
**Scenario:** User triggers "Generate Insights" during a Gemini API traffic spike.
Cloud Function times out (default Firebase Function timeout: 60 seconds).
Flutter client receives a timeout error.

**Current behavior:** Falls back to rule-based insights, `isAIPowered = false`.
**Good:** Fallback exists. **Gap:** User is not clearly informed that they got degraded results.
UI may show "AI Insights" branding even when `isAIPowered = false`.
**What should happen:** Show a badge or label "Basic insights — AI temporarily unavailable"
when `isAIPowered == false`.

---

## EC-ANLY-05: Usage Counter Not Rolled Back on Failed AI Call (LOW)
**Scenario:** `SubscriptionService` increments `aiInsightsGenerated` before calling Gemini.
Cloud Function call fails. Counter was already incremented.

**Current behavior:** Usage is counted even when AI call fails.
**Impact:** Free-tier users may hit their limit sooner due to failed calls eating their quota.
**What should happen:** Increment counter only after a successful AI response.

---

## EC-ANLY-06: OCR Fuzzy Match Creates Wrong Invoice Items (LOW)
**Scenario:** Receipt has "Amul Butter 500g". Catalog has "Amul Butter 200g".
Fuzzy matcher considers these similar enough and maps to the wrong item.
User creates invoice with wrong item at wrong price without noticing.

**Current behavior:** Fuzzy matching on name similarity only — no price or quantity verification.
**Impact:** Invoice created with incorrect inventory item, wrong stock deducted, wrong cost.
**What should happen:** Show OCR match results with confidence score. Require user confirmation
when confidence is below threshold (e.g. < 80%).

---

## EC-ANLY-07: testPremiumMode Shipping to Production (CRITICAL)
**Scenario:** Developer forgets to set `_testPremiumMode = false` before release.
All users of the production app have unlimited premium access.

**Current location:** `lib/providers/subscription_provider.dart` line 14.
**Impact:** Zero subscription revenue. Razorpay integration is never tested in real conditions.
No way to recover revenue from users who used premium for free.
**What should happen:** Gate this behind a compile-time constant or build flavor.
Never use a Dart `const bool` for this — it compiles to the literal value and cannot
be changed without a code release.
