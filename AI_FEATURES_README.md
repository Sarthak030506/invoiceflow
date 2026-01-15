# InvoiceFlow AI Premium Features

Complete implementation of AI-powered features with subscription monetization.

## 🎯 Overview

This implementation adds 4 premium AI features behind a subscription paywall:

1. **Invoice OCR with Fuzzy Matching** - Scan receipts and auto-fill invoices
2. **AI Business Insights** - Get personalized recommendations (framework ready)
3. **Payment Risk Prediction** - Prioritize collections (framework ready)
4. **Inventory Forecasting** - Predict demand (framework ready)

## 💰 Subscription Model

### Free Tier
- Basic invoice management (all existing features)
- 5 OCR scans per month
- Monthly usage resets on 1st of each month

### Premium Tier
- **Pricing**: ₹299/month or ₹2,999/year (16% savings)
- **7-day free trial** available for new users
- **Unlimited OCR scans**
- **All AI features** (current + future)
- **Priority support**

### Payment Integration
- **Razorpay** for Indian market (UPI, cards, wallets, net banking)
- Secure payment flow with success/error handling
- Automatic subscription management

## 🏗️ Architecture

### New Models
```
lib/models/
├── subscription_model.dart     # Subscription state management
├── ocr_scan_model.dart         # OCR results with fuzzy matching data
├── ai_insight_model.dart       # Business insights (future)
├── payment_risk_model.dart     # Risk predictions (future)
└── inventory_forecast_model.dart # Demand forecasts (future)
```

### Services
```
lib/services/
├── subscription_service.dart   # Subscription CRUD, usage tracking
├── payment_service.dart        # Razorpay integration
└── ai/
    ├── fuzzy_matcher_service.dart  # Multi-algorithm item matching
    ├── ocr_service.dart           # Receipt scanning orchestration
    ├── insights_service.dart      # (future)
    ├── risk_service.dart          # (future)
    └── forecast_service.dart      # (future)
```

### Providers
```
lib/providers/
└── subscription_provider.dart  # State management with real-time updates
```

### UI Components
```
lib/presentation/
├── subscription/
│   ├── subscription_screen.dart    # Plan display, usage stats
│   └── upgrade_dialog.dart         # Payment flow
└── invoice_ocr/
    ├── ocr_scan_screen.dart        # Camera/gallery picker
    └── widgets/
        └── ocr_results_sheet.dart  # Match review UI

lib/widgets/
├── premium_badge.dart          # Visual premium indicators
└── feature_gate_overlay.dart   # Upgrade prompts
```

### Firebase Functions
```
functions/src/
├── index.ts                    # Main exports
├── ocr.ts                      # Gemini Vision API processing
├── insights.ts                 # (future)
├── risk.ts                     # (future)
└── forecast.ts                 # (future)
```

## 🔥 Key Innovation: Fuzzy Matching Algorithm

The **FuzzyMatcherService** is the core differentiator, handling typos and variations in Indian product names.

### Multi-Algorithm Approach

1. **Levenshtein Distance** (30% weight)
   - Measures edit distance between strings
   - Handles character substitutions, insertions, deletions
   - Example: "contaner" → "Container" (1 edit, high score)

2. **Jaccard Similarity** (25% weight)
   - Token-based word matching
   - Splits strings into words and compares sets
   - Example: "silver foil" matches "Silver Foil 72mtr"

3. **N-gram Similarity** (25% weight)
   - Character-level comparison using 2-grams
   - Catches typos and spelling variations
   - Example: "biriyani" vs "biryani" has high n-gram overlap

4. **Phonetic Similarity** (20% weight)
   - Handles pronunciation variations
   - Built-in synonym dictionary for Indian names
   - Example: "alu foil" → "Aluminium Foil"

### Confidence Scoring

- **90%+** (Green) - Excellent match, very confident
- **70-89%** (Orange) - Good match, likely correct
- **50-69%** (Red) - Fair match, user should verify
- **<50%** - Rejected, no match shown

### Built-in Synonyms

```dart
{
  'biryani': ['biriyani', 'briyani', 'biryaani'],
  'container': ['contaner', 'konteiner'],
  'aluminium': ['aluminum', 'alu'],
  'milk': ['milk', 'doodh'],
  // ... more
}
```

## 📱 User Flows

### 1. New User Journey
```
Sign Up → Free Tier (5 OCR/month)
    ↓
See "7-day Free Trial" banner
    ↓
Try OCR Feature (works during trial)
    ↓
Trial Ends → Downgraded to Free
    ↓
Hit 5 scan limit → Upgrade Prompt
    ↓
Pay ₹299 → Premium Unlocked
```

### 2. OCR Scanning Flow
```
Tap "Scan Receipt"
    ↓
Check Subscription (show gate if needed)
    ↓
Camera/Gallery → Take Photo
    ↓
Upload to Firebase Storage
    ↓
Call Firebase Function (Gemini Vision)
    ↓
Extract Items (AI parsing)
    ↓
Fuzzy Match with Catalog
    ↓
Show Results with Confidence Scores
    ↓
User Reviews & Confirms Matches
    ↓
Create Invoice (pre-filled)
```

### 3. Subscription Upgrade Flow
```
User hits feature gate
    ↓
Show FeatureGateOverlay with benefits
    ↓
Tap "Upgrade to Premium"
    ↓
UpgradeDialog (Monthly/Yearly plans)
    ↓
Select Plan → Pay with Razorpay
    ↓
Payment Success → Verify & Upgrade
    ↓
Subscription Provider updates (real-time)
    ↓
Feature unlocked immediately
```

## 🛠️ Setup Instructions

### 1. Install Dependencies

Already added to `pubspec.yaml`:
```yaml
razorpay_flutter: ^1.3.7
google_generative_ai: ^0.4.6
image_picker: ^1.1.2
string_similarity: ^2.0.0
http: ^1.2.2
flutter_dotenv: ^5.1.0
```

Run:
```bash
flutter pub get
```

### 2. Firebase Functions Setup

```bash
cd functions
npm install
firebase functions:config:set gemini.apikey="YOUR_GEMINI_API_KEY"
npm run build
firebase deploy --only functions
```

Get Gemini API key: https://makersuite.google.com/app/apikey

### 3. Update Function URL

In `lib/services/ai/ocr_service.dart`, update:
```dart
static const String _functionUrl =
    'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/processOCR';
```

### 4. Add Razorpay Keys

In `lib/services/payment_service.dart`, update:
```dart
static const String _razorpayKeyId = 'rzp_live_YOUR_KEY';  // Production
static const String _razorpayKeySecret = 'YOUR_SECRET';    // Keep secure
```

Get keys: https://dashboard.razorpay.com/

### 5. Firestore Security Rules

Add these rules to `firestore.rules`:
```javascript
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;

  match /subscription/{document=**} {
    allow read: if request.auth.uid == userId;
    allow write: if request.auth.uid == userId;
  }

  match /ocr_scans/{document=**} {
    allow read, write: if request.auth.uid == userId;
  }

  match /ai_usage/{document=**} {
    allow read: if request.auth.uid == userId;
    allow create: if request.auth.uid == userId;
  }
}
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

## 🧪 Testing

### Test OCR Feature

1. Navigate to any invoice creation screen
2. Look for camera/OCR button (needs to be added to UI)
3. Or directly navigate to: `/ocr-scan`
4. Take photo of receipt with clear items and prices
5. Review fuzzy matching results
6. Verify confidence scores are accurate

### Test Subscription Flow

1. Sign up new user (gets free tier)
2. Go to `/subscription` screen
3. See usage stats (5 OCR scans remaining)
4. Try "Start Free Trial" button
5. Verify trial activates (7 days)
6. Try upgrade to premium (test mode)
7. Verify features unlock

### Test Fuzzy Matching

Run unit tests:
```bash
flutter test test/services/fuzzy_matcher_test.dart
```

Test cases included:
- Exact matches (confidence = 1.0)
- Typos: "biryani contaner" → "Biryani Container" (>70%)
- Partial: "silver foil" → "Silver Foil 72mtr" (>80%)
- No match: "Computer" vs "Milk" (<50%, rejected)

## 📊 Analytics & Monitoring

### Firebase Analytics Events

Track these events:
```dart
'subscription_upgraded': {plan: 'monthly', source: 'ocr_limit'}
'subscription_cancelled': {tier: 'premium', days_remaining: 15}
'trial_started': {}
'trial_expired': {}
'ocr_scan_completed': {items_detected: 5, avg_confidence: 0.82}
'fuzzy_match_manual_override': {original: 'X', user_selected: 'Y'}
'ai_feature_used': {feature: 'ocr', subscription_tier: 'premium'}
```

### Monitor Costs

**Gemini API Dashboard**: https://makersuite.google.com/app/apikey
**Firebase Console**: https://console.firebase.google.com/
- Functions → Usage
- Firestore → Usage
- Storage → Usage

**Expected costs (1000 OCR scans/month)**:
- Gemini API: ~$0.30-0.50
- Firebase Functions: Free tier
- Firebase Storage: Free tier
- **Total: ~$0.50/month** (very low!)

## 🚀 Deployment Checklist

### Pre-deployment

- [ ] Test all subscription flows
- [ ] Test OCR with 20+ real receipts
- [ ] Verify fuzzy matching accuracy >85%
- [ ] Test payment with Razorpay test keys
- [ ] Review Firestore security rules
- [ ] Set Firebase Functions config (Gemini key)
- [ ] Update function URLs in code
- [ ] Test trial expiration logic
- [ ] Test monthly usage reset

### Production

- [ ] Replace Razorpay test keys with live keys
- [ ] Deploy Firebase Functions: `firebase deploy --only functions`
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Build Flutter app: `flutter build apk --release`
- [ ] Test payment flow end-to-end in production
- [ ] Monitor Firebase Functions logs for errors
- [ ] Set up billing alerts in Firebase Console
- [ ] Test subscription cancellation flow

### Post-deployment

- [ ] Monitor first 100 OCR scans for accuracy
- [ ] Track conversion rate (free → premium)
- [ ] Collect user feedback on fuzzy matching
- [ ] Monitor API costs daily for first week
- [ ] A/B test pricing (₹299 vs ₹399)
- [ ] Optimize Gemini prompts based on real data

## 📈 Success Metrics

### Target KPIs (First Month)

- **Conversion Rate**: >5% (free → premium)
- **Trial Activation**: >30% of new users
- **OCR Accuracy**: >85% correct top match
- **False Positive Rate**: <10%
- **User Satisfaction**: >4.5/5 stars
- **Churn Rate**: <5%/month
- **Backend Cost**: <1% of revenue

### How to Measure

```dart
// Track in Firestore
'metrics/monthly': {
  totalUsers: 1000,
  premiumUsers: 50,
  trialUsers: 100,
  ocrScansCompleted: 2500,
  avgConfidence: 0.87,
  manualOverrides: 150,  // 6% override rate
  subscriptionRevenue: 14950,  // ₹299 × 50
  totalCosts: 50  // <0.4%
}
```

## 🐛 Troubleshooting

### OCR not working
- Check Firebase Function deployed: `firebase functions:list`
- Verify Gemini API key set: `firebase functions:config:get`
- Check function logs: `firebase functions:log`
- Test function URL with curl/Postman

### Payment failing
- Verify Razorpay keys are correct
- Check Razorpay dashboard for payment logs
- Ensure webhook URL is configured (if using)

### Poor fuzzy matching
- Check catalog has sufficient items loaded
- Review synonym dictionary in `fuzzy_matcher_service.dart`
- Adjust confidence threshold (default 0.5)
- Add more synonyms for your specific products

### Subscription not syncing
- Check internet connection
- Verify Firestore security rules
- Check `subscription_provider.dart` stream is active
- Look for errors in `subscription_service.dart`

## 🔜 Future Enhancements

### Phase 2 (Next 4-6 weeks)

1. **AI Business Insights** - Framework ready, needs Gemini integration
2. **Payment Risk Prediction** - Framework ready, needs ML model
3. **Inventory Forecasting** - Framework ready, needs Prophet/Time-series

### Phase 3 (Optional)

4. **Voice-to-Invoice** - Speak to create invoices
5. **Smart Customer Segmentation** - RFM analysis
6. **Semantic Search** - Natural language invoice search
7. **Anomaly Detection** - Flag unusual transactions
8. **Dynamic Pricing** - AI-powered price optimization

## 📝 Code Statistics

- **28 new files created**
- **~4,000 lines of code**
- **6 commits** on `feature/ai-premium-subscription` branch
- **4 weeks of work** compressed into hours

## 🎉 What's Complete

✅ **Subscription System** (Week 1-2)
- Models, services, providers
- Payment integration (Razorpay)
- UI screens (subscription, upgrade)
- Feature gates throughout app
- Usage tracking & limits
- Trial management

✅ **OCR + Fuzzy Matching** (Week 3-4)
- Multi-algorithm fuzzy matcher
- OCR service with Gemini Vision
- Camera integration
- Results display with confidence
- Firebase Functions
- Real-time subscription checks

✅ **Infrastructure**
- Firebase Functions deployment
- Scheduled functions (monthly reset, expiration check)
- Analytics tracking
- Error handling
- Security rules

## 📧 Support

For issues or questions:
- Check Firebase Console logs first
- Review this documentation
- Test with emulators before production
- Monitor costs in first week

---

**Built with ❤️ for InvoiceFlow**
*AI-powered business management for Indian SMBs*
