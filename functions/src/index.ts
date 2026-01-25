import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenerativeAI } from '@google/generative-ai';
import axios from 'axios';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Gemini AI
// Get API key from Firebase Functions config: firebase functions:config:set gemini.apikey="YOUR_KEY"
const genAI = new GoogleGenerativeAI(
  functions.config().gemini?.apikey || process.env.GEMINI_API_KEY || ''
);

/**
 * Process OCR - Extract invoice data from receipt image using Gemini Vision API
 */
export const processOCR = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use OCR'
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

    // Call Gemini Vision API
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

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

    console.log(
      `OCR completed successfully: ${normalizedData.items.length} items detected`
    );

    return {
      success: true,
      data: normalizedData,
    };
  } catch (error: any) {
    console.error('OCR processing error:', error);

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
export const generateBusinessInsights = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { invoiceData, customerData, inventoryData } = data;

  try {
    console.log(`Generating AI insights for user ${context.auth.uid}`);

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

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
export const predictPaymentRisk = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { customers } = data;

  try {
    console.log(`Predicting payment risk for user ${context.auth.uid}`);

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

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
export const forecastInventory = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { inventoryData, currentMonth } = data;

  try {
    console.log(`Forecasting inventory for user ${context.auth.uid}`);

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

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
