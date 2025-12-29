# PropLedger Testing Guide

## Prerequisites

1. **Flutter installed** ✓ (You have 3.29.2)
2. **Android Studio installed** ✓
3. **Android emulator or physical device**

## Quick Start Testing (Without PocketBase)

The app will work in **offline mode** without PocketBase backend. You can test all CRUD operations locally.

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

Since PocketBase is not configured, the login will fail. To test the app features without authentication:

**Temporary Testing Workaround:**
1. The app will show login screen
2. Login will fail (expected - no backend yet)
3. For now, you can test the UI structure

## Full Testing (With PocketBase)

For complete testing with authentication and sync:

### Step 1: Set Up PocketBase

**Download PocketBase:**
```bash
# Download from https://github.com/pocketbase/pocketbase/releases
# Extract pocketbase.exe to a folder
# Or use the quick download:
```

**Run PocketBase:**
```bash
# Navigate to PocketBase folder
cd path\to\pocketbase

# Start PocketBase
.\pocketbase.exe serve
```

PocketBase will start on `http://127.0.0.1:8090`

### Step 2: Configure PocketBase

1. Open browser: `http://127.0.0.1:8090/_/`
2. Create admin account
3. Go to Settings → Collections
4. Create collections as per `docs/POCKETBASE_SETUP.md`

### Step 3: Create Test User

1. In PocketBase admin: Collections → users
2. Click "New record"
3. Add:
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

### "Unable to connect to PocketBase"
- Check PocketBase is running: `http://127.0.0.1:8090`
- For emulator, URL should be `http://10.0.2.2:8090`
- For physical device, use your computer's IP address

### "Authentication failed"
- Verify user exists in PocketBase admin
- Check email/password are correct
- Ensure users collection exists

### App crashes on startup
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild: `flutter run`

### Changes not syncing
- Check PocketBase is running
- View sync queue in local database
- Check PocketBase logs for errors

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
- `docs/POCKETBASE_SETUP.md` - Detailed backend setup
- `docs/TODO.md` - Development roadmap
