# InvoiceFlow Deployment Setup Guide

## Prerequisites Checklist

- [ ] Firebase CLI installed (`firebase --version`)
- [ ] Firebase project initialized (`firebase projects:list`)
- [ ] Node.js installed (v18+)
- [ ] Flutter installed

---

## Step 1: Get API Keys

### A. Gemini API Key (Required for OCR)

1. Go to: https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key (starts with `AIza...`)

### B. Razorpay Keys (Required for Payments)

1. Go to: https://dashboard.razorpay.com/
2. Sign up for Razorpay account
3. Go to Settings → API Keys
4. Generate **Test Mode** keys first:
   - Key ID: `rzp_test_xxxxx`
   - Key Secret: `xxxxx` (keep secure!)

---

## Step 2: Configure Firebase Functions

### Set Gemini API Key

```bash
cd functions
firebase functions:config:set gemini.apikey="YOUR_GEMINI_API_KEY"
```

Verify it's set:
```bash
firebase functions:config:get
```

Should show:
```json
{
  "gemini": {
    "apikey": "AIza..."
  }
}
```

---

## Step 3: Update App Configuration

### A. Update OCR Service with Function URL

**File:** `lib/services/ai/ocr_service.dart`

Get your Firebase project ID:
```bash
firebase projects:list
```

Update line 23-24:
```dart
// OLD:
static const String _functionUrl =
    'https://us-central1-invoiceflow-deafa.cloudfunctions.net/processOCR';

// NEW (replace YOUR_PROJECT_ID):
static const String _functionUrl =
    'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/processOCR';
```

### B. Update Payment Service with Razorpay Keys

**File:** `lib/services/payment_service.dart`

Update lines 28-30:
```dart
// OLD:
static const String _razorpayKeyId = 'rzp_test_1234567890';
static const String _razorpayKeySecret = 'YOUR_SECRET_KEY';

// NEW (use YOUR test keys):
static const String _razorpayKeyId = 'rzp_test_YOUR_KEY_ID';
static const String _razorpayKeySecret = 'YOUR_SECRET_KEY';
```

**IMPORTANT:** For production, use Live keys (`rzp_live_xxxxx`)

---

## Step 4: Update Firestore Security Rules

**File:** `firestore.rules`

Ensure these rules are present:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

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

      match /subscription_events/{document=**} {
        allow read: if request.auth.uid == userId;
        allow create: if request.auth.uid == userId;
      }
    }
  }
}
```

---

## Step 5: Deploy Firebase Functions

```bash
cd functions
firebase deploy --only functions
```

This will deploy:
- `processOCR` - Main OCR function
- `resetMonthlyUsage` - Scheduled (monthly)
- `checkExpiredSubscriptions` - Scheduled (daily)

**Expected output:**
```
✔ functions[processOCR(us-central1)] Successful create operation.
✔ functions[resetMonthlyUsage(us-central1)] Successful create operation.
✔ functions[checkExpiredSubscriptions(us-central1)] Successful create operation.

Function URL (processOCR):
https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/processOCR
```

**Copy this URL** and update `ocr_service.dart` (Step 3A)!

---

## Step 6: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

**Expected output:**
```
✔ firestore: rules file firestore.rules compiled successfully
✔ firestore: released rules firestore.rules to cloud.firestore
```

---

## Step 7: Test End-to-End

### A. Test on Android Device/Emulator

```bash
# Run in debug mode
flutter run

# Or build and install APK
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### B. Testing Checklist

- [ ] **Sign Up**: Create new account → gets free tier
- [ ] **View Subscription**: Navigate to `/subscription` → see "Free Plan" with 5 OCR scans
- [ ] **Test OCR**:
  - [ ] Navigate to `/ocr-scan`
  - [ ] Take photo of receipt
  - [ ] Verify items extracted
  - [ ] Check fuzzy matching confidence scores
  - [ ] Create invoice from OCR results
- [ ] **Test Usage Limits**:
  - [ ] Use 5 OCR scans
  - [ ] Try 6th scan → should show upgrade prompt
- [ ] **Test Coming Soon**:
  - [ ] Try to access "AI Insights" → see "Coming Soon" dialog
  - [ ] Try "Payment Risk" → see "Coming Soon" dialog
  - [ ] Try "Inventory Forecast" → see "Coming Soon" dialog
- [ ] **Test Free Trial**:
  - [ ] Click "Start Free Trial" on subscription screen
  - [ ] Verify premium features unlock for 7 days
- [ ] **Test Payment** (with Razorpay test keys):
  - [ ] Click "Upgrade to Premium"
  - [ ] Select Monthly (₹299) or Yearly (₹2999)
  - [ ] Complete test payment
  - [ ] Verify subscription upgraded
  - [ ] Try OCR again → should be unlimited
- [ ] **Test Subscription Management**:
  - [ ] View subscription details
  - [ ] Test cancellation flow

### C. Test Payment with Razorpay Test Cards

**Test Card Details:**
- Card Number: `4111 1111 1111 1111`
- CVV: Any 3 digits
- Expiry: Any future date
- Name: Any name

For UPI: Use `success@razorpay`

---

## Step 8: Build Release APK

### For Testing (Debug)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### For Production (Release)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### For Play Store (App Bundle)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 9: Monitor & Verify

### A. Check Firebase Console

**Functions:**
- https://console.firebase.google.com/project/YOUR_PROJECT/functions
- Verify all 3 functions deployed
- Check function logs

**Firestore:**
- https://console.firebase.google.com/project/YOUR_PROJECT/firestore
- Verify `users` collection exists
- Check subscription data after test signup

**Storage:**
- https://console.firebase.google.com/project/YOUR_PROJECT/storage
- OCR images should appear in `ocr_scans/` folder

### B. Monitor Costs

**Gemini API:**
- https://makersuite.google.com/app/apikey
- Check usage/quota

**Firebase:**
- https://console.firebase.google.com/project/YOUR_PROJECT/usage
- Monitor function invocations
- Check storage usage

---

## Troubleshooting

### Issue: "Function not found"
**Solution:** Ensure you deployed functions and updated the URL in `ocr_service.dart`

### Issue: "OCR processing failed"
**Solution:** Check Gemini API key is set correctly:
```bash
firebase functions:config:get
```

### Issue: "Payment failing"
**Solution:**
- Verify Razorpay keys in `payment_service.dart`
- Check Razorpay dashboard for payment logs
- Ensure using test mode keys for testing

### Issue: "Subscription not syncing"
**Solution:**
- Check Firestore security rules deployed
- Verify user is authenticated
- Check browser console for errors

### Issue: "Coming Soon dialog not showing"
**Solution:**
- Verify `coming_soon_dialog.dart` exists
- Check `subscription_provider.dart` imports it
- Try hot restart

---

## Production Checklist

Before going live:

- [ ] Replace Razorpay **test keys** with **live keys**
- [ ] Update `_razorpayKeyId` with `rzp_live_xxxxx`
- [ ] Test payment with real card (small amount)
- [ ] Set Firebase to Blaze plan (pay-as-you-go) if needed
- [ ] Configure custom domain for functions (optional)
- [ ] Set up billing alerts in Firebase Console
- [ ] Enable Firebase App Check for security
- [ ] Review and tighten Firestore security rules
- [ ] Test trial expiration (wait 7 days or adjust for testing)
- [ ] Set up error monitoring (Firebase Crashlytics)
- [ ] Create privacy policy (required for Play Store)
- [ ] Create terms of service
- [ ] Submit to Google Play Store

---

## Support

- **Firebase Issues**: Check Firebase Console logs
- **Payment Issues**: Check Razorpay Dashboard
- **OCR Issues**: Check function logs: `firebase functions:log`

---

## Next Steps After Deployment

1. **Monitor first 100 users** for issues
2. **Track conversion rate** (free → premium)
3. **Collect feedback** on OCR accuracy
4. **Optimize Gemini prompts** based on real data
5. **Implement remaining features** (Insights, Risk, Forecast)
6. **A/B test pricing** if needed
7. **Add more fuzzy matching synonyms** for your products

---

**Your app is ready for production! 🚀**

For detailed technical documentation, see `AI_FEATURES_README.md`
