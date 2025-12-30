# PropLedger - Development TODO List

> **Current Stage**: MVP  
> **Version**: 1.1.0  
> **Last Updated**: 2024-12-30

---

## Phase 1: Foundation & Setup

### Project Setup
- [ ] Initialize Flutter project with proper package name
- [ ] Configure Android build settings (minSdk, targetSdk)
- [ ] Set up development, staging, production environments
- [ ] Configure `.env` file structure
- [ ] Add required dependencies to `pubspec.yaml`
  - [ ] State management (Riverpod/Bloc)
  - [ ] dio (HTTP client)
  - [ ] flutter_secure_storage
  - [ ] drift (SQLite ORM)
  - [ ] path_provider
  - [ ] intl (internationalization)

### Firebase Backend
- [ ] Create Firebase project at console.firebase.google.com
- [ ] Add Android app to Firebase project
- [ ] Download and configure google-services.json
- [ ] Enable Firebase Authentication (Email/Password)
- [ ] Enable Cloud Firestore
- [ ] Configure Firestore security rules
- [ ] Set up automated backups (Firestore export)
- [ ] Enable Firebase Cloud Messaging (FCM) for notifications

### Authentication System
- [ ] Implement Firebase Auth integration
- [ ] Create login screen UI
- [ ] Implement secure token storage (flutter_secure_storage)
- [ ] Add token refresh logic with Firebase Auth
- [ ] Build logout functionality
- [ ] Add biometric authentication (optional)
- [ ] Handle auth state management with Firebase Auth streams

---

## Phase 2: Core Data Models & Local Storage ✅ COMPLETED

### Data Models
- [x] Define Property model
- [x] Define Unit model (with nullable propertyId, upkeepAmount)
- [x] Define Tenant model (with LeaseTerm enum)
- [x] Define RentPayment model (with PaymentStatus enum)
- [x] Define Expense model
- [x] Define MaintenanceTask model (with TaskPriority, TaskStatus enums)
- [x] Define Loan model (with nullable propertyId, unitId)
- [x] Define LoanPayment model
- [x] Define Document model (with LinkedType enum)
- [x] Add JSON serialization for all models
- [x] Add validation logic to models

### Local Database (Drift)
- [x] Set up Drift database configuration
- [x] Create Property table
- [x] Create Unit table (with upkeepAmount, nullable propertyId)
- [x] Create Tenant table (with leaseTerm)
- [x] Create RentPayment table
- [x] Create Expense table
- [x] Create MaintenanceTask table
- [x] Create Loan table (with nullable propertyId, unitId)
- [x] Create LoanPayment table
- [x] Create Document table
- [x] Create SyncQueue table (for offline changes)
- [x] Implement DAOs for all entities (all tables created)
- [x] Add database migrations strategy (v1 → v2)

### Firestore Collections
- [ ] Create Property collection
- [ ] Create Unit collection (subcollection or top-level with property reference)
- [ ] Create Tenant collection with unit reference
- [ ] Create RentPayment collection
- [ ] Create Expense collection
- [ ] Create MaintenanceTask collection
- [ ] Create Loan collection
- [ ] Create LoanPayment collection
- [ ] Create Document collection with Cloud Storage references
- [ ] Configure Firestore security rules (auth, validation)
- [ ] Set up cascade delete with Cloud Functions
- [ ] Test all CRUD operations via Firebase Console

---

## Phase 3: Repository Layer ✅ PARTIALLY COMPLETED

### Repository Pattern Implementation
- [x] Create base repository interface
- [x] Implement PropertyRepository
  - [x] CRUD operations (local)
  - [ ] Sync logic (Firebase - future)
- [x] Implement UnitRepository
- [x] Implement TenantRepository (with unit status updates)
- [x] Implement RentPaymentRepository
- [x] Implement ExpenseRepository (with property filtering, total expenses)
- [x] Implement MaintenanceTaskRepository (with status filtering, overdue tasks)
- [x] Implement LoanRepository
- [x] Implement LoanPaymentRepository (with loan totals, payment history)
- [x] Implement DocumentRepository (with expiry tracking, linked entity filtering)
- [ ] Create SyncService for background sync (Firebase - future)
- [ ] Implement conflict resolution strategy (future)
- [ ] Add retry logic with exponential backoff (future)

**Note**: Local-only repositories completed. Firebase sync implementation deferred.

---

## Phase 4: Properties & Units Feature ✅ COMPLETED

### UI Screens
- [x] Property list screen
- [x] Property detail screen with tabs
- [x] Add/Edit property form
- [x] Unit list (within property detail tabs)
- [x] Add/Edit unit form (dialog)
- [x] Unit detail view (within units tab)
- [x] Standalone units support (nullable propertyId)

### Business Logic
- [x] Property CRUD operations
- [x] Unit CRUD operations
- [x] Link units to properties (optional)
- [x] Update unit occupancy status (vacant/occupied)
- [x] Unit upkeep amount tracking
- [x] Validate property/unit data
- [ ] Calculate property value and equity (future)

### Testing
- [x] Manual test: Create property
- [x] Manual test: Add units to property
- [x] Manual test: Edit property details
- [x] Manual test: Delete property
- [x] Test unit occupancy status updates
- [x] Test standalone units (no property)
- [ ] Test offline CRUD operations (local-only mode)
- [ ] Test sync after offline changes (Firebase - future)

---

## Phase 5: Tenants & Leases Feature ✅ COMPLETED

### UI Screens
- [x] Tenant list screen (with unit filter)
- [x] Tenant detail screen
- [x] Add/Edit tenant form with lease term selector
- [x] Lease information view (start, end, duration, term)
- [ ] End lease flow (manual deletion for now)

### Business Logic
- [x] Tenant CRUD operations
- [x] Link tenant to unit
- [x] Auto-update unit status when tenant assigned (vacant → occupied)
- [x] Auto-update unit status when tenant deleted (occupied → vacant)
- [x] Calculate lease duration
- [x] Lease term support (monthly/annually)
- [x] Provider invalidation for real-time UI updates
- [ ] Flag expiring leases (< 60 days) (future)
- [ ] Handle lease end and unit vacancy (future automation)

### Testing
- [x] Manual test: Add tenant to unit
- [x] Manual test: View tenant details
- [x] Manual test: Edit tenant
- [x] Manual test: Delete tenant
- [x] Verify unit status changes (create/delete tenant)
- [x] Test lease term selection (monthly/annually)
- [x] Test real-time unit status updates

---

## Phase 6: Rent Payments Feature ✅ COMPLETED (v1.1.0)

### UI Screens
- [x] Rent payment list screen with filtering
- [x] Add/Edit rent payment form
- [x] Payment history per tenant
- [x] Outstanding rent view with filters (All, Outstanding, Late, Paid)
- [x] Dashboard cards (Outstanding Rent, Upcoming Payments)
- [x] Real-time UI updates across all screens

### Business Logic
- [x] Record rent payment
- [x] Calculate outstanding/late rent
- [x] Flag late payments (overdue > 1 day)
- [x] Auto-generate recurring payments based on lease terms (monthly/annually)
- [x] Payment generator service with one-time setup
- [x] Late payment interest calculation (5% daily, max 25%)
- [x] Link payments to tenant and unit
- [x] Calculate total income
- [x] Real-time provider invalidation for instant updates

### Enhancements
- [x] Standalone units (nullable propertyId)
- [x] Unit-level loans (nullable unitId in loans)
- [x] Lease term types (monthly/annually)
- [x] Unit upkeep amount field
- [x] Database migration strategy (v1 → v2)

### Testing
- [x] Manual test: Record payment
- [x] Manual test: View outstanding rent
- [x] Verify late payment flagging
- [x] Test payment history display
- [x] Test auto-generation on tenant create/update
- [x] Test dashboard real-time updates
- [x] Test payment filtering
- [x] Verify type safety (orElse null returns)

---

## Phase 7: Expenses Feature ✅ COMPLETED

### UI Screens
- [x] Expense list screen with filtering
- [x] Add/Edit expense form with autocomplete categories
- [x] Expense cards showing property, amount, category
- [x] Filter by category, property, date range
- [x] Total expenses summary card
- [x] Quick action integration in dashboard

### Business Logic
- [x] Expense CRUD operations (ExpenseRepository)
- [x] Link expense to property or unit (optional unit)
- [x] Handle recurring expenses (toggle flag)
- [x] Calculate total expenses
- [x] Category management (common categories + custom)
- [x] ExpensesNotifier with Riverpod state management
- [x] Filter helpers (by property, category, date range)
- [ ] Upload receipt to Firebase Storage (future)

### Testing
- [x] Manual test: Log expense
- [x] Manual test: View expense history
- [x] Manual test: Filter by property/category/date
- [x] Manual test: Edit and delete expense
- [x] Manual test: Recurring expense flag
- [ ] Test file upload/download (future - Firebase Storage)

---

## Phase 8: Maintenance Feature ✅ COMPLETED

### UI Screens
- [x] Maintenance task list with filtering
- [x] Add/Edit task form with priority and status
- [x] Task cards showing status, priority, due date
- [x] Filter by status, priority, property
- [x] Overdue task highlighting
- [x] Quick action integration in dashboard

### Business Logic
- [x] MaintenanceTask CRUD operations (MaintenanceTaskRepository)
- [x] Update task status (open, in progress, done)
- [x] Link to property or unit (optional unit)
- [x] Record actual cost when complete
- [x] Flag overdue tasks (isOverdue computed property)
- [x] MaintenanceNotifier with Riverpod state management
- [x] Filter helpers (by property, status, priority)
- [x] Priority levels (low, medium, high) with color coding
- [ ] Attach photos (future - Firebase Storage)

### Testing
- [x] Manual test: Create task
- [x] Manual test: Update status
- [x] Manual test: Mark as complete with cost
- [x] Manual test: Filter by property/status/priority
- [x] Verify overdue highlighting
- [x] Manual test: Edit and delete task

---

## Phase 9: Loans Feature

### UI Screens
- [ ] Loan list per property
- [ ] Add/Edit loan form
- [ ] Loan detail view
- [ ] Loan payment history
- [ ] Record loan payment form

### Business Logic
- [ ] Loan CRUD operations
- [ ] Link loan to property
- [ ] Record loan payment
- [ ] Calculate principal vs interest
- [ ] Update remaining balance
- [ ] Calculate total interest paid
- [ ] Estimate payoff date

### Testing
- [ ] Manual test: Add loan
- [ ] Manual test: Record payment
- [ ] Verify balance calculations
- [ ] Test payment history

---

## Phase 10: Documents Feature

### UI Screens
- [ ] Document list (grouped by type)
- [ ] Upload document form
- [ ] Document viewer (PDF/image)
- [ ] Expiring documents view

### Business Logic
- [ ] Upload document to PocketBase
- [ ] Link to property, unit, or tenant
- [ ] Set document type and expiry
- [ ] Flag expiring documents (< 30 days)
- [ ] Download and view documents
- [ ] Delete documents

### Testing
- [ ] Manual test: Upload PDF
- [ ] Manual test: Upload image
- [ ] Manual test: View document
- [ ] Test expiry alerts

---

## Phase 11: Dashboard & Reports

### Dashboard UI
- [x] Dashboard screen with KPI cards
- [x] Outstanding rent summary (card with real-time updates)
- [x] Upcoming payments card (next 30 days)
- [x] Quick actions grid (2-column layout)
- [ ] Upcoming lease expiries widget
- [ ] Monthly cash flow chart
- [ ] Open maintenance tasks count
- [ ] Recent activity feed

### Analytics & Reports
- [ ] Calculate total portfolio value
- [ ] Calculate total equity
- [ ] Calculate occupancy rate
- [ ] Monthly cash flow calculation
- [ ] YTD income and expenses
- [ ] Property financial snapshot
- [ ] Portfolio overview report

### Testing
- [ ] Verify all dashboard metrics
- [ ] Test with empty state
- [ ] Test with realistic data
- [ ] Verify calculations

---

## Phase 12: Settings & Configuration

### UI Screens
- [ ] Settings screen
- [ ] Profile/account settings
- [ ] App preferences
- [ ] About screen

### Features
- [ ] Currency selection
- [ ] Date format preference
- [ ] Biometric toggle
- [ ] Manual sync trigger
- [ ] View last sync time
- [ ] Theme selection (light/dark)
- [ ] Clear cache option

### Testing
- [ ] Test all settings persist
- [ ] Test manual sync
- [ ] Verify currency formatting

---

## Phase 13: Sync & Offline Handling

### Sync Service
- [ ] Implement background sync worker
- [ ] Queue offline changes
- [ ] Sync on connectivity restore
- [ ] Handle sync conflicts (last-write-wins)
- [ ] Retry failed syncs
- [ ] Show sync status indicator

### Offline Support
- [ ] Test all CRUD operations offline
- [ ] Verify sync queue persistence
- [ ] Test conflict scenarios
- [ ] Ensure UI works without network

### Testing
- [ ] Test offline CRUD for all entities
- [ ] Test sync after prolonged offline
- [ ] Test conflict resolution
- [ ] Verify data integrity

---

## Phase 14: Error Handling & Edge Cases

### Error States
- [ ] Network error handling
- [ ] Auth token expiry handling
- [ ] Form validation errors
- [ ] File upload errors
- [ ] Database errors
- [ ] Sync errors

### Empty States
- [ ] Empty property list
- [ ] Empty tenant list
- [ ] No outstanding rent
- [ ] No expenses
- [ ] No maintenance tasks
- [ ] Empty dashboard

### Testing
- [ ] Test all error scenarios
- [ ] Test all empty states
- [ ] Verify error messages are user-friendly

---

## Phase 15: UI/UX Polish

### UI Improvements
- [ ] Consistent spacing and alignment
- [ ] Loading indicators
- [ ] Pull-to-refresh on lists
- [ ] Smooth animations
- [ ] Material 3 design compliance
- [ ] Accessibility (screen readers)

### UX Enhancements
- [ ] Form auto-focus
- [ ] Smart defaults (today's date)
- [ ] Confirmation dialogs for delete
- [ ] Success toast messages
- [ ] Quick action buttons
- [ ] Search functionality

---

## Phase 16: Testing & Quality Assurance

### Manual Testing
- [ ] Complete auth flow test
- [ ] Test all CRUD operations
- [ ] Test offline scenarios
- [ ] Test sync behavior
- [ ] Test all navigation paths
- [ ] Test edge cases

### Performance Testing
- [ ] Test with 100+ properties
- [ ] Test with 1000+ records
- [ ] Measure cold start time
- [ ] Verify 60fps scrolling
- [ ] Test database query speed

### Security Testing
- [ ] Verify HTTPS enforcement
- [ ] Test token expiry handling
- [ ] Verify secure storage
- [ ] Check for sensitive data in logs

---

## Phase 17: Build & Deployment

### Android Build
- [ ] Generate signing keystore
- [ ] Configure `key.properties`
- [ ] Update `build.gradle` for release
- [ ] Set app version and build number
- [ ] Build release APK
- [ ] Test release build on device

### Deployment Preparation
- [ ] Write deployment instructions
- [ ] Document PocketBase setup
- [ ] Create user manual (optional)
- [ ] Prepare backup/restore guide

### Distribution
- [ ] Distribute APK to user
- [ ] Set up update mechanism (manual or via store)

---

## Future Enhancements (Post-MVP)

- [ ] Push notifications for rent due/lease expiry
- [ ] Export reports to PDF/CSV
- [ ] Multi-currency support
- [ ] Recurring rent auto-generation
- [ ] Tenant portal (separate app)
- [ ] Bank account integration
- [ ] Automated accounting sync
- [ ] iOS version
- [ ] Web dashboard

---

## Notes

- Prioritize offline functionality throughout development
- Keep UI simple and fast
- Manual testing is sufficient for MVP
- Document all PocketBase collection configurations
- Maintain changelog for major updates
