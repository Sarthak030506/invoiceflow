# Domain Model — All 7 Entities

## 1. InvoiceModel
**File:** `lib/models/invoice_model.dart`
**Firestore:** `users/{uid}/invoices/{invoiceId}`

```
id: String
invoiceNumber: String              # human-readable, not enforced unique at DB level
clientName: String                 # denormalized from Customer
customerPhone: String?
customerId: String?                # FK → customers/{id}
date: DateTime
revenue: double                    # LEGACY — written at creation, not updated
status: String                     # 'draft' | 'posted' | 'cancelled'
items: List<InvoiceItem>           # inline array, not sub-collection
notes: String?
createdAt: DateTime
updatedAt: DateTime
invoiceType: String                # 'sales' | 'purchase'
amountPaid: double                 # cumulative, grows with each payment
paymentMethod: String              # 'Cash' | 'Online' | 'Cheque'
followUpDate: DateTime?
isDeleted: bool                    # soft delete for drafts
cancelledAt: DateTime?
cancelReason: String?
modifiedFlag: bool                 # true when a return credit has been applied
modifiedReason: String?
modifiedAt: DateTime?
refundAdjustment: double           # return credit applied to this invoice

# Computed getters (not stored):
subtotal       = sum(item.price * item.quantity)
taxRate        = 0.0  ← HARDCODED, no tax system
total          = subtotal + taxAmount  (= subtotal while taxRate=0)
adjustedTotal  = total - refundAdjustment  ← TRUE PAYABLE AMOUNT
effectiveRevenue = adjustedTotal  ← use this for analytics, not 'revenue'
remainingAmount  = adjustedTotal - amountPaid  (negative = overpaid)
isFullyPaid    = (adjustedTotal - amountPaid).abs() < 0.01  ← epsilon!
paymentStatus  = paidInFull | balanceDue | refundDue
```

**InvoiceItem** (inline):
```
name: String
quantity: int
price: double
totalPrice = quantity * price  (computed)
```

---

## 2. CustomerModel
**File:** `lib/models/customer_model.dart`
**Firestore:** `users/{uid}/customers/{customerId}`

```
id: String
name: String
phoneNumber: String              # free-form, no format validation
pendingReturnAmount: double      # unspent sales return credit owed to customer
createdAt: DateTime
updatedAt: DateTime
totalSpent: double               # DENORMALIZED — sum of adjustedTotal from posted invoices
totalPaid: double                # DENORMALIZED — cumulative amountPaid across invoices
invoiceCount: int                # DENORMALIZED — count of posted invoices
lastPurchaseDate: DateTime?      # DENORMALIZED — date of most recent posted invoice

# Computed getter:
outstandingAmount = totalSpent - totalPaid
```

---

## 3. InventoryItem
**File:** `lib/models/inventory_item_model.dart`
**Firestore:** `users/{uid}/inventory/{itemId}`
**JSON keys:** snake_case (`opening_stock`, `current_stock`, `reorder_point`, `avg_cost`, `last_updated`)

```
id: String
sku: String
name: String                     # used for fuzzy matching on returns
unit: String                     # e.g. 'kg', 'pcs', 'box'
openingStock: double
currentStock: double             # DO NOT edit directly — use InventoryService methods
reorderPoint: double             # alert fires when currentStock <= reorderPoint
avgCost: double                  # NOT recalculated on restocking (gap)
category: String
lastUpdated: DateTime
barcode: String?                 # manual entry only — no scanner

# Computed getter:
inventoryValue = currentStock * avgCost
```

---

## 4. StockMovement
**File:** `lib/models/stock_movement_model.dart`
**Firestore:** `users/{uid}/stock_movements/{movId}`

```
id: String
itemId: String                   # FK → inventory/{itemId}
type: StockMovementType          # IN | OUT | ADJUSTMENT | RETURN_IN | RETURN_OUT | REVERSAL_OUT
quantity: double                 # always positive — direction from type
unitCost: double
sourceRefType: String            # 'invoice' | 'return' | 'adjustment'
sourceRefId: String              # ID of source document
createdAt: DateTime
reversalOfMovementId: String?    # links reversal to original movement
reversalFlag: bool               # true = this is a reversal movement
note: String?
```

**Movement type triggers:**
- `IN` → purchase invoice posted
- `OUT` → sales invoice posted
- `ADJUSTMENT` → manual correction
- `RETURN_IN` → sales return (goods back in)
- `RETURN_OUT` → purchase return (goods sent back)
- `REVERSAL_OUT` → invoice cancelled (undoes original OUT)

---

## 5. ReturnModel
**File:** `lib/models/return_model.dart`
**Firestore:** `users/{uid}/returns/{returnId}`

```
id: String
returnNumber: String             # 'SR-{timestamp}' for sales, 'PR-{timestamp}' for purchase
invoiceId: String                # FK → invoices/{invoiceId}
invoiceNumber: String            # denormalized
customerName: String             # denormalized
customerId: String?
customerPhone: String?
invoiceDate: DateTime
returnDate: DateTime
returnType: String               # 'sales' | 'purchase'
items: List<ReturnItem>          # inline array
returnReason: String
notes: String?
totalReturnValue: double
refundAmount: double
isApplied: bool                  # true when credit applied to a new invoice
createdAt: DateTime
updatedAt: DateTime
```

**ReturnItem** (inline):
```
name: String
quantity: int
price: double
totalValue: double               # quantity * price
```

---

## 6. SubscriptionModel
**File:** `lib/models/subscription_model.dart`
**Firestore:** `users/{uid}/subscription/current`

```
tier: SubscriptionTier           # free | premium
status: SubscriptionStatus       # active | cancelled | expired | trial
startDate: DateTime
endDate: DateTime?
trialEndDate: DateTime?          # 7-day trial via createTrial()
paymentProvider: String          # 'razorpay'
subscriptionId: String?          # Razorpay subscription ID
features: SubscriptionFeatures
usageLimits: UsageLimits
createdAt: DateTime
updatedAt: DateTime
```

**SubscriptionFeatures:**
```
ocrScansRemaining: int           # -1 = unlimited (premium)
aiInsightsGenerated: int         # usage counter
riskPredictionsUsed: int         # usage counter
inventoryForecastsGenerated: int # usage counter
```

**UsageLimits:**
```
ocrScansPerMonth: int            # 5 (free) | -1 (premium)
aiInsightsPerMonth: int          # 0 (free) | -1 (premium)
riskPredictionsEnabled: bool     # false (free) | true (premium)
inventoryForecastEnabled: bool   # false (free) | true (premium)
```

**Pricing:** ₹299/month | ₹2999/year (via Razorpay)

---

## 7. AI Models
**Files:** `lib/models/ai_insight_model.dart`, `payment_risk_model.dart`, `inventory_forecast_model.dart`

**AIInsight:**
```
id, type (InsightType), category (InsightCategory), title, description,
actionText?, value?, changePercent?, isPositive, priority (InsightPriority),
generatedAt, metadata?

InsightType:    trend | alert | opportunity | milestone | recommendation | general
InsightCategory: revenue | products | customers | inventory | payments | growth
InsightPriority: high | medium | low
```

**PaymentRiskModel:**
```
customerId, riskScore (0-100), riskLevel (critical|high|medium|low),
totalOutstanding, overdueInvoices, maxDaysOverdue, paymentReliability (0-1),
riskFactors: [{name, impact, description}]
```

**InventoryForecastModel:**
```
itemId, dailyDemand, weeklyDemand, daysUntilStockout,
reorderPoint, recommendedOrderQty, confidenceLevel (0-1),
seasonalNotes?, alertType (stockout|overstock|slow_moving|seasonal_spike)
```
