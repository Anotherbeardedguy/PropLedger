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

### PocketBase Backend
- [ ] Set up PocketBase instance (local or VPS)
- [ ] Create admin account
- [ ] Configure HTTPS/SSL certificate
- [ ] Set up automated daily backups
- [ ] Document PocketBase URL and credentials

### Authentication System
- [ ] Define user collection in PocketBase
- [ ] Implement PocketBase auth API integration
- [ ] Create login screen UI
- [ ] Implement JWT token storage (secure_storage)
- [ ] Add token refresh logic
- [ ] Build logout functionality
- [ ] Add biometric authentication (optional)
- [ ] Handle auth state management

---

## Phase 2: Core Data Models & Local Storage

### Data Models
- [ ] Define Property model
- [ ] Define Unit model
- [ ] Define Tenant model
- [ ] Define RentPayment model
- [ ] Define Expense model
- [ ] Define MaintenanceTask model
- [ ] Define Loan model
- [ ] Define LoanPayment model
- [ ] Define Document model
- [ ] Add JSON serialization for all models
- [ ] Add validation logic to models

### Local Database (Drift)
- [ ] Set up Drift database configuration
- [ ] Create Property table
- [ ] Create Unit table
- [ ] Create Tenant table
- [ ] Create RentPayment table
- [ ] Create Expense table
- [ ] Create MaintenanceTask table
- [ ] Create Loan table
- [ ] Create LoanPayment table
- [ ] Create Document table
- [ ] Create SyncQueue table (for offline changes)
- [ ] Implement DAOs for all entities
- [ ] Add database migrations strategy

### PocketBase Collections
- [ ] Create Property collection
- [ ] Create Unit collection with property relation
- [ ] Create Tenant collection with unit relation
- [ ] Create RentPayment collection
- [ ] Create Expense collection
- [ ] Create MaintenanceTask collection
- [ ] Create Loan collection
- [ ] Create LoanPayment collection
- [ ] Create Document collection with file field
- [ ] Configure collection rules (auth, validation)
- [ ] Set up cascade delete rules
- [ ] Test all CRUD operations via PocketBase admin

---

## Phase 3: Repository Layer

### Repository Pattern Implementation
- [ ] Create base repository interface
- [ ] Implement PropertyRepository
  - [ ] CRUD operations (local + remote)
  - [ ] Sync logic
- [ ] Implement UnitRepository
- [ ] Implement TenantRepository
- [ ] Implement RentPaymentRepository
- [ ] Implement ExpenseRepository
- [ ] Implement MaintenanceTaskRepository
- [ ] Implement LoanRepository
- [ ] Implement LoanPaymentRepository
- [ ] Implement DocumentRepository
- [ ] Create SyncService for background sync
- [ ] Implement conflict resolution strategy
- [ ] Add retry logic with exponential backoff

---

## Phase 4: Properties & Units Feature

### UI Screens
- [ ] Property list screen
- [ ] Property detail screen
- [ ] Add/Edit property form
- [ ] Unit list (within property detail)
- [ ] Add/Edit unit form
- [ ] Unit detail view

### Business Logic
- [ ] Property CRUD operations
- [ ] Unit CRUD operations
- [ ] Link units to properties
- [ ] Update unit occupancy status
- [ ] Calculate property value and equity
- [ ] Validate property/unit data

### Testing
- [ ] Manual test: Create property
- [ ] Manual test: Add units to property
- [ ] Manual test: Edit property details
- [ ] Manual test: Delete property (with cascade)
- [ ] Test offline CRUD operations
- [ ] Test sync after offline changes

---

## Phase 5: Tenants & Leases Feature

### UI Screens
- [ ] Tenant list screen
- [ ] Tenant detail screen
- [ ] Add/Edit tenant form
- [ ] Lease information view
- [ ] End lease flow

### Business Logic
- [ ] Tenant CRUD operations
- [ ] Link tenant to unit
- [ ] Auto-update unit status when tenant assigned
- [ ] Calculate lease duration
- [ ] Flag expiring leases (< 60 days)
- [ ] Handle lease end and unit vacancy

### Testing
- [ ] Manual test: Add tenant to unit
- [ ] Manual test: View tenant details
- [ ] Manual test: End lease
- [ ] Verify unit status changes

---

## Phase 6: Rent Payments Feature

### UI Screens
- [ ] Rent payment list
- [ ] Add rent payment form
- [ ] Payment history per tenant
- [ ] Outstanding rent view

### Business Logic
- [ ] Record rent payment
- [ ] Calculate outstanding/late rent
- [ ] Flag late payments (overdue > 1 day)
- [ ] Generate rent due dates
- [ ] Link payments to tenant and unit
- [ ] Calculate total income

### Testing
- [ ] Manual test: Record payment
- [ ] Manual test: View outstanding rent
- [ ] Verify late payment flagging
- [ ] Test payment history display

---

## Phase 7: Expenses Feature

### UI Screens
- [ ] Expense list screen
- [ ] Add/Edit expense form
- [ ] Expense detail view with receipt
- [ ] Filter by category, property, date

### Business Logic
- [ ] Expense CRUD operations
- [ ] Link expense to property or unit
- [ ] Handle recurring expenses
- [ ] Upload receipt to PocketBase file storage
- [ ] Calculate total expenses
- [ ] Category management

### Testing
- [ ] Manual test: Log expense
- [ ] Manual test: Attach receipt photo
- [ ] Manual test: View expense history
- [ ] Test file upload/download

---

## Phase 8: Maintenance Feature

### UI Screens
- [ ] Maintenance task list
- [ ] Add/Edit task form
- [ ] Task detail view
- [ ] Filter by status, priority, property

### Business Logic
- [ ] MaintenanceTask CRUD operations
- [ ] Update task status
- [ ] Link to property or unit
- [ ] Record actual cost when complete
- [ ] Attach photos
- [ ] Flag overdue tasks

### Testing
- [ ] Manual test: Create task
- [ ] Manual test: Update status
- [ ] Manual test: Mark as complete with cost
- [ ] Verify overdue highlighting

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
