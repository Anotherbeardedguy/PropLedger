# PropLedger Testing Guide

## Prerequisites

1. **Flutter installed** ✓ (You have 3.29.2)
2. **Android Studio installed** ✓
3. **Android emulator or physical device**

## Quick Start Testing (Without Firebase)

The app currently works in **offline mode** without Firebase backend. You can test all CRUD operations locally using the Drift SQLite database.

### Step 1: Start Android Emulator

**Option A - Via Android Studio:**
1. Open Android Studio
2. Go to `Tools > Device Manager`
3. Create a new virtual device (if none exists)
4. Click the ▶️ play button to start the emulator

**Option B - Via Command Line:**
```bash
# List available emulators
emulator -list-avds

# Start an emulator
emulator -avd <emulator_name>
```

### Step 2: Run the App

```bash
cd C:\git\PropLedger

# Check connected devices
flutter devices

# Run the app
flutter run
```

The app will:
- Install on the emulator
- Start automatically
- Open to the login screen

### Step 3: Test Without Backend (Offline Mode)

Since Firebase is not configured yet, the login will fail. To test the app features without authentication:

**Temporary Testing Workaround:**
1. The app will show login screen
2. Login will fail (expected - no backend yet)
3. For now, you can test the UI structure

## Full Testing (With Firebase)

For complete testing with authentication and sync:

### Step 1: Set Up Firebase

Follow the comprehensive guide in `docs/FIREBASE_SETUP.md`:

1. Create Firebase project at https://console.firebase.google.com
2. Add Android app to project
3. Download `google-services.json` to `android/app/`
4. Enable Firebase Authentication (Email/Password)
5. Enable Cloud Firestore
6. Configure Firestore security rules

### Step 2: Create Test User

**Option 1: Via Firebase Console**
1. Go to Firebase Console → Authentication → Users
2. Click "Add user"
3. Enter:
   - Email: `test@propledger.com`
   - Password: `test123456`
4. Save

### Step 4: Run App with Backend

```bash
# The app is already configured for localhost
# Default: http://10.0.2.2:8090 (Android emulator's localhost alias)

flutter run
```

### Step 5: Login and Test

1. **Login:**
   - Email: `test@propledger.com`
   - Password: `test123456`

2. **Test Properties:**
   - Click "Properties" card on dashboard
   - Add a property (e.g., "Sunset Apartments", "123 Main St")
   - View property details
   - Edit property
   - Add units to property

3. **Test Units:**
   - Open a property
   - Go to "Units" tab
   - Add unit (e.g., "Unit 101", Rent: $1500)
   - Change unit status (Vacant/Occupied)
   - Edit/delete units

## Testing Offline Features

1. **Create data while online:**
   - Add properties and units with PocketBase running
   
2. **Stop PocketBase:**
   ```bash
   # Stop the PocketBase server
   Ctrl+C
   ```

3. **Continue using app:**
   - All data still accessible (local SQLite)
   - Create/edit/delete still works
   - Changes queued in sync queue

4. **Restart PocketBase:**
   - Data will sync automatically
   - Check PocketBase admin to verify sync

## What to Test

### ✅ Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should fail)
- [ ] Logout
- [ ] Token refresh on app restart

### ✅ Properties
- [ ] View empty state
- [ ] Add new property
- [ ] Edit property
- [ ] Delete property (with confirmation)
- [ ] View property details
- [ ] Navigate between screens
- [ ] Pull to refresh

### ✅ Units
- [ ] Add unit to property
- [ ] Edit unit
- [ ] Delete unit
- [ ] Change unit status (Vacant/Occupied)
- [ ] View units list
- [ ] Empty state when no units

### ✅ Offline Mode
- [ ] App works without internet
- [ ] CRUD operations save locally
- [ ] Data persists after app restart
- [ ] Sync works when backend available

### ✅ UI/UX
- [ ] Loading states show correctly
- [ ] Error messages are clear
- [ ] Success feedback (snackbars)
- [ ] Smooth navigation
- [ ] Forms validate properly
- [ ] Empty states are helpful

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean && flutter pub get`
- Rebuild the app

### "FirebaseException: PERMISSION_DENIED"
- Check Firestore security rules in Firebase Console
- Ensure user is authenticated
- Verify rules allow authenticated access

### "Authentication failed"
- Verify user exists in Firebase Console → Authentication
- Check email/password are correct
- Ensure Firebase Auth is enabled

### App crashes on startup
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild: `flutter run`

### Changes not syncing
- Check internet connection
- View sync queue in local database (when implemented)
- Check Firebase Console for service status
- Verify Firestore security rules allow write access

## Build for Testing

### Debug Build (APK)
```bash
flutter build apk --debug
```
APK location: `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build
```bash
flutter build apk --release
```

## Testing Tools

### View Local Database
Use a SQLite browser to inspect:
- Location: App's documents directory
- File: `propledger.db`
- Tables: properties, units, tenants, etc.

### View Logs
```bash
# While app is running
flutter logs

# Or in Android Studio
View > Tool Windows > Logcat
```

## Next Steps After Testing

1. Report any bugs or issues
2. Test additional features as they're added
3. Verify sync behavior
4. Test on physical device
5. Performance testing with larger datasets

## Quick Demo Data

Once logged in, you can quickly add test data:

**Property 1:**
- Name: Sunset Apartments
- Address: 123 Main Street, Springfield
- Purchase Price: $500,000
- Estimated Value: $600,000

**Units for Sunset Apartments:**
- Unit 101: 2 rooms, $1,200/mo, Occupied
- Unit 102: 1 room, $950/mo, Vacant
- Unit 201: 2 rooms, $1,250/mo, Occupied

**Property 2:**
- Name: Downtown Plaza
- Address: 456 Oak Avenue, Metropolis
- Purchase Price: $750,000

---

**Happy Testing! 🎉**

For issues or questions, check:
- `README.md` - Project overview
- `docs/FIREBASE_SETUP.md` - Detailed Firebase setup guide
- `docs/TODO.md` - Development roadmap
