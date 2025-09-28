# Firestore Security Rules - Setup and Deployment Guide

## Overview

This guide explains how to deploy and test the comprehensive Firestore security rules for InvoiceFlow's multi-tenant architecture.

## 🔒 Security Rules Summary

The `firestore.rules` file implements:

### **Multi-Tenant Data Isolation**
- ✅ Users can only access data under `users/{uid}/`
- ✅ Authenticated users required for all operations
- ✅ Complete cross-user data access prevention

### **Protected Collections**
- ✅ `users/{uid}/customers/` - Customer data with validation
- ✅ `users/{uid}/invoices/` - Invoice data with business logic validation
- ✅ `users/{uid}/inventory_items/` - Inventory items with stock validation
- ✅ `users/{uid}/stock_movements/` - Stock movement audit trail

### **Data Validation**
- ✅ Required field validation for all models
- ✅ Data type and format validation
- ✅ Business logic constraints (amounts, quantities, etc.)
- ✅ Audit trail protection for stock movements

## 📋 Pre-Deployment Checklist

Before deploying the security rules, ensure:

1. **Firebase CLI Installed**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Project Authentication**:
   ```bash
   firebase login
   ```

3. **Project Initialization** (if not done):
   ```bash
   firebase init firestore
   ```

4. **Backup Current Rules** (if any exist):
   ```bash
   firebase firestore:rules get > firestore.rules.backup
   ```

## 🚀 Deployment Steps

### Step 1: Verify Rules File
Ensure the `firestore.rules` file is in your project root:
```
invoiceflow/
├── firestore.rules     # ← Should be here
├── firebase.json
├── pubspec.yaml
└── lib/
```

### Step 2: Test Rules Locally (Recommended)
```bash
# Start the Firestore emulator with rules
firebase emulators:start --only firestore

# In another terminal, run your app against the emulator
flutter run
```

### Step 3: Deploy Rules to Production
```bash
# Deploy rules to your Firebase project
firebase deploy --only firestore:rules
```

### Step 4: Verify Deployment
```bash
# Check deployed rules
firebase firestore:rules list
```

## 🧪 Testing the Security Rules

### Manual Testing Commands

1. **Test Authentication Requirement**:
   ```javascript
   // This should FAIL (no auth)
   db.collection('users').doc('test-uid').collection('invoices').get()
   ```

2. **Test User Isolation**:
   ```javascript
   // User A trying to access User B's data - should FAIL
   db.collection('users').doc('user-b-uid').collection('customers').get()
   ```

3. **Test Valid Operations**:
   ```javascript
   // User accessing their own data - should SUCCEED
   db.collection('users').doc(currentUser.uid).collection('invoices').get()
   ```

### Automated Testing Script

Create a test file `test_security_rules.js`:

```javascript
const firebase = require('@firebase/testing');

describe('InvoiceFlow Security Rules', () => {
  // Test user isolation
  it('should deny access to other users data', async () => {
    const db = firebase.firestore();
    await firebase.assertFails(
      db.collection('users').doc('other-user').collection('invoices').get()
    );
  });

  // Test authenticated access
  it('should allow access to own data when authenticated', async () => {
    const auth = { uid: 'test-user', email: 'test@example.com' };
    const db = firebase.firestore(auth);
    await firebase.assertSucceeds(
      db.collection('users').doc('test-user').collection('invoices').get()
    );
  });
});
```

## 🔧 Rule Configuration Details

### **Key Security Features**

1. **Authentication Guards**:
   ```javascript
   function isAuthenticated() {
     return request.auth != null;
   }

   function isOwner(uid) {
     return isAuthenticated() && request.auth.uid == uid;
   }
   ```

2. **Data Validation Functions**:
   - Phone number format validation
   - Invoice amount limits (max 1 crore)
   - Item quantity limits (max 10,000)
   - String length limits
   - Required field validation

3. **Business Logic Protection**:
   - Invoice amounts vs. payment validation
   - Stock movement audit trail protection
   - Immutable field protection (IDs, SKUs)

### **Validation Limits**

| Field | Limit | Reason |
|-------|-------|---------|
| Customer Name | 100 chars | UI display constraints |
| Invoice Amount | ₹1 crore | Business limit |
| Items per Invoice | 100 items | Performance |
| Stock Movement | ±10,000 units | Reasonable business limit |
| Notes/Descriptions | 500 chars | Storage optimization |

## 🚨 Security Best Practices

### **Implemented Protections**

1. **Zero-Trust Architecture**: Every operation requires authentication and authorization
2. **Data Isolation**: Complete separation between user accounts
3. **Input Validation**: Comprehensive validation of all data types
4. **Audit Trail Protection**: Stock movements are immutable once created
5. **Business Logic Enforcement**: Prevents invalid business operations

### **Additional Recommendations**

1. **Monitor Rule Performance**:
   ```bash
   # Check rule evaluation metrics in Firebase Console
   # Navigate to Firestore > Usage > Rules evaluation
   ```

2. **Set up Monitoring**:
   ```javascript
   // Add logging for security violations
   functions.firestore.document('users/{uid}/violations/{violationId}')
     .onCreate((snap, context) => {
       console.error('Security violation detected', snap.data());
     });
   ```

3. **Regular Security Audits**:
   - Review access patterns monthly
   - Monitor for unusual data access
   - Update rules as business logic evolves

## 🔍 Troubleshooting

### Common Issues

1. **"Permission Denied" Errors**:
   - Verify user is authenticated
   - Check if UID matches document path
   - Validate required fields are present

2. **Rule Deployment Failures**:
   ```bash
   # Check syntax
   firebase firestore:rules validate

   # View detailed error messages
   firebase deploy --only firestore:rules --debug
   ```

3. **Testing Issues**:
   ```bash
   # Clear emulator data
   firebase emulators:start --only firestore --import=./seed-data --export-on-exit
   ```

### Debug Mode

Enable debug logging during development:

```javascript
// Add to your Flutter app for debugging
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  // Enable for debug logging
  host: 'localhost:8080', // When using emulator
  sslEnabled: false,
);
```

## 📈 Performance Considerations

1. **Rule Complexity**: Current rules are optimized for security with minimal performance impact
2. **Index Requirements**: Ensure proper indexes are created for query patterns
3. **Caching**: Rules evaluation is cached by Firebase for better performance

## 🔄 Update Process

When updating rules:

1. **Test Changes Locally**: Always test with emulator first
2. **Gradual Rollout**: Consider staging environment deployment
3. **Monitor Metrics**: Watch for increased denial rates
4. **Rollback Plan**: Keep previous rules backed up

```bash
# Backup before updates
firebase firestore:rules get > firestore.rules.backup.$(date +%Y%m%d)

# Deploy new rules
firebase deploy --only firestore:rules

# Rollback if needed
firebase deploy --only firestore:rules --file firestore.rules.backup.20241201
```

## ✅ Verification Checklist

After deployment, verify:

- [ ] **Authentication Required**: Unauthenticated requests are denied
- [ ] **User Isolation**: Users cannot access other users' data
- [ ] **Data Validation**: Invalid data is rejected
- [ ] **Business Logic**: Amount and quantity limits are enforced
- [ ] **Audit Trail**: Stock movements cannot be tampered with
- [ ] **Performance**: No significant impact on app performance

## 📞 Support

If you encounter issues:

1. Check Firebase Console for rule evaluation errors
2. Review the Security Rules documentation
3. Use Firebase emulator for local testing
4. Monitor application logs for security violations

The security rules are now production-ready and provide comprehensive protection for your InvoiceFlow application's multi-tenant architecture.