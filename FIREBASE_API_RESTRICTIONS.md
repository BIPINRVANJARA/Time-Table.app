# Firebase API Key Restrictions Guide

## Overview

This guide explains how to secure your Firebase API keys by applying restrictions in the Firebase Console. While Firebase API keys are designed to be included in client applications, they should still be restricted to prevent unauthorized use.

---

## Why Restrict API Keys?

> [!IMPORTANT]
> **API Key Security**: Firebase API keys identify your project to Google servers. Without restrictions, anyone with your API key could potentially abuse your Firebase quota, leading to unexpected costs or service disruptions.

**Benefits of API Key Restrictions:**
- Prevent unauthorized API usage
- Protect against quota abuse
- Reduce security attack surface
- Comply with security best practices

---

## Step-by-Step Instructions

### 1. Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **timestunner**
3. Click the **gear icon** (ΓÜÖ∩╕Å) next to "Project Overview"
4. Select **Project settings**

### 2. Navigate to API Keys Section

1. In Project Settings, scroll down to **Your apps** section
2. You'll see your registered apps (Android, Web, iOS)
3. Each app has an associated API key

### 3. Restrict Android API Key

#### Option A: Via Firebase Console

1. Click on your **Android app** in the "Your apps" section
2. Find the **API Key** field
3. Click **Manage API keys in Google Cloud Console** (this will open Google Cloud Console)

#### Option B: Direct to Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **timestunner**
3. Navigate to **APIs & Services** ΓåÆ **Credentials**
4. Find the API key for Android (usually named "Android key (auto created by Firebase)")

#### Apply Android Restrictions

1. Click on the API key to edit
2. Under **Application restrictions**, select **Android apps**
3. Click **Add an item**
4. Enter your package name and SHA-1 certificate fingerprint:
   - **Package name**: `com.yourcompany.timetable_app` (check your `android/app/build.gradle`)
   - **SHA-1 fingerprint**: Get this by running:
     ```bash
     cd android
     ./gradlew signingReport
     ```
     Copy the SHA-1 from the output

5. Under **API restrictions**, select **Restrict key**
6. Enable only the APIs your app uses:
   - Γ£à Firebase Authentication API
   - Γ£à Cloud Firestore API
   - Γ£à Firebase Cloud Messaging API
   - Γ£à Identity Toolkit API
7. Click **Save**

### 4. Restrict Web API Key

1. In Google Cloud Console ΓåÆ **Credentials**
2. Find the **Browser key (auto created by Firebase)**
3. Click to edit
4. Under **Application restrictions**, select **HTTP referrers (web sites)**
5. Click **Add an item** and add your authorized domains:
   ```
   localhost:*
   127.0.0.1:*
   your-domain.com/*
   your-domain.netlify.app/*
   ```
6. Under **API restrictions**, select **Restrict key**
7. Enable the same APIs as Android
8. Click **Save**

### 5. Enable Firebase App Check (Recommended)

Firebase App Check provides an additional layer of security by verifying that requests come from your authentic app.

#### For Android:

1. In Firebase Console, go to **Build** ΓåÆ **App Check**
2. Click **Get started**
3. Select your **Android app**
4. Choose **Play Integrity** as the provider
5. Click **Save**
6. Add App Check to your app:

**Add dependency to `pubspec.yaml`:**
```yaml
dependencies:
  firebase_app_check: ^0.2.1+8
```

**Initialize in `main.dart`:**
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  
  runApp(const MyApp());
}
```

#### For Web:

1. In App Check settings, select your **Web app**
2. Choose **reCAPTCHA v3** as the provider
3. Register your site at [reCAPTCHA Admin](https://www.google.com/recaptcha/admin)
4. Add the site key to your web app configuration

---

## Verification Checklist

After applying restrictions, verify everything works:

- [ ] Android app can authenticate users
- [ ] Android app can read/write to Firestore
- [ ] Web app (if applicable) functions correctly
- [ ] Push notifications still work
- [ ] No console errors related to API keys

---

## Current API Key Status

**Your current API key** (from `firebase_options.dart`):
```
AIzaSyCbRfIbLUSt3-J2JDuUzIp3B6XOzgKJ2ho
```

> [!WARNING]
> This key is currently **UNRESTRICTED**. Follow the steps above to secure it immediately.

---

## Troubleshooting

### "API key not valid" Error

**Cause**: API key restrictions are too strict or incorrectly configured.

**Solution**:
1. Verify package name matches exactly
2. Verify SHA-1 fingerprint is correct
3. Check that required APIs are enabled
4. Wait 5-10 minutes for changes to propagate

### App Works Locally But Not in Production

**Cause**: Different signing keys for debug vs. release builds.

**Solution**:
1. Get SHA-1 for **both** debug and release keystores
2. Add both SHA-1 fingerprints to the API key restrictions

**Get release SHA-1:**
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

### Web App CORS Errors

**Cause**: Domain not added to HTTP referrer restrictions.

**Solution**:
1. Add your production domain to HTTP referrers
2. Include both `http://` and `https://` versions if needed
3. Use wildcards for subdomains: `*.yourdomain.com/*`

---

## Security Best Practices

1. **Never commit API keys to public repositories** (already handled by `.gitignore`)
2. **Use different Firebase projects** for development and production
3. **Rotate API keys** if you suspect they've been compromised
4. **Monitor API usage** in Google Cloud Console for unusual activity
5. **Enable billing alerts** to catch quota abuse early

---

## Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [Google Cloud API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

## Next Steps

1. Γ£à Apply Android API key restrictions
2. Γ£à Apply Web API key restrictions (if using web)
3. Γ£à Enable Firebase App Check
4. Γ£à Test all app functionality
5. Γ£à Monitor API usage for the first week

> [!TIP]
> Set a calendar reminder to review your API key restrictions quarterly to ensure they remain properly configured.
