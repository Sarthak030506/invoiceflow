# Domain Model: Analytics & AI

## AIInsight
**File:** `lib/models/ai_insight_model.dart`

### Fields
| Field | Type | Notes |
|---|---|---|
| `id` | `String` | UUID |
| `type` | `InsightType` | See enum below |
| `category` | `InsightCategory` | See enum below |
| `title` | `String` | Short insight headline |
| `description` | `String` | Full explanation |
| `actionText` | `String?` | CTA e.g. "Call this customer now" |
| `value` | `double?` | Numeric value (e.g. revenue amount) |
| `changePercent` | `double?` | % change vs previous period |
| `isPositive` | `bool` | `true` = green/good, `false` = red/warning |
| `priority` | `InsightPriority` | `high` / `medium` / `low` |
| `generatedAt` | `DateTime` | When insight was created |
| `metadata` | `Map<String,dynamic>?` | Extra AI context |

### InsightType Enum
- `trend` — Revenue/sales direction
- `alert` — Warnings or issues requiring action
- `opportunity` — Growth or upsell opportunities
- `milestone` — Achievement notifications
- `recommendation` — Specific actionable suggestions
- `general` — Catch-all

### InsightCategory Enum
- `revenue` / `products` / `customers` / `inventory` / `payments` / `growth`

### InsightPriority Enum
- `high` / `medium` / `low`

### BusinessInsightsReport (container)
| Field | Type | Notes |
|---|---|---|
| `insights` | `List<AIInsight>` | 5–8 insights per generation |
| `generatedAt` | `DateTime` | |
| `totalInsights` | `int` | Computed |
| `highPriorityCount` | `int` | Computed |
| `categoryBreakdown` | `Map<InsightCategory, int>` | Computed |
| `summary` | `String?` | AI-generated summary paragraph |
| `isAIPowered` | `bool` | `false` = fallback rule-based insights |

---

## PaymentRiskModel
**File:** `lib/models/payment_risk_model.dart`

| Field | Type | Notes |
|---|---|---|
| `customerId` | `String` | |
| `riskScore` | `double` | 0–100 |
| `riskLevel` | `String` | `critical` / `high` / `medium` / `low` |
| `totalOutstanding` | `double` | |
| `overdueInvoices` | `int` | |
| `maxDaysOverdue` | `int` | |
| `paymentReliability` | `double` | 0.0–1.0 |
| Risk factors | `List<Map>` | Each: `{name, impact, description}` |

---

## InventoryForecastModel
**File:** `lib/models/inventory_forecast_model.dart`

| Field | Type | Notes |
|---|---|---|
| `itemId` | `String` | |
| `dailyDemand` | `double` | Predicted units/day |
| `weeklyDemand` | `double` | Predicted units/week |
| `daysUntilStockout` | `int` | At current stock levels |
| `reorderPoint` | `double` | Recommended reorder threshold |
| `recommendedOrderQty` | `double` | Suggested purchase quantity |
| `confidenceLevel` | `double` | 0.0–1.0 |
| `seasonalNotes` | `String?` | Indian festival/seasonal context |
| Alert type | `String` | `stockout` / `overstock` / `slow_moving` / `seasonal_spike` |

---

## Analytics Cache
**Implemented in:** `lib/services/analytics_service.dart`

| Property | Value |
|---|---|
| Storage | `SharedPreferences` |
| Key prefix | `analytics_cache_` |
| Time key | `analytics_cache_time_{cacheKey}` |
| TTL | 30 minutes (1,800,000 ms) |
| Scope | Per date range + salesOnly flag |
| Invalidation | `AnalyticsService().invalidateCache()` — clears all `analytics_cache_*` keys |

**Date Range Options:**
- `'Today'` → `DateTime(now.year, now.month, now.day)` (midnight)
- `'Last 7 days'` → `now - 7 days`
- `'Last 30 days'` → `now - 30 days`
- `'Last 90 days'` → `now - 90 days`
- `'This year'` → `DateTime(now.year, 1, 1)`
- `'All time'` → no date filter

---

## Subscription Model (Feature Gating)
**File:** `lib/models/subscription_model.dart`

| Tier | OCR Scans | AI Insights | Risk Prediction | Inventory Forecast |
|---|---|---|---|---|
| `free` | 5/month | ❌ | ❌ | ❌ |
| `premium` | unlimited (-1) | ✅ | ✅ | ✅ |
| `trial` (7 days) | unlimited | ✅ | ✅ | ✅ |

**SubscriptionFeatures fields:**
- `ocrScansRemaining: int` — `-1` = unlimited
- `aiInsightsGenerated: int` — usage counter
- `riskPredictionsUsed: int` — usage counter
- `inventoryForecastsGenerated: int` — usage counter

**UsageLimits fields:**
- `ocrScansPerMonth: int`
- `aiInsightsPerMonth: int`
- `riskPredictionsEnabled: bool`
- `inventoryForecastEnabled: bool`
