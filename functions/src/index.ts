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
