# Firebase Setup Guide

This guide walks you through setting up Firebase for the PropLedger app.

---

## 1. Create Firebase Project

### Step 1: Go to Firebase Console
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Click **Add project**
3. Enter project name: `PropLedger` (or your preferred name)
4. Disable Google Analytics (optional for personal project)
5. Click **Create project**

---

## 2. Add Android App to Firebase

### Step 1: Register Your App
1. In Firebase Console, click **Add app** → Select **Android**
2. **Android package name**: `com.propledger.app` (or match your app's package name)
   - Find in `android/app/build.gradle` → `applicationId`
3. **App nickname**: `PropLedger Android` (optional)
4. **Debug signing certificate SHA-1**: Leave blank for now (optional for testing)
5. Click **Register app**

### Step 2: Download Configuration File
1. Download `google-services.json`
2. Place file in: `android/app/google-services.json`
3. **IMPORTANT**: Add to `.gitignore` to keep credentials secure

### Step 3: Add Firebase SDK
Firebase dependencies are already added to `pubspec.yaml`. No manual configuration needed.

### Step 4: Modify Android Build Files
**Already configured in project**, but verify:

**android/build.gradle** (project-level):
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle**:
```gradle
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}
```

---

## 3. Enable Firebase Services

### Authentication
1. In Firebase Console → **Authentication** → **Get started**
2. Click **Sign-in method** tab
3. Enable **Email/Password**
4. Click **Save**

### Firestore Database
1. In Firebase Console → **Firestore Database** → **Create database**
2. Choose **Start in test mode** (for development)
3. Select location: closest to your region
4. Click **Enable**

### Security Rules (Important!)
After creating Firestore, update security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**For production**, restrict rules per collection:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Properties - only owner can access
    match /properties/{propertyId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // Units - only owner can access
    match /units/{unitId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // Tenants - only owner can access
    match /tenants/{tenantId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // Rent Payments - only owner can access
    match /rentPayments/{paymentId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
    
    // Loans - only owner can access
    match /loans/{loanId} {
      allow read, write: if request.auth != null 
        && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Cloud Storage (Optional - for receipts/documents)
1. In Firebase Console → **Storage** → **Get started**
2. Choose **Start in test mode**
3. Click **Next** → **Done**

### Cloud Messaging (Optional - for notifications)
1. In Firebase Console → **Cloud Messaging**
2. No setup needed, FCM is automatically enabled

---

## 4. Create Test User

### Via Firebase Console
1. Go to **Authentication** → **Users** tab
2. Click **Add user**
3. Enter:
   - **Email**: `test@propledger.com`
   - **Password**: `test123456`
4. Click **Add user**

### Via App (Once running)
Use the sign-up screen in the app to create a user.

---

## 5. Configure App

### Environment Variables (Optional)
Create `.env` file in project root for emulator testing:
```
USE_FIREBASE_EMULATOR=false
FIRESTORE_EMULATOR_HOST=localhost
FIRESTORE_EMULATOR_PORT=8080
```

### Update .gitignore
Ensure these lines exist in `.gitignore`:
```
# Firebase
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
.env
firebase-debug.log
firestore-debug.log
```

---

## 6. Run the App

### Install Dependencies
```bash
flutter pub get
```

### Run on Android Device/Emulator
```bash
flutter run
```

### First Launch
1. App will connect to Firebase automatically
2. Sign in with test user: `test@propledger.com` / `test123456`
3. Or create new account via sign-up screen

---

## 7. Verify Firebase Connection

### Check Authentication
1. Sign in via app
2. Go to Firebase Console → **Authentication** → **Users**
3. Verify user appears in list

### Check Firestore
1. Create a property in the app
2. Go to Firebase Console → **Firestore Database**
3. Verify `properties` collection exists with document

---

## 8. Firebase Emulator (Optional - Local Development)

For offline development without cloud Firebase:

### Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Login to Firebase
```bash
firebase login
```

### Initialize Firebase Emulators
```bash
cd <project-root>
firebase init emulators
```

Select:
- Authentication Emulator
- Firestore Emulator
- Storage Emulator

### Start Emulators
```bash
firebase emulators:start
```

### Configure App for Emulator
Update `.env`:
```
USE_FIREBASE_EMULATOR=true
FIRESTORE_EMULATOR_HOST=10.0.2.2  # For Android emulator
FIRESTORE_EMULATOR_PORT=8080
```

---

## 9. Firestore Collections

The app uses these collections:

| Collection | Purpose |
|------------|---------|
| `users` | User profiles |
| `properties` | Property records |
| `units` | Unit records |
| `tenants` | Tenant records |
| `rentPayments` | Rent payment records |
| `loans` | Loan records |
| `expenses` | Expense records (future) |
| `maintenanceTasks` | Maintenance tasks (future) |
| `documents` | Document metadata (future) |

**Note**: Collections are auto-created when first document is added.

---

## 10. Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### "FirebaseException: PERMISSION_DENIED"
- Check Firestore security rules in Firebase Console
- Ensure user is authenticated
- Verify rules allow authenticated access

### "Network error"
- Check internet connection
- Verify Firebase project is active
- Check if Firebase services are enabled

### "google-services.json not found"
- Download from Firebase Console → Project Settings → Your apps
- Place in `android/app/` directory
- Rebuild app

---

## 11. Production Checklist

Before releasing to production:

- [ ] Update Firestore security rules (restrict by userId)
- [ ] Enable App Check for additional security
- [ ] Set up Cloud Functions for cascade deletes
- [ ] Configure automated Firestore backups
- [ ] Set up Firebase Performance Monitoring
- [ ] Enable Crashlytics for crash reporting
- [ ] Review and optimize Firebase usage (billing)
- [ ] Add proper error tracking and logging
- [ ] Test all features with production Firebase project
- [ ] Document backup and restore procedures

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Console](https://console.firebase.google.com)
