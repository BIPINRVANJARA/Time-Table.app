# Firebase Rules Deployment Note

## Manual Deployment Required

The Firestore security rules have been updated in `firestore.rules` but need to be manually deployed.

### Reason
Firebase CLI is not installed on this system.

### How to Deploy

**Option 1: Install Firebase CLI and Deploy**

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

**Option 2: Manual Deployment via Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **timestunner**
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the contents of `firestore.rules` from your project
5. Paste into the Firebase Console rules editor
6. Click **Publish**

### What Changed in the Rules

The updated rules now:
- ✅ Require email verification for all operations
- ✅ Use helper functions for cleaner code
- ✅ Add audit log collection support
- ✅ Enforce admin role checks consistently

### Verification

After deploying, test that:
1. Unverified users cannot access timetables
2. Verified students can read timetables
3. Only admins can modify timetables

See `SECURITY_SETUP_GUIDE.md` for detailed testing instructions.
