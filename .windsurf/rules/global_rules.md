---
trigger: always_on
---
# Windsurf IDE — Global Rules (Flutter + PocketBase + Firebase)

---

## trigger: always_on

This document extends the Windsurf Global Rules to cover **Flutter (Android)**, **PocketBase**, and **Firebase (future)** for the Rental Portfolio App.

---

## 1. Task Analysis Template (Mobile)

```markdown
## Task Analysis
- Purpose: [What feature or change is being built]
- Platform: Android (Flutter)
- Backend Dependency: PocketBase | Firebase | None
- Offline Impact: [Yes/No]
- Data Models Affected: [Collections / Tables]
- Security Considerations: [Auth, storage, tokens]
- Quality Standards: [Performance, UX, stability]
```

---

## 2. Implementation Plan Template (Flutter)

```markdown
## Implementation Plan
1. UI Layer
   - Screens / Widgets affected
   - Navigation changes
   - State management updates

2. State & Logic
   - Riverpod/Bloc providers
   - Business logic changes
   - Validation rules

3. Data Layer
   - PocketBase/Firebase calls
   - Local DB updates (Drift)
   - Sync considerations

4. Verification
   - Manual test cases
   - Edge cases
   - Offline scenarios
```

---

## 3. Flutter-Specific Rules

### Core

* Flutter stable channel only
* Android-only configuration
* Material 3 UI
* Null safety enforced

### State Management

* Choose **one**: Riverpod *or* Bloc
* No mixed paradigms
* Business logic must not live in widgets

### Project Structure

```
lib/
├── app/              # App-level config
├── core/             # Constants, theming, utils
├── data/
│   ├── models/       # Data models
│   ├── repositories/ # PB/Firebase abstractions
│   └── local/        # Drift DB
├── features/
│   ├── dashboard/
│   ├── properties/
│   ├── loans/
│   └── ...
├── routing/
└── main.dart
```

### Quality

* No business logic in UI widgets
* Explicit loading & error states
* Defensive null handling

---

## 4. PocketBase Rules

### Usage

* REST API only
* No direct schema mutations from app
* All collections defined server-side

### Authentication

* Single-user model
* Token stored securely (flutter_secure_storage)
* Token refresh handled explicitly

### Data Access

* Repository pattern mandatory
* No direct HTTP calls from UI/state layers
* Explicit error mapping (network, auth, validation)

### Files

* Use PocketBase file storage
* Always validate file size and type client-side

---

## 5. Offline & Sync Rules

* Local DB (Drift) is source of truth for UI
* PocketBase is sync source
* Write-through caching model
* Manual conflict resolution (last-write-wins)

No background sync automation without explicit approval.

---

## 6. Firebase (Future Integration Rules)

### Allowed Firebase Services

* Firebase Authentication
* Cloud Functions
* Cloud Messaging (FCM)
* Analytics (optional)

### Migration Rules

* PocketBase remains primary datastore
* Firebase Auth may replace PB auth
* No Firestore unless explicitly approved

### Messaging

* Push notifications only for:

  * Rent due
  * Lease expiry
  * Loan payment reminders

---

## 7. Security Rules (Mobile)

* All secrets via environment configs
* No API keys committed
* Secure storage for tokens
* HTTPS enforced
* No plaintext PII in logs

---

## 8. Quality Management (Mobile)

### Code Quality

* Dart analyzer clean
* No unused imports
* Consistent naming

### Performance

* Avoid unnecessary rebuilds
* Use const constructors where possible
* Paginate lists by default

### UX

* One primary action per screen
* Empty states are mandatory
* Error messages must be actionable

---

## 9. Stage Rules (Mobile Adaptation)

### QUICK_PROTOTYPE

* Minimal UI
* Local-only data allowed
* No offline guarantees

### POC

* PocketBase integration required
* Manual test checklist

### MVP

* Offline support required
* Secure auth storage
* Crash-free flows

### ENTERPRISE / SAAS

* Not applicable unless multi-user or commercialized

---

## 10. Error Handling Protocol (Flutter)

1. Identify

   * UI error
   * Network error
   * Data inconsistency

2. Handle

   * User-visible message
   * Logged technical detail

3. Verify

   * Retry behavior
   * Offline fallback

4. Document

   * Cause
   * Fix
   * Prevention

---

## 11. Non-Negotiables

* No silent failures
* No magic automation
* Manual correctness > smart guesses
* Clarity over cleverness

