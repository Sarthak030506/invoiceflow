# Skill: Analytics

## Trigger Phrases — Load When Discussing
Analytics dashboard, revenue metrics, outstanding balances, inventory value, low-stock count,
date range filtering (Today / Last 7 days / Last 30 days / Last 90 days / This year / All time),
analytics cache, cache invalidation, SharedPreferences cache, multi-device data staleness,
AI business insights, payment risk prediction, inventory demand forecasting, Gemini AI,
Cloud Functions, subscription feature gating, or OCR receipt scanning.

## Domain Summary
`AnalyticsService` computes dashboard metrics from Firestore and caches results in
`SharedPreferences` for 30 minutes (key prefix: `analytics_cache_`). All date-range
filtering is done on the client after fetching — not server-side.
AI features run as Cloud Functions calling Gemini 1.5-flash. They require a premium
subscription. Fallback implementations exist for all 4 AI features in case the Cloud
Function fails.

## Critical Rules to Always Respect
- Cache TTL is 30 minutes — stale on multi-device setups where another device wrote data
- Cache must be invalidated after: invoice create/edit/cancel, return create, payment record
- `AnalyticsService().invalidateCache()` clears all `analytics_cache_*` SharedPreferences keys
- Date ranges calculate `startDate` from `DateTime.now()` at call time — "Today" = midnight of current day
- AI features are premium-gated via `SubscriptionProvider.isPremium`
- `_testPremiumMode = true` in `SubscriptionProvider` currently bypasses all premium checks (BLOCKER)
- Free tier: 5 OCR scans/month (`ocrScansRemaining`), no AI features
- Premium trial: 7 days, all features, created via `SubscriptionModel.createTrial()`
- Gemini API key stored in Firebase Functions config — never in client code

## AI Feature Map
| Feature | Cloud Function | Flutter Service | Fallback |
|---|---|---|---|
| Business Insights | `generateBusinessInsights` | `BusinessInsightsService` | Basic rule-based insights |
| Payment Risk | `predictPaymentRisk` | `PaymentRiskService` | Score calculated from payment history |
| Inventory Forecast | `forecastInventory` | `InventoryForecastService` | Simple moving average |
| OCR | `processOCR` | `OCRService` | Manual item entry |

## Files
| File | Purpose |
|---|---|
| `lib/services/analytics_service.dart` | Dashboard metrics + SharedPreferences cache |
| `lib/services/ai/business_insights_service.dart` | Calls generateBusinessInsights function |
| `lib/services/ai/payment_risk_service.dart` | Calls predictPaymentRisk function |
| `lib/services/ai/inventory_forecast_service.dart` | Calls forecastInventory function |
| `lib/services/ai/ocr_service.dart` | Calls processOCR function |
| `functions/src/index.ts` | All 4 Cloud Functions |
| `lib/providers/subscription_provider.dart` | Feature gating, `_testPremiumMode` BLOCKER |
| `lib/models/ai_insight_model.dart` | AIInsight, InsightType, InsightCategory, InsightPriority |

## Reference Docs in This Skill
- `references/domain-model.md` — AIInsight, PaymentRisk, InventoryForecast field lists
- `references/business-rules.md` — cache invalidation rules, date range logic, feature gating
- `references/edge-cases.md` — multi-device cache staleness, scale limits, subscription expiry race condition
