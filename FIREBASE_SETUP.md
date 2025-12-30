# Firebase Setup Guide for PropLedger

## Overview
PropLedger now supports Firebase Authentication for secure user management and biometric authentication for app security.

---

## Firebase Configuration

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add an Android app to your project

### 2. Download google-services.json
1. In Firebase Console → Project Settings → Your Apps
2. Download `google-services.json`
3. Place it in: `android/app/google-services.json`

### 3. Enable Authentication Methods
1. In Firebase Console → Authentication → Sign-in method
2. Enable **Email/Password** provider
3. (Optional) Enable other providers as needed

### 4. Firestore Database (Optional)
1. In Firebase Console → Firestore Database
2. Create database in production or test mode
3. Set up security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Authenticated users can read/write their property data
    match /properties/{propertyId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Biometric Authentication

### Device Requirements
- **Android 6.0+** (API 23+) for fingerprint
- **Android 10+** (API 29+) for BiometricPrompt
- Device must have biometric hardware enrolled

### How It Works
1. User enables biometric in Settings → Security
2. App locks after 5 minutes of inactivity
3. User must authenticate with fingerprint/face to unlock
4. Authentication state persists in secure storage

### Testing Biometrics
- **Physical Device**: Use actual fingerprint/face ID
- **Emulator**: Configure virtual fingerprint in emulator settings

---

## User Flow

### First Time User
1. App shows **Login Screen**
2. User taps "Sign Up"
3. Enters name, email, password
4. Account created in Firebase
5. Redirected to **Dashboard**

### Returning User
1. App checks Firebase auth state
2. If authenticated → **Dashboard**
3. If not → **Login Screen**

### With Biometric Enabled
1. User authenticated with Firebase
2. If app inactive >5 min → **Biometric Lock Screen**
3. User authenticates with fingerprint/face
4. Access granted to **Dashboard**

---

## Settings Configuration

### Enable Biometric Lock
1. Navigate to **Settings** → **Security**
2. Toggle "Biometric Authentication"
3. System prompts for fingerprint/face verification
4. Once verified, biometric lock is active

### Disable Biometric Lock
1. Navigate to **Settings** → **Security**
2. Toggle off "Biometric Authentication"
3. App will no longer lock

### Sign Out
1. Navigate to **Settings** → **Security**
2. Tap "Sign Out"
3. Confirm action
4. Redirected to **Login Screen**

---

## Local-Only Mode

**Firebase is optional!** The app works without Firebase:
- Local database (Drift) stores all data
- No cloud sync
- No authentication required
- App starts directly on Dashboard

To run without Firebase:
1. Don't add `google-services.json`
2. App detects missing Firebase and runs locally
3. All features work except authentication

---

## Troubleshooting

### Firebase Initialization Failed
**Symptom:** App shows "Firebase initialization skipped"
**Solution:** Add `google-services.json` to `android/app/`

### Biometric Not Available
**Symptom:** Toggle is disabled in Settings
**Cause:** Device doesn't support or hasn't enrolled biometrics
**Solution:** Enroll fingerprint/face in device Settings

### Authentication Errors
**Common Issues:**
- `user-not-found`: No account with that email
- `wrong-password`: Incorrect password
- `email-already-in-use`: Email already registered
- `weak-password`: Password must be 6+ characters
- `network-request-failed`: Check internet connection

### Biometric Lock Not Working
**Checks:**
1. Is biometric enabled in app Settings?
2. Is fingerprint/face enrolled on device?
3. Has 5 minutes passed since last auth?

---

## Security Best Practices

### Production Setup
1. ✅ Use Firebase security rules
2. ✅ Enable App Check for API protection
3. ✅ Set up email verification
4. ✅ Configure password policies
5. ✅ Enable 2FA for admin accounts

### Data Protection
- User data stored in Firestore (optional)
- Local data encrypted with Drift
- Auth tokens in secure storage
- Biometric data never leaves device

---

## Development vs Production

### Development
- Use Firebase test mode
- Keep debug logging enabled
- Test with emulator + real device

### Production
- Switch to production Firestore rules
- Disable debug logs
- Test thoroughly on multiple devices
- Monitor Firebase Console for errors

---

## Next Steps

1. **Test Authentication**
   - Create test account
   - Sign in/out flows
   - Password reset

2. **Test Biometrics**
   - Enable on physical device
   - Verify auto-lock after 5 min
   - Test unlock flow

3. **Optional: Firebase Features**
   - Cloud Firestore sync
   - Firebase Storage for documents
   - Cloud Messaging for notifications

---

## Support

For Firebase issues, check:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

For Biometric issues, check:
- [local_auth package](https://pub.dev/packages/local_auth)
- Android Biometric API docs
