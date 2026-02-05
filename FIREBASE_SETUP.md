# Firebase Setup Guide for Timestunner

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: **Timestunner** (or your college name)
4. Disable Google Analytics (optional for now)
5. Click "Create project"

---

## Step 2: Add Android App

1. In Firebase Console, click the Android icon
2. **Android package name**: `com.schedulo.timetable.timetable_app`
   (Found in `android/app/build.gradle.kts`)
3. **App nickname**: Timestunner
4. **Debug signing certificate SHA-1**: (Optional for now)
5. Click "Register app"

---

## Step 3: Download google-services.json

1. Download the `google-services.json` file
2. Place it in: `android/app/google-services.json`
3. **DO NOT** commit this file to Git (add to .gitignore)

---

## Step 4: Configure Android Build Files

### android/build.gradle.kts
Add Google services classpath:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

### android/app/build.gradle.kts
Add at the bottom:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this line
}
```

---

## Step 5: Enable Firebase Services

### Authentication
1. In Firebase Console → Authentication
2. Click "Get started"
3. Enable "Email/Password" sign-in method
4. Save

### Firestore Database
1. In Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **Test mode** (we'll add security rules later)
4. Choose location: **asia-south1** (Mumbai) or closest
5. Click "Enable"

### Cloud Messaging
1. In Firebase Console → Cloud Messaging
2. No setup needed - automatically enabled

---

## Step 6: Set Up Firestore Security Rules

Replace default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
    
    // Timetables - students can read, only admins can write
    match /timetables/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Branches, semesters, etc. - read-only for all authenticated users
    match /config/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## Step 7: Initialize Firebase in Flutter

The app will automatically initialize Firebase on startup.
Check `lib/main.dart` for initialization code.

---

## Step 8: Create First Admin User

After deploying the app:

1. Sign up with an email (e.g., admin@college.edu)
2. Go to Firebase Console → Firestore Database
3. Find the user document
4. Manually change `role` from `"student"` to `"admin"`

---

## Step 9: Test Firebase Connection

Run the app and check:
- [ ] No Firebase initialization errors
- [ ] Can sign up with email/password
- [ ] User document created in Firestore
- [ ] Can log in and out

---

## Security Checklist

- [ ] `google-services.json` added to `.gitignore`
- [ ] Firestore security rules configured
- [ ] Test mode disabled after initial setup
- [ ] Admin role manually assigned to first user

---

## Troubleshooting

### "google-services.json not found"
- Make sure file is in `android/app/` directory
- Run `flutter clean` and rebuild

### "Firebase not initialized"
- Check `google-services.json` package name matches `build.gradle.kts`
- Ensure `com.google.gms.google-services` plugin is applied

### "Permission denied" in Firestore
- Check security rules
- Verify user is authenticated
- Check user role for admin operations

---

## Next Steps

After Firebase is set up:
1. Test authentication flow
2. Create academic setup wizard
3. Build admin panel
4. Set up FCM notifications
