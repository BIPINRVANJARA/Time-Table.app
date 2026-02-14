# Security Setup Guide

This guide provides step-by-step instructions for setting up security features in the Time Table app.

---

## 1. Deploy Firestore Security Rules

The enhanced security rules require email verification for all operations.

**Steps:**

1. Open terminal in project directory
2. Run the following command:
   ```bash
   firebase deploy --only firestore:rules
   ```
3. Verify deployment success in Firebase Console

**What this does:**
- Requires email verification for all database operations
- Enforces admin role checks for timetable modifications
- Adds audit log collection with validation

---

## 2. Set Admin Roles

Admin users must be manually designated in Firebase Console.

**Steps:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **timestunner**
3. Navigate to **Firestore Database**
4. Find the `users` collection
5. Click on the user document you want to make admin
6. Add or edit the `role` field:
   - Field: `role`
   - Value: `admin`
7. Click **Update**

**Important:** Only users with `role: admin` can access the Admin Dashboard and modify timetables.

---

## 3. Restrict Firebase API Keys (CRITICAL)

Follow the detailed instructions in `FIREBASE_API_RESTRICTIONS.md`.

**Quick steps:**

1. Get SHA-1 fingerprint for debug build:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy the SHA-1 from the output

2. Go to [Google Cloud Console](https://console.cloud.google.com/)
3. Select project: **timestunner**
4. Navigate to **APIs & Services** → **Credentials**
5. Find "Android key (auto created by Firebase)"
6. Click to edit
7. Under **Application restrictions**, select **Android apps**
8. Add your package name and SHA-1 fingerprint
9. Under **API restrictions**, enable only:
   - Firebase Authentication API
   - Cloud Firestore API
   - Identity Toolkit API
10. Click **Save**

---

## 4. Test Email Verification Flow

**Test Case 1: New User Signup**

1. Run the app: `flutter run`
2. Click "Sign Up"
3. Enter email and strong password (8+ chars, uppercase, number, special char)
4. Click "Create Account"
5. **Expected:** Redirected to Email Verification screen
6. Check email inbox for verification link
7. Click verification link
8. **Expected:** App automatically detects verification and proceeds to Academic Setup

**Test Case 2: Existing Unverified User**

1. Try to login with unverified account
2. **Expected:** Redirected to Email Verification screen
3. Click "Resend Email" if needed
4. Verify email and app should proceed automatically

---

## 5. Test Admin Access Control

**Test Case 1: Non-Admin User**

1. Login as regular student (without admin role)
2. Try to navigate to Admin Dashboard (if accessible)
3. **Expected:** Redirected to main app with error "Admin access required"

**Test Case 2: Admin User**

1. Set user role to 'admin' in Firebase Console (see Step 2)
2. Login with admin account
3. Navigate to Admin Dashboard
4. **Expected:** Access granted, can manage timetables

---

## 6. Test Password Strength Validation

**Test passwords:**

- ❌ `123456` - Too short, no uppercase, no special char
- ❌ `password` - No uppercase, no number, no special char
- ❌ `Password123` - No special character
- ✅ `Password@123` - Meets all requirements

**Expected behavior:**
- Password strength indicator shows real-time strength
- Form validation prevents weak passwords
- Clear error messages guide users

---

## 7. Verify Firestore Rules

After deploying rules, test that:

1. **Unverified users cannot access data:**
   - Create account but don't verify email
   - Try to access timetables
   - **Expected:** Permission denied

2. **Verified students can read timetables:**
   - Login with verified student account
   - View timetables
   - **Expected:** Success

3. **Non-admin users cannot modify timetables:**
   - Login as verified student
   - Try to add/edit subject (via code)
   - **Expected:** Permission denied

4. **Admin users can modify timetables:**
   - Login as admin
   - Add/edit/delete subjects
   - **Expected:** Success

---

## 8. Monitor Security

**Firebase Console Monitoring:**

1. Go to Firebase Console → **Authentication**
2. Check **Users** tab for verified emails
3. Go to **Firestore Database**
4. Monitor `audit_logs` collection for admin actions

**What to watch for:**
- Unusual number of failed login attempts
- Unexpected admin actions in audit logs
- Unverified users trying to access data (check Firebase logs)

---

## Troubleshooting

### Email Verification Not Working

**Problem:** Verification emails not received

**Solutions:**
1. Check spam/junk folder
2. Verify email settings in Firebase Console → **Authentication** → **Templates**
3. Try resending verification email
4. Check Firebase Console → **Authentication** → **Users** to see if email is verified

### Admin Access Denied

**Problem:** Admin user cannot access Admin Dashboard

**Solutions:**
1. Verify `role` field is set to `admin` in Firestore
2. Ensure user's email is verified
3. Check browser console for errors
4. Try logging out and logging back in

### Firestore Permission Denied

**Problem:** Users getting permission denied errors

**Solutions:**
1. Verify Firestore rules are deployed: `firebase deploy --only firestore:rules`
2. Check that user's email is verified
3. For admin operations, verify user has `role: admin`
4. Check Firebase Console → **Firestore** → **Rules** tab for rule errors

### Password Strength Indicator Not Showing

**Problem:** Password strength indicator not visible

**Solutions:**
1. Start typing in password field
2. Indicator only shows when password field is not empty
3. Check for console errors

---

## Security Checklist

After setup, verify:

- [ ] Firestore security rules deployed
- [ ] At least one admin user designated
- [ ] Firebase API keys restricted (Android)
- [ ] Email verification working for new signups
- [ ] Email verification required for login
- [ ] Password strength validation enforced
- [ ] Admin dashboard checks role before access
- [ ] Non-admin users cannot modify timetables
- [ ] Verified students can view timetables
- [ ] Unverified users cannot access any data

---

## Next Steps

1. **Enable Firebase App Check** (see `implementation_plan.md` Phase 4)
2. **Set up monitoring alerts** in Firebase Console
3. **Regular security audits** - Review audit logs monthly
4. **Update documentation** - Keep this guide current as you add features

---

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review `implementation_plan.md` for detailed technical information
3. Consult `security_summary.md` for overview

**Last Updated:** February 12, 2026
