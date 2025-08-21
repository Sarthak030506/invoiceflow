# App Signing Setup for InvoiceFlow

## Step 1: Generate Upload Keystore

Run this command in your terminal (make sure you have Java installed):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### When prompted, provide:
- **Keystore password**: Choose a strong password (save this!)
- **Key password**: Choose a strong password (save this!)
- **First and last name**: Your name or company name
- **Organizational unit**: Your department/team
- **Organization**: Your company name
- **City**: Your city
- **State**: Your state/province
- **Country code**: Your 2-letter country code (e.g., US, IN, UK)

## Step 2: Move Keystore File

Move the generated `upload-keystore.jks` file to the `android/` directory:

```bash
mv upload-keystore.jks android/
```

## Step 3: Create key.properties File

Create `android/key.properties` file with your actual values:

```properties
storePassword=your_actual_keystore_password
keyPassword=your_actual_key_password
keyAlias=upload
storeFile=../upload-keystore.jks
```

## Step 4: Add to .gitignore

Add these lines to your `.gitignore` file:

```
# Android signing
android/key.properties
android/upload-keystore.jks
```

## Step 5: Build Release APK

```bash
flutter build apk --release
```

## Step 6: Build App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release
```

## Important Security Notes

1. **NEVER commit keystore files or key.properties to version control**
2. **Keep multiple backups of your keystore file in secure locations**
3. **If you lose your keystore, you cannot update your app on Play Store**
4. **Store passwords securely (use a password manager)**

## Troubleshooting

### If you get "keytool not found":
- Make sure Java JDK is installed
- Add Java bin directory to your PATH
- On Windows: Usually `C:\Program Files\Java\jdk-XX\bin`

### If build fails:
- Check that key.properties file exists and has correct values
- Verify keystore file is in the correct location
- Ensure passwords match what you set during keystore generation

## File Structure After Setup

```
android/
├── key.properties          # Your signing configuration
├── upload-keystore.jks     # Your keystore file (keep secure!)
└── app/
    └── build.gradle        # Updated with signing config
```

## Next Steps

After successful setup:
1. Test the release build on a device
2. Upload to Play Console for internal testing
3. Complete Play Store listing
4. Submit for review