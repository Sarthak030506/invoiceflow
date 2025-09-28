# Test Plan: Pick from Call List Feature

## Feature Overview
Added a "Pick from Call List" button to the customer input form when creating sales invoices, allowing users to select contacts directly from their device's native contact list.

## Implementation Summary

### 1. New Service Created
- **File**: `lib/services/contact_picker_service.dart`
- **Purpose**: Handles device contact access using contacts_service package
- **Features**:
  - Permission handling for contact access
  - Opens device's native contact picker
  - Phone number cleaning and validation
  - Filters for valid Indian mobile numbers

### 3. Customer Input Widget Enhanced
- **File**: `lib/presentation/create_invoice/widgets/customer_input_widget.dart`
- **Changes**:
  - Added "Pick from Call List" button
  - Added contact selection handling
  - Auto-fills name and phone when contact selected

## How to Test

### Manual Testing Steps:

1. **Navigate to Invoice Creation**
   - Go to create new sales invoice
   - Choose "New Customer" option
   - Verify customer input form appears

2. **Check Button Visibility**
   - Verify "Pick from Call List" button appears between name and phone fields
   - Button should have contacts icon and proper styling
   - Button should be full width

3. **Test Contact Picker**
   - Tap "Pick from Call List" button
   - Permission dialog should appear (first time)
   - Grant contacts permission
   - Device's native contact picker should open

4. **Test Contact Selection**
   - Browse through device contacts
   - Select any contact with a phone number
   - Should return to customer input form
   - Name and phone fields should be auto-filled
   - Phone validation should pass

6. **Test Invoice Flow**
   - After selecting contact, continue with invoice creation
   - Verify customer data is properly passed through
   - Complete invoice creation to ensure no issues

### Expected Behavior:

- **Permission Request**: Asks for contacts permission on first use
- **Native Picker**: Opens device's built-in contact picker
- **Auto-fill**: Selected contact name and phone auto-populate form fields
- **Validation**: Phone numbers are cleaned and validated
- **New Customer**: Creates new customer record if contact not in existing customers
- **Real Contacts**: Uses actual contacts from user's device

### Edge Cases to Test:

1. **Permission Denied**: Handle when user denies contacts permission
2. **No Phone Number**: Handle contacts without phone numbers
3. **Invalid Phone Numbers**: Clean and validate phone numbers
4. **Cancel Selection**: Handle when user cancels contact picker
5. **Multiple Phone Numbers**: Handle contacts with multiple phone numbers

## Files Modified/Created:

### New Files:
- `lib/services/contact_picker_service.dart`

### Modified Files:
- `lib/presentation/create_invoice/widgets/customer_input_widget.dart`
- `pubspec.yaml` (added contacts_service and permission_handler)
- `android/app/src/main/AndroidManifest.xml` (added READ_CONTACTS permission)

## Future Enhancements:

1. **Native Integration**: Add platform-specific contact access
2. **Permissions**: Handle contact permission requests
3. **Call History**: Access recent call logs if permissions available
4. **Contact Photos**: Display contact profile pictures
5. **Favorites**: Show frequently contacted numbers first

## Benefits:

1. **User Experience**: Quick contact selection without manual typing
2. **Accuracy**: Reduces errors in name and phone number entry
3. **Efficiency**: Faster invoice creation workflow
4. **Integration**: Seamless integration with existing customer flow
5. **Fallback**: Works even without native contact access