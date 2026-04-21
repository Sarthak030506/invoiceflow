import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { defineSecret } from 'firebase-functions/params';
import { GoogleGenerativeAI } from '@google/generative-ai';
import axios from 'axios';
import * as crypto from 'crypto';

// Initialize Firebase Admin
admin.initializeApp();

// Secret declarations — resolved at invocation time, not module load.
// Create secrets once with:
//   firebase functions:secrets:set GEMINI_API_KEY
//   firebase functions:secrets:set RAZORPAY_KEY_SECRET
// Each function that uses a secret must declare it in runWith({ secrets: [...] }).
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');

/**
 * Process OCR - Extract invoice data from receipt image using Gemini Vision API
 */
export const processOCR = functions
  .runWith({ secrets: ['GEMINI_API_KEY'] })
  .https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use OCR'
    );
  }
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token is missing or invalid.'
    );
  }

  const { imageUrl, scanId } = data;

  if (!imageUrl) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'imageUrl is required'
    );
  }

  try {
    console.log(`Processing OCR for scan ${scanId}, user ${context.auth.uid}`);

    // Download image from Firebase Storage URL
    const imageBuffer = await downloadImage(imageUrl);

    // Call Gemini Vision API — genAI initialised here (not at module level)
    // because GEMINI_API_KEY secret is only available at invocation time.
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const prompt = `
Analyze this invoice/receipt image (Indian business format) and extract the following information:
- List of items/products with quantities and prices
- Total amount (in ₹)
- Vendor/store name (if visible)
- Date (in DD/MM/YYYY format if visible)

IMPORTANT:
- Handle variations in spelling and format
- Support Hindi text and mixed language receipts
- Parse prices in various formats (₹, Rs., INR)
- Extract quantities even if units vary (kg, pcs, liters, etc.)

Return ONLY a valid JSON object with this exact structure:
{
  "items": [
    {"text": "item name", "quantity": 2, "price": 150.00}
  ],
  "totalAmount": 300.00,
  "vendor": "Store Name",
  "date": "15/01/2025"
}

If any field is not found, use null. Ensure all numbers are numeric, not strings.
`;

    const result = await model.generateContent([
      prompt,
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageBuffer.toString('base64'),
        },
      },
    ]);

    const response = result.response;
    const text = response.text();

    console.log('Gemini raw response:', text);

    // Parse JSON from response
    let extractedData;
    try {
      // Extract JSON from markdown code blocks if present
      const jsonMatch = text.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
      const jsonText = jsonMatch ? jsonMatch[1] : text;
      extractedData = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Failed to parse Gemini response as JSON:', text);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to parse OCR results. Please try again with a clearer image.'
      );
    }

    // Validate and normalize data
    const normalizedData = {
      items: Array.isArray(extractedData.items)
        ? extractedData.items.map((item: any) => ({
            text: String(item.text || ''),
            quantity: item.quantity ? Number(item.quantity) : null,
            price: item.price ? Number(item.price) : null,
          }))
        : [],
      totalAmount: extractedData.totalAmount
        ? Number(extractedData.totalAmount)
        : null,
      vendor: extractedData.vendor ? String(extractedData.vendor) : null,
      date: extractedData.date ? String(extractedData.date) : null,
    };

    // Track usage in Firestore
    await admin
      .firestore()
      .collection('users')
      .doc(context.auth.uid)
      .collection('ai_usage')
      .add({
        featureType: 'ocr',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        tokensUsed: response.usageMetadata?.totalTokenCount || 0,
        scanId: scanId,
        metadata: {
          itemsDetected: normalizedData.items.length,
          totalAmount: normalizedData.totalAmount,
        },
      });

    // --- Decrement ocrScansRemaining (server-authoritative, replaces client-side decrementOCRScans) ---
    // RACE CONDITION NOTE: Between the client's canAccessFeature() check and this decrement, a second
    // device on the same account could consume the last remaining scan. FieldValue.increment(-1) is
    // atomic but does not enforce a floor of 0. We use a Firestore transaction here: read the current
    // count, validate it is still > 0, then decrement atomically. If the count has dropped to 0 by the
    // time we enter the transaction the function throws resource-exhausted, leaving the scan fee to the
    // caller (OCR Gemini call already ran). A pre-function quota gate in a separate onCall is the proper
    // long-term fix, but this transaction closes the duplicate-decrement window.
    const subRef = admin
      .firestore()
      .collection('users')
      .doc(context.auth.uid)
      .collection('subscription')
      .doc('current');

    await admin.firestore().runTransaction(async (txn) => {
      const subSnap = await txn.get(subRef);
      if (!subSnap.exists) {
        // No subscription doc yet — nothing to decrement (free-tier initialisation
        // may not have run; don't block OCR result from returning).
        return;
      }

      const remaining = subSnap.data()?.features?.ocrScansRemaining ?? 0;

      if (remaining === -1) {
        // -1 means unlimited (premium tier) — skip decrement entirely.
        return;
      }

      if (remaining === 0) {
        // Guard: should have been caught before calling OCR, but a race brought us here.
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'OCR scan limit reached'
        );
      }

      // remaining > 0: decrement atomically inside the transaction.
      txn.update(subRef, {
        'features.ocrScansRemaining': admin.firestore.FieldValue.increment(-1),
        'features.updatedAt': admin.firestore.Timestamp.now(),
      });
    });

    console.log(
      `OCR completed successfully: ${normalizedData.items.length} items detected`
    );

    return {
      success: true,
      data: normalizedData,
    };
  } catch (error: any) {
    console.error('OCR processing error:', error);

    // Re-throw HttpsErrors as-is (resource-exhausted, etc.)
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    // Return user-friendly error
    throw new functions.https.HttpsError(
      'internal',
      `OCR processing failed: ${error.message || 'Unknown error'}`
    );
  }
});

/**
 * Download image from URL (Firebase Storage)
 */
async function downloadImage(url: string): Promise<Buffer> {
  try {
    const response = await axios.get(url, {
      responseType: 'arraybuffer',
      timeout: 30000, // 30 second timeout
    });

    return Buffer.from(response.data);
  } catch (error: any) {
    console.error('Failed to download image:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to download image: ${error.message}`
    );
  }
}

/**
 * Reset monthly usage limits (scheduled function - runs on 1st of every month)
 */
export const resetMonthlyUsage = functions.pubsub
  .schedule('0 0 1 * *') // Midnight on 1st of every month (UTC)
  .timeZone('Asia/Kolkata') // Indian timezone
  .onRun(async (context) => {
    console.log('Starting monthly usage reset...');

    try {
      const usersSnapshot = await admin.firestore().collection('users').get();

      const batch = admin.firestore().batch();
      let resetCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const subRef = userDoc.ref.collection('subscription').doc('current');
        const subDoc = await subRef.get();

        if (!subDoc.exists) continue;

        const subData = subDoc.data();
        const tier = subData?.tier || 'free';

        // Reset based on tier
        if (tier === 'free') {
          batch.update(subRef, {
            'features.ocrScansRemaining': 5, // Reset to 5 for free tier
            'features.aiInsightsGenerated': 0,
            'features.riskPredictionsUsed': 0,
            'features.inventoryForecastsGenerated': 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          resetCount++;
        } else if (tier === 'premium') {
          // Reset counters but keep unlimited (-1)
          batch.update(subRef, {
            'features.aiInsightsGenerated': 0,
            'features.riskPredictionsUsed': 0,
            'features.inventoryForecastsGenerated': 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          resetCount++;
        }
      }

      await batch.commit();

      console.log(
        `Monthly usage reset completed. Updated ${resetCount} users.`
      );

      return null;
    } catch (error) {
      console.error('Monthly usage reset failed:', error);
      throw error;
    }
  });

/**
 * Check and expire subscriptions (scheduled function - runs daily)
 */
export const checkExpiredSubscriptions = functions.pubsub
  .schedule('0 2 * * *') // 2 AM daily (UTC)
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    console.log('Checking for expired subscriptions...');

    try {
      const now = admin.firestore.Timestamp.now();
      const usersSnapshot = await admin.firestore().collection('users').get();

      const batch = admin.firestore().batch();
      let expiredCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const subRef = userDoc.ref.collection('subscription').doc('current');
        const subDoc = await subRef.get();

        if (!subDoc.exists) continue;

        const subData = subDoc.data();
        const status = subData?.status;
        const endDate = subData?.endDate;

        // Check if subscription has expired
        if (
          (status === 'active' || status === 'trial') &&
          endDate &&
          endDate.toMillis() < now.toMillis()
        ) {
          // Expire subscription - downgrade to free
          batch.update(subRef, {
            tier: 'free',
            status: 'expired',
            'features.ocrScansRemaining': 5,
            'features.aiInsightsGenerated': 0,
            'features.riskPredictionsUsed': 0,
            'features.inventoryForecastsGenerated': 0,
            'usageLimits.ocrScansPerMonth': 5,
            'usageLimits.aiInsightsPerMonth': 0,
            'usageLimits.riskPredictionsEnabled': false,
            'usageLimits.inventoryForecastEnabled': false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Log expiration event
          batch.create(userDoc.ref.collection('subscription_events').doc(), {
            event: 'subscription_expired',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            parameters: { previousStatus: status },
          });

          expiredCount++;
        }
      }

      await batch.commit();

      console.log(`Expired ${expiredCount} subscriptions.`);

      return null;
    } catch (error) {
      console.error('Subscription expiration check failed:', error);
      throw error;
    }
  });

/**
 * Generate AI Business Insights using Gemini
 */
export const generateBusinessInsights = functions
  .runWith({ secrets: ['GEMINI_API_KEY'] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  if (!context.app) {
    throw new functions.https.HttpsError('failed-precondition', 'App Check token is missing or invalid.');
  }

  const { invoiceData, customerData, inventoryData } = data;

  try {
    console.log(`Generating AI insights for user ${context.auth.uid}`);

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const prompt = `
You are a business analyst AI for an Indian small business. Analyze the following business data and provide actionable insights.

BUSINESS DATA:
- Recent Invoices (last 30 days): ${JSON.stringify(invoiceData)}
- Customer Summary: ${JSON.stringify(customerData)}
- Inventory Status: ${JSON.stringify(inventoryData)}

Provide insights in the following JSON format:
{
  "insights": [
    {
      "id": "unique_id",
      "type": "trend|alert|opportunity|recommendation",
      "category": "revenue|products|customers|inventory|payments",
      "title": "Short title (max 50 chars)",
      "description": "Detailed insight with specific numbers and actionable advice (2-3 sentences)",
      "priority": "high|medium|low",
      "value": optional_numeric_value,
      "changePercent": optional_percentage_change,
      "isPositive": true_or_false
    }
  ],
  "summary": "One paragraph executive summary of business health"
}

Generate 5-8 meaningful insights. Focus on:
1. Revenue trends and growth opportunities
2. Top performing products and slow movers
3. Customer payment patterns and risks
4. Inventory health and reorder needs
5. Actionable recommendations for improvement

Use Indian Rupee (₹) for currency. Be specific with numbers.
`;

    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();

    console.log('Gemini insights response:', text);

    // Parse JSON from response
    let insightsData;
    try {
      const jsonMatch = text.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
      const jsonText = jsonMatch ? jsonMatch[1] : text;
      insightsData = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Failed to parse insights JSON:', text);
      throw new functions.https.HttpsError('internal', 'Failed to parse AI insights');
    }

    // Track usage
    await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .collection('ai_usage')
      .add({
        featureType: 'business_insights',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        tokensUsed: response.usageMetadata?.totalTokenCount || 0,
        insightsCount: insightsData.insights?.length || 0,
      });

    return { success: true, data: insightsData };
  } catch (error: any) {
    console.error('Business insights error:', error);
    throw new functions.https.HttpsError('internal', `AI insights failed: ${error.message}`);
  }
});

/**
 * Predict Payment Risk using Gemini AI
 */
export const predictPaymentRisk = functions
  .runWith({ secrets: ['GEMINI_API_KEY'] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  if (!context.app) {
    throw new functions.https.HttpsError('failed-precondition', 'App Check token is missing or invalid.');
  }

  const { customers } = data;

  try {
    console.log(`Predicting payment risk for user ${context.auth.uid}`);

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const prompt = `
You are a credit risk analyst AI for an Indian small business. Analyze customer payment data and predict payment risk.

CUSTOMER DATA:
${JSON.stringify(customers)}

For each customer, analyze:
- Outstanding balance and total spent
- Payment history patterns
- Invoice count and recency
- Credit utilization

Return JSON in this exact format:
{
  "riskAssessments": [
    {
      "customerId": "customer_id",
      "customerName": "name",
      "riskScore": 0-100 (higher = more risky),
      "riskLevel": "critical|high|medium|low",
      "outstandingAmount": amount_in_rupees,
      "factors": ["factor1", "factor2"],
      "recommendation": "Specific action to take",
      "predictedPaymentDays": estimated_days_to_payment
    }
  ],
  "summary": {
    "totalAtRisk": total_rupees_at_risk,
    "criticalCount": number,
    "highRiskCount": number,
    "recommendation": "Overall collection strategy"
  }
}

Risk scoring guidelines:
- 80-100: Critical - immediate action needed, high default probability
- 60-79: High - follow up within 3 days
- 40-59: Medium - weekly reminder
- 0-39: Low - standard collection cycle

Be specific with amounts in ₹ and provide actionable recommendations.
`;

    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();

    console.log('Gemini risk response:', text);

    let riskData;
    try {
      const jsonMatch = text.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
      const jsonText = jsonMatch ? jsonMatch[1] : text;
      riskData = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Failed to parse risk JSON:', text);
      throw new functions.https.HttpsError('internal', 'Failed to parse risk predictions');
    }

    // Track usage
    await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .collection('ai_usage')
      .add({
        featureType: 'payment_risk',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        tokensUsed: response.usageMetadata?.totalTokenCount || 0,
        customersAnalyzed: customers.length,
      });

    return { success: true, data: riskData };
  } catch (error: any) {
    console.error('Payment risk error:', error);
    throw new functions.https.HttpsError('internal', `Risk prediction failed: ${error.message}`);
  }
});

/**
 * Forecast Inventory Demand using Gemini AI
 */
export const forecastInventory = functions
  .runWith({ secrets: ['GEMINI_API_KEY'] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  if (!context.app) {
    throw new functions.https.HttpsError('failed-precondition', 'App Check token is missing or invalid.');
  }

  const { inventoryData, currentMonth } = data;

  try {
    console.log(`Forecasting inventory for user ${context.auth.uid}`);

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const monthName = new Date(2024, (currentMonth || new Date().getMonth()) - 1, 1)
      .toLocaleString('en-IN', { month: 'long' });

    const prompt = `
You are an inventory management AI for an Indian small business. Analyze inventory data to forecast demand.

Current Month: ${monthName}

INVENTORY DATA (with 90-day sales metrics):
${JSON.stringify(inventoryData)}

For each inventory item, predict:
- Daily/weekly demand
- Days until stockout
- Recommended reorder quantity
- Seasonal factors (consider Indian festivals, seasons)

Return JSON in this exact format:
{
  "forecasts": [
    {
      "itemId": "item_id",
      "itemName": "name",
      "currentStock": current_quantity,
      "dailyDemand": predicted_daily_sales,
      "weeklyDemand": predicted_weekly_sales,
      "daysUntilStockout": estimated_days,
      "reorderPoint": when_to_order,
      "recommendedOrderQty": how_much_to_order,
      "trend": "increasing|stable|decreasing",
      "confidence": "high|medium|low",
      "seasonalNote": "Any seasonal factor like Diwali, summer, etc.",
      "alert": {
        "type": "stockout|overstock|slow_moving|seasonal_spike|none",
        "message": "Alert message if any",
        "severity": "critical|warning|info"
      }
    }
  ],
  "summary": {
    "criticalItems": number_needing_immediate_reorder,
    "totalReorderValue": estimated_purchase_amount,
    "slowMovingItems": number_of_slow_movers,
    "recommendation": "Overall inventory strategy"
  }
}

Consider Indian context:
- Festival seasons (Diwali in Oct-Nov, Holi in March, etc.)
- Summer months (April-June) for seasonal products
- Monsoon (July-Sept) impacts
- Wedding season (Nov-Feb)

Be specific with quantities and provide actionable insights.
`;

    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();

    console.log('Gemini forecast response:', text);

    let forecastData;
    try {
      const jsonMatch = text.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
      const jsonText = jsonMatch ? jsonMatch[1] : text;
      forecastData = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Failed to parse forecast JSON:', text);
      throw new functions.https.HttpsError('internal', 'Failed to parse forecast data');
    }

    // Track usage
    await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .collection('ai_usage')
      .add({
        featureType: 'inventory_forecast',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        tokensUsed: response.usageMetadata?.totalTokenCount || 0,
        itemsAnalyzed: inventoryData?.length || 0,
      });

    return { success: true, data: forecastData };
  } catch (error: any) {
    console.error('Inventory forecast error:', error);
    throw new functions.https.HttpsError('internal', `Forecast failed: ${error.message}`);
  }
});

/**
 * Verify Razorpay payment signature and upgrade subscription to premium
 *
 * Resolves BLOCKER 3 — No Server-Side Payment Verification.
 * The signature check uses HMAC-SHA256 with timing-safe comparison so the
 * Razorpay key secret is never exposed to the client.
 */
export const verifyRazorpayPayment = functions
  .runWith({ secrets: ['RAZORPAY_KEY_SECRET'] })
  .https.onCall(async (data, context) => {
  // --- Auth guard ---
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to verify payment'
    );
  }
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token is missing or invalid.'
    );
  }

  const uid = context.auth.uid;
  const { paymentId, orderId, signature, plan } = data;

  // --- Input validation ---
  if (!paymentId || !orderId || !signature || !plan) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'paymentId, orderId, signature, and plan are all required'
    );
  }

  if (plan !== 'monthly' && plan !== 'yearly') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'plan must be "monthly" or "yearly"'
    );
  }

  // --- Razorpay signature verification ---
  // Spec: HMAC-SHA256(orderId + '|' + paymentId, keySecret)
  const razorpayKeySecret = RAZORPAY_KEY_SECRET.value().trim();

  const expectedSignature = crypto
    .createHmac('sha256', razorpayKeySecret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  // Timing-safe comparison — prevents timing-based attacks against the HMAC
  let signaturesMatch = false;
  try {
    signaturesMatch = crypto.timingSafeEqual(
      Buffer.from(expectedSignature, 'hex'),
      Buffer.from(signature, 'hex')
    );
  } catch {
    // timingSafeEqual throws if buffer lengths differ — treat as mismatch
    signaturesMatch = false;
  }

  if (!signaturesMatch) {
    console.warn(`Payment verification failed for uid=${uid} orderId=${orderId}`);
    throw new functions.https.HttpsError(
      'permission-denied',
      'Payment verification failed'
    );
  }

  // --- Check for already-active premium subscription ---
  const subscriptionRef = admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('subscription')
    .doc('current');

  try {
    const subDoc = await subscriptionRef.get();

    if (subDoc.exists) {
      const subData = subDoc.data();
      const currentTier = subData?.tier;
      const currentStatus = subData?.status;
      const endDate = subData?.endDate;
      const now = admin.firestore.Timestamp.now();

      // Active premium that has not yet expired = already subscribed
      if (
        currentTier === 'premium' &&
        currentStatus === 'active' &&
        endDate &&
        endDate.toMillis() > now.toMillis()
      ) {
        throw new functions.https.HttpsError(
          'already-exists',
          'Subscription already active'
        );
      }
    }

    // --- Compute subscription dates ---
    const startDate = new Date();
    const endDate = new Date(startDate);
    if (plan === 'yearly') {
      endDate.setDate(endDate.getDate() + 365);
    } else {
      endDate.setDate(endDate.getDate() + 30);
    }

    // --- Firestore update — mirrors SubscriptionModel.toFirestore() after upgradeToPremium() ---
    // upgradeToPremium() calls .update() with copyWith(), so createdAt is NOT changed here.
    // Field names and values match toFirestore(), SubscriptionFeatures.premiumTier(),
    // and UsageLimits.premiumTier() exactly.
    await subscriptionRef.update({
      tier: 'premium',
      status: 'active',
      startDate: admin.firestore.Timestamp.fromDate(startDate),
      endDate: admin.firestore.Timestamp.fromDate(endDate),
      trialEndDate: null,
      paymentProvider: 'razorpay',
      subscriptionId: paymentId,
      features: {
        ocrScansRemaining: -1,          // Unlimited for premium
        aiInsightsGenerated: 0,
        riskPredictionsUsed: 0,
        inventoryForecastsGenerated: 0,
      },
      usageLimits: {
        ocrScansPerMonth: -1,           // Unlimited for premium
        aiInsightsPerMonth: -1,         // Unlimited for premium
        riskPredictionsEnabled: true,
        inventoryForecastEnabled: true,
      },
      updatedAt: admin.firestore.Timestamp.fromDate(startDate),
    });

    // --- Track upgrade event (mirrors _trackSubscriptionEvent in SubscriptionService) ---
    await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('subscription_events')
      .add({
        event: 'subscription_upgraded',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        parameters: {
          plan: plan,
          payment_id: paymentId,
          order_id: orderId,
        },
      });

    console.log(
      `Subscription upgraded: uid=${uid} plan=${plan} paymentId=${paymentId}`
    );

    return {
      success: true,
      tier: 'premium',
      endDate: endDate.toISOString(),
    };
  } catch (error: any) {
    // Re-throw HttpsErrors as-is (auth, validation, already-exists, permission-denied)
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    console.error(`verifyRazorpayPayment unexpected error for uid=${uid}:`, error);
    throw new functions.https.HttpsError(
      'internal',
      'An unexpected error occurred. Please try again.'
    );
  }
});

/**
 * Create a Razorpay order server-side before opening checkout.
 *
 * Must be called BEFORE opening the Razorpay checkout SDK. Passing the
 * returned orderId into checkout options causes the SDK to return non-null
 * orderId + signature on success, which verifyRazorpayPayment can then
 * authenticate with HMAC-SHA256(orderId|paymentId).
 *
 * Without a pre-created order, the SDK returns null orderId and null
 * signature — making server-side verification impossible.
 */
export const createRazorpayOrder = functions
  .runWith({ secrets: ['RAZORPAY_KEY_ID', 'RAZORPAY_KEY_SECRET'] })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to create an order'
    );
  }
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token is missing or invalid.'
    );
  }

  const { amount, currency = 'INR', planType } = data;

  if (!amount || !planType) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'amount and planType are required'
    );
  }

  if (planType !== 'monthly' && planType !== 'yearly') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'planType must be "monthly" or "yearly"'
    );
  }

  const keyId = RAZORPAY_KEY_ID.value().trim();
  const keySecret = RAZORPAY_KEY_SECRET.value().trim();
  const uid = context.auth.uid;

  // Debug: log secret lengths to catch whitespace/encoding issues (not values)
  console.log(`createRazorpayOrder: keyId len=${keyId.length} keySecret len=${keySecret.length} plan=${planType} amount=${amount}`);

  try {
    const response = await axios.post(
      'https://api.razorpay.com/v1/orders',
      {
        amount,
        currency,
        receipt: `rzp_${Date.now()}`,
        notes: { plan: planType },
      },
      {
        auth: { username: keyId, password: keySecret },
      }
    );

    console.log(`Razorpay order created: ${response.data.id} uid=${uid} plan=${planType}`);

    return {
      orderId: response.data.id,
      amount: response.data.amount,
      currency: response.data.currency,
    };
  } catch (error: any) {
    const razorpayMsg = error?.response?.data?.error?.description || error.message;
    console.error(`createRazorpayOrder failed uid=${uid}: status=${error?.response?.status} msg=${razorpayMsg} fullError=${JSON.stringify(error?.response?.data)}`);
    throw new functions.https.HttpsError('internal', `Failed to create order: ${razorpayMsg}`);
  }
});

/**
 * Initialize subscription document for a new user (free tier).
 *
 * Called by the client on every signup / first launch. The function is
 * idempotent: if the document already exists it returns { alreadyExists: true }
 * and makes no writes.
 *
 * Field values mirror SubscriptionModel.createFreeTier().toFirestore():
 *   tier: 'free', status: 'active', startDate/createdAt/updatedAt: now,
 *   endDate: null, trialEndDate: null, subscriptionId: null,
 *   paymentProvider: 'razorpay',
 *   features: { ocrScansRemaining: 5, aiInsightsGenerated: 0, riskPredictionsUsed: 0,
 *               inventoryForecastsGenerated: 0 },
 *   usageLimits: { ocrScansPerMonth: 5, aiInsightsPerMonth: 0,
 *                  riskPredictionsEnabled: false, inventoryForecastEnabled: false }
 *
 * RACE CONDITION NOTE: The idempotency check (read existing doc) and the
 * subsequent set() are NOT wrapped in a transaction. Two simultaneous first-launch
 * calls (e.g. app killed and reopened within milliseconds) could both pass the
 * existence check and both attempt the set(). Because both would write identical
 * field values this is safe (last-write-wins is harmless here), but it is not
 * strictly atomic. A Firestore transaction or create()-on-missing would fully close
 * this window if stricter guarantees are needed in the future.
 */
export const initializeUserSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to initialize subscription'
    );
  }
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token is missing or invalid.'
    );
  }

  const uid = context.auth.uid;

  const subRef = admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('subscription')
    .doc('current');

  try {
    const existing = await subRef.get();

    // Idempotency guard: if a tier field is already present the doc exists.
    if (existing.exists && existing.data()?.tier) {
      return { alreadyExists: true };
    }

    const now = admin.firestore.Timestamp.now();

    // Field values exactly match SubscriptionModel.createFreeTier().toFirestore()
    const freeTierDoc = {
      tier: 'free',
      status: 'active',
      startDate: now,
      endDate: null,
      trialEndDate: null,
      paymentProvider: 'razorpay',
      subscriptionId: null,
      features: {
        ocrScansRemaining: 5,
        aiInsightsGenerated: 0,
        riskPredictionsUsed: 0,
        inventoryForecastsGenerated: 0,
      },
      usageLimits: {
        ocrScansPerMonth: 5,
        aiInsightsPerMonth: 0,
        riskPredictionsEnabled: false,
        inventoryForecastEnabled: false,
      },
      createdAt: now,
      updatedAt: now,
    };

    await subRef.set(freeTierDoc);

    // Mirror _trackSubscriptionEvent('subscription_initialized', {}) from SubscriptionService
    await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('subscription_events')
      .add({
        event: 'subscription_initialized',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        parameters: {},
      });

    console.log(`initializeUserSubscription: free tier created for uid=${uid}`);

    return { success: true, tier: 'free' };
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) throw error;

    console.error(`initializeUserSubscription error for uid=${uid}:`, error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to initialize subscription. Please try again.'
    );
  }
});

/**
 * Start a 7-day free trial for the authenticated user.
 *
 * Guards:
 *  - trialEndDate already set  → failed-precondition 'Free trial already used'
 *  - tier=premium AND status=active → failed-precondition 'Already on premium plan'
 *
 * Field values mirror SubscriptionModel.createTrial().toFirestore():
 *   tier: 'premium', status: 'trial',
 *   startDate: now, trialEndDate: now+7d, endDate: now+7d,
 *   features: SubscriptionFeatures.premiumTier() → ocrScansRemaining: -1, others: 0
 *   usageLimits: UsageLimits.premiumTier() → ocrScansPerMonth: -1, aiInsightsPerMonth: -1,
 *                riskPredictionsEnabled: true, inventoryForecastEnabled: true
 *
 * Uses update() (not set()) so createdAt is preserved.
 */
export const startFreeTrial = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to start a free trial'
    );
  }
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token is missing or invalid.'
    );
  }

  const uid = context.auth.uid;

  const subRef = admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('subscription')
    .doc('current');

  try {
    const subDoc = await subRef.get();

    if (subDoc.exists) {
      const subData = subDoc.data()!;

      // Trial already used (trialEndDate was ever set)
      if (subData.trialEndDate != null) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Free trial already used'
        );
      }

      // Already on an active premium plan — no need to trial
      if (subData.tier === 'premium' && subData.status === 'active') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Already on premium plan'
        );
      }
    }

    const now = new Date();
    const trialEnd = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // +7 days

    const nowTs = admin.firestore.Timestamp.fromDate(now);
    const trialEndTs = admin.firestore.Timestamp.fromDate(trialEnd);

    // Field values exactly match SubscriptionModel.createTrial().toFirestore().
    // update() preserves createdAt (matching the Dart implementation which also
    // calls _subscriptionRef!.update(trialSub.toFirestore())).
    await subRef.update({
      tier: 'premium',
      status: 'trial',
      startDate: nowTs,
      trialEndDate: trialEndTs,
      endDate: trialEndTs,
      paymentProvider: 'razorpay',
      subscriptionId: null,
      features: {
        ocrScansRemaining: -1,   // Unlimited during trial
        aiInsightsGenerated: 0,
        riskPredictionsUsed: 0,
        inventoryForecastsGenerated: 0,
      },
      usageLimits: {
        ocrScansPerMonth: -1,    // Unlimited during trial
        aiInsightsPerMonth: -1,
        riskPredictionsEnabled: true,
        inventoryForecastEnabled: true,
      },
      updatedAt: nowTs,
    });

    // Mirror _trackSubscriptionEvent('trial_started', {}) from SubscriptionService
    await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('subscription_events')
      .add({
        event: 'trial_started',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        parameters: {},
      });

    console.log(`startFreeTrial: trial started for uid=${uid}, ends ${trialEnd.toISOString()}`);

    return { success: true, trialEndDate: trialEnd.toISOString() };
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) throw error;

    console.error(`startFreeTrial error for uid=${uid}:`, error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to start free trial. Please try again.'
    );
  }
});

/**
 * Cancel the authenticated user's active subscription.
 *
 * Guard: subscription must be premium and active (or trial); otherwise
 * throws failed-precondition 'No active subscription to cancel'.
 *
 * Writes: update() sets status='cancelled' and updatedAt=now.
 * The user retains premium access until the existing endDate (handled by
 * checkExpiredSubscriptions scheduled function).
 *
 * Optional input: { reason: string } — stored in the subscription_events entry.
 */
export const cancelSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to cancel subscription'
    );
  }
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token is missing or invalid.'
    );
  }

  const uid = context.auth.uid;
  const reason: string | undefined = data?.reason;

  const subRef = admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('subscription')
    .doc('current');

  try {
    const subDoc = await subRef.get();

    if (!subDoc.exists) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'No active subscription to cancel'
      );
    }

    const subData = subDoc.data()!;
    const isPremiumOrTrial =
      subData.tier === 'premium' &&
      (subData.status === 'active' || subData.status === 'trial');

    if (!isPremiumOrTrial) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'No active subscription to cancel'
      );
    }

    // update() — only status and updatedAt change, matching the Dart copyWith() pattern
    await subRef.update({
      status: 'cancelled',
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Mirror _trackSubscriptionEvent('subscription_cancelled', {...}) from SubscriptionService
    const eventParameters: Record<string, any> = {
      tier: subData.tier,
      previous_status: subData.status,
    };
    if (reason) {
      eventParameters.reason = reason;
    }

    await admin
      .firestore()
      .collection('users')
      .doc(uid)
      .collection('subscription_events')
      .add({
        event: 'subscription_cancelled',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        parameters: eventParameters,
      });

    console.log(`cancelSubscription: cancelled for uid=${uid}${reason ? ` reason=${reason}` : ''}`);

    return { success: true };
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) throw error;

    console.error(`cancelSubscription error for uid=${uid}:`, error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to cancel subscription. Please try again.'
    );
  }
});
