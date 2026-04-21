# Business Rules: Analytics & AI

---

## 1. Analytics Cache Rules

```
ON any analytics read:
  cacheKey = "{dateRange}_{salesOnly}"
  IF SharedPreferences has analytics_cache_{cacheKey}:
    age = now() - analytics_cache_time_{cacheKey}
    IF age < 30 * 60 * 1000 ms:
      return cached JSON
    ELSE:
      fall through to compute
  compute fresh from Firestore
  store in SharedPreferences
  store timestamp in analytics_cache_time_{cacheKey}
```

**Cache invalidation (must call after these operations):**
- Invoice created, edited, payment recorded, or cancelled → `AnalyticsService().invalidateCache()`
- Return created → `AnalyticsService().invalidateCache()` (called inside `ReturnService.createReturn()`)
- Customer stats change does NOT automatically invalidate cache

---

## 2. Date Range Filtering

```
startDate = _calculateStartDate(dateRange):
  'Today'        → DateTime(year, month, day)        // midnight of today
  'Last 7 days'  → now() - 7 days
  'Last 30 days' → now() - 30 days
  'Last 90 days' → now() - 90 days
  'This year'    → DateTime(year, 1, 1)
  'All time'     → null (no filter)
```

Filtering is done **client-side** after fetching all records — no Firestore query filter.
At scale (1000+ invoices), this creates large reads.

---

## 3. AI Feature Access Rules

```
FOR any AI feature (insights, risk, forecast, OCR):
  IF SubscriptionProvider._testPremiumMode == true:
    grant access (PRODUCTION BLOCKER — bypasses all checks)
  ELSE IF subscription.isPremium == true:
    grant access
  ELSE:
    show upgrade dialog → /subscription route
```

**OCR special case:**
```
IF tier == free:
  IF ocrScansRemaining > 0:
    allow scan AND decrement ocrScansRemaining
  ELSE:
    show "You've used all 5 free OCR scans" dialog
IF tier == premium:
  ocrScansRemaining == -1 (unlimited) → always allow
```

---

## 4. Cloud Function Invocation Pattern

All AI features follow the same pattern in Flutter:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('functionName');
final result = await callable.call(inputData);
// parse result.data as JSON
```

Fallback pattern:
```
TRY: call Cloud Function
IF success: parse AI response, set isAIPowered = true
IF failure: run local fallback logic, set isAIPowered = false
```

All 4 AI features have fallback implementations — the app degrades gracefully.

---

## 5. Business Insights Generation Rules

Input to Gemini: last 30 days of invoices + all customers + inventory snapshot
Output: 5–8 `AIInsight` objects

**Fallback insights generated when AI unavailable:**
- Outstanding dues alert (if any customer has outstanding > 0)
- Low stock alert (if any item at or below reorder point)

Usage is tracked:
```
Firestore: users/{uid}/ai_usage → aiInsightsGenerated++
SubscriptionFeatures.aiInsightsGenerated++
```

---

## 6. Payment Risk Prediction Rules

Input to Gemini: customer payment history (invoice dates, amounts, payment dates)
Output: `PaymentRiskModel` with score 0–100 and risk factors

**Fallback score calculation (if AI unavailable):**
- Base on: days overdue, outstanding amount ratio, payment frequency
- Risk levels:
  - 80–100 → `critical`
  - 60–79  → `high`
  - 40–59  → `medium`
  - 0–39   → `low`

---

## 7. Inventory Forecast Rules

Input to Gemini: 90-day sales history per item
Output: `InventoryForecastModel` with demand predictions

**Hardcoded constants (not configurable):**
- Lead time: 7 days
- Service level factor: 1.65 (for safety stock calculation)
- Data limit: first 100 movements only (may miss older data)

**Indian seasonal factors considered:**
- Diwali, Dussehra, Holi, Eid, Christmas, New Year

---

## 8. OCR Receipt Processing Rules

Input to Gemini Vision: Firebase Storage URL of receipt image
Output: `{items: [{name, qty, price}], totalAmount, vendor, date}`

```
Supported formats: ₹, Rs., INR (and mixed Hindi/English)
Item matching: fuzzy match against user's catalog after extraction
Fuzzy match failure: item kept with raw OCR name, user must manually verify
```

**Free tier monthly reset:**
Cloud Function scheduled at UTC 00:00 on 1st of each month (Asia/Kolkata):
```
resets ocrScansRemaining = 5 for all free-tier users
```
