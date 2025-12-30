# 🔥 Firebase Setup Guide - Step by Step

## Part 1: Create Firebase Project

### Step 1: Go to Firebase Console
1. Open browser and navigate to: **https://console.firebase.google.com/**
2. Click **"Add project"** or **"Create a project"**

### Step 2: Project Details
1. **Project name**: `PropLedger` (or any name you prefer)
2. Click **Continue**
3. **Google Analytics**: You can disable it for now (toggle OFF)
4. Click **Create project**
5. Wait for project creation (takes ~30 seconds)
6. Click **Continue** when done

---

## Part 2: Add Android App

### Step 3: Register Android App
1. In Firebase Console, click the **Android icon** (robot symbol)
2. **Android package name**: `com.propledger.propledger`
   - ⚠️ **IMPORTANT**: Must match exactly!
3. **App nickname**: `PropLedger Android` (optional)
4. **Debug signing certificate SHA-1**: Leave blank for now
5. Click **Register app**

### Step 4: Download google-services.json
1. Click **Download google-services.json**
2. **CRITICAL**: Move this file to:
   ```
   C:\git\PropLedger\android\app\google-services.json
   ```
3. ✅ Verify the file is in the correct location
4. Click **Next** (skip the "Add Firebase SDK" step, already done)
5. Click **Next** again (skip Run app step)
6. Click **Continue to console**

---

## Part 3: Enable Firebase Services

### Step 5: Enable Authentication
1. In Firebase Console sidebar, click **Authentication**
2. Click **Get started**
3. Click **Email/Password** tab
4. Toggle **Enable** switch ON
5. Click **Save**

### Step 6: Enable Firestore Database
1. In Firebase Console sidebar, click **Firestore Database**
2. Click **Create database**
3. **Select location**: Choose closest to you (e.g., `us-central` or `europe-west`)
4. **Security rules**: Select **"Start in test mode"**
   - ⚠️ Test mode allows read/write for 30 days (we'll secure it later)
5. Click **Next**, then **Enable**
6. Wait for database creation (~1 minute)

### Step 7: Set Up Security Rules (IMPORTANT)
1. Still in **Firestore Database**, click **Rules** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User backups subcollection
      match /backups/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User backup metadata
      match /backupMetadata/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **Publish**

---

## Part 4: Verify Setup

### Step 8: Check File Location
Verify `google-services.json` is in the correct location:
```
C:\git\PropLedger\android\app\google-services.json
```

The file should look similar to this:
```json
{
  "project_info": {
    "project_number": "...",
    "project_id": "propledger-...",
    "storage_bucket": "..."
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "...",
        "android_client_info": {
          "package_name": "com.propledger.propledger"
        }
      }
    }
  ]
}
```

---

## Part 5: Test Firebase Connection

### Step 9: Run the App
1. Open terminal in VS Code
2. Make sure your phone is connected via USB or wireless
3. Run:
   ```bash
   flutter run
   ```

### Step 10: Verify Firebase Initialization
1. Watch the console output
2. Look for: **`✅ Firebase initialized successfully`**
3. If you see this, Firebase is working! 🎉

### Step 11: Test Authentication
1. On the Login screen, tap **"Sign Up"**
2. Enter:
   - **Name**: Test User
   - **Email**: test@propledger.com
   - **Password**: test123
   - **Confirm Password**: test123
3. Tap **"Create Account"**
4. If successful, you'll be redirected to the Dashboard

### Step 12: Verify User in Firebase
1. Go back to Firebase Console
2. Click **Authentication** in sidebar
3. You should see your test user listed!

---

## Part 6: Enable Test Subscription

### Step 13: Activate Premium (Test Mode)
1. In the app, go to **Settings** → **Subscription**
2. You'll see a **"Activate Premium (Test)"** button
3. Tap it to enable 30-day premium access
4. **Online Backups** option will now be enabled

### Step 14: Test Online Backup
1. In **Settings** → **Cloud Backup**
2. Tap **"Backup Now"**
3. Wait for backup to complete
4. Check Firebase Console → Firestore Database
5. You should see your data under: `users/{userId}/backups/`

---

## Troubleshooting

### ❌ Firebase initialization skipped
**Problem**: `google-services.json` not found
**Solution**: 
1. Double-check file location: `android/app/google-services.json`
2. Restart the app: `flutter run`

### ❌ Package name mismatch
**Problem**: Error about package name
**Solution**: 
1. Verify package name in `google-services.json` is `com.propledger.propledger`
2. Re-download `google-services.json` with correct package name

### ❌ Authentication failed
**Problem**: Sign up/sign in doesn't work
**Solution**:
1. Check Firebase Console → Authentication
2. Verify Email/Password is **enabled**
3. Check internet connection

### ❌ Backup requires subscription
**Problem**: Can't backup, shows "requires premium"
**Solution**:
1. Go to Settings → Subscription
2. Tap **"Activate Premium (Test)"**
3. Try backup again

---

## Next Steps

✅ Firebase is now set up!
✅ Authentication working
✅ Firestore database ready
✅ Test subscription active

You can now:
- Create real user accounts
- Test online backups
- Sync data across devices
- Set up production security rules

---

## Production Checklist (Later)

Before releasing to users:
- [ ] Update Firestore security rules (remove test mode)
- [ ] Set up real payment processing (Stripe/Google Play Billing)
- [ ] Add App Check for API protection
- [ ] Enable email verification
- [ ] Set up backup encryption
- [ ] Configure backup retention policies
- [ ] Add Firebase Analytics (optional)
- [ ] Set up Cloud Functions for automation (optional)

---

## Support

**Firebase Console**: https://console.firebase.google.com/
**FlutterFire Docs**: https://firebase.flutter.dev/
**Firestore Docs**: https://firebase.google.com/docs/firestore
