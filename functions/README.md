# InvoiceFlow Firebase Functions

Cloud Functions for AI-powered features in InvoiceFlow.

## Functions

1. **processOCR** - Extract invoice data from receipt images using Gemini Vision API
2. **resetMonthlyUsage** - Scheduled function to reset usage limits monthly
3. **checkExpiredSubscriptions** - Scheduled function to expire subscriptions daily

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Set Gemini API Key

Get your free Gemini API key from: https://makersuite.google.com/app/apikey

```bash
firebase functions:config:set gemini.apikey="YOUR_GEMINI_API_KEY"
```

### 3. Build TypeScript

```bash
npm run build
```

### 4. Test Locally (Optional)

```bash
npm run serve
```

This starts the Firebase emulator. Update the URL in `lib/services/ai/ocr_service.dart`:
```dart
static const String _functionUrl = 'http://127.0.0.1:5001/invoiceflow-deafa/us-central1/processOCR';
```

### 5. Deploy to Firebase

```bash
firebase deploy --only functions
```

Or deploy specific function:
```bash
firebase deploy --only functions:processOCR
```

### 6. Update App

After deployment, update the function URL in `lib/services/ai/ocr_service.dart`:
```dart
static const String _functionUrl = 'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/processOCR';
```

Replace `YOUR_PROJECT_ID` with your Firebase project ID.

## Cost Estimates

### Gemini API (Free Tier)
- **Free**: 1,500 requests/day (Gemini 1.5 Flash)
- **Paid**: $0.075 per 1M tokens (very cheap)

### Firebase Functions (Free Tier)
- **Invocations**: 125K/month free
- **Compute time**: 40K GB-seconds/month free
- **Network egress**: 5GB/month free

**Estimated costs for 1000 OCR scans/month**: ~$0.50-1.00

## Monitoring

View function logs:
```bash
firebase functions:log
```

Or in Firebase Console: Functions → Logs

## Troubleshooting

### Error: "GEMINI_API_KEY not set"
Run: `firebase functions:config:set gemini.apikey="YOUR_KEY"`

### Error: "Failed to download image"
Check Firebase Storage security rules allow authenticated read access.

### Error: "OCR processing timed out"
Increase timeout in `ocr_service.dart` or optimize image size.

## Security Rules

Ensure Firestore security rules allow:
- Users can read/write their own `ocr_scans` collection
- Users can read/write their own `subscription` data
- Only authenticated users can call `processOCR` function

## Development

Build on changes:
```bash
npm run build
```

Watch mode:
```bash
tsc --watch
```
