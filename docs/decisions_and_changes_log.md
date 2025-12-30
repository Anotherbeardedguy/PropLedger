# Decisions and Changes Log

## 2024-12-30: Backend Migration from PocketBase to Firebase

### Context
Project architecture updated to use Firebase instead of PocketBase as the backend service. This decision aligns with:
- Better integration with Google Cloud ecosystem
- More mature authentication system
- Built-in Cloud Functions for serverless logic
- Native support for push notifications (FCM)
- Automatic HTTPS and security
- Better scalability for future growth

### Changes

#### Documentation Updates
- **README.md**: Updated tech stack, setup instructions, security section
- **docs/TODO.md**: Phase 1 backend setup, collections, authentication
- **rental_portfolio_app_development_document.md**: Backend architecture, infrastructure
- **docs/USER_STORIES.md**: Storage references updated to Cloud Storage
- **TESTING.md**: Testing instructions updated for Firebase

#### Backend Architecture
**Previous**: PocketBase (self-hosted)
- REST API
- Self-hosted on VPS
- Manual backup configuration

**New**: Firebase (Google Cloud)
- Firestore (NoSQL database)
- Firebase Auth (authentication)
- Cloud Functions (serverless)
- Cloud Storage (file uploads)
- Firebase Cloud Messaging (notifications)
- Automatic backups and scaling

#### Future Code Changes Required
- Rename `pocketbase_client.dart` → `firebase_client.dart`
- Update `auth_repository.dart` to use Firebase Auth SDK
- Replace `env.dart` PocketBase URLs with Firebase config
- Add Firebase dependencies to `pubspec.yaml`:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_storage`
  - `firebase_messaging`

#### Migration Notes
- Local-first architecture remains unchanged
- Drift database still primary data source
- Firebase sync will be implemented in future phase
- Current local-only implementation unaffected

### Rationale
1. **Better ecosystem**: Firebase provides complete backend solution
2. **Authentication**: More mature and secure auth system
3. **Notifications**: Built-in FCM support for payment reminders
4. **Scalability**: Auto-scaling with Firebase
5. **Free tier**: Generous free tier for development
6. **Documentation**: Extensive documentation and community support

---

## 2024-12-30: Automated Rent Payment System - Version 1.1.0

### Context
User requested an automated rent payment system with minimal manual intervention. The system should:
- Generate upcoming payments automatically based on tenant lease terms
- Require only a "one-time setup" (changes only on real-world alterations)
- Support payment reminders and interest calculations
- Update UI in real-time across all screens

### Changes Implemented

#### 1. Payment Generator Service
**File**: `lib/features/rent_payments/logic/payment_generator_service.dart`

- **Auto-generation logic**: Creates recurring payments from lease start to lease end
- **Lease term support**: Handles monthly and annual payment intervals
- **Late fee calculation**: 5% daily late fee, max 25% of payment amount
- **Upcoming payments**: Returns payments due in next N days
- **Payment reminder support**: Infrastructure for future reminder system

#### 2. Real-Time Provider Integration
**Files**:
- `lib/features/tenants/logic/tenants_notifier.dart`
- `lib/features/dashboard/widgets/outstanding_rent_card.dart`
- `lib/features/dashboard/widgets/upcoming_payments_card.dart`

**Changes**:
- Tenant create/update now invalidates `rentPaymentsNotifierProvider`
- Dashboard cards converted from `FutureBuilder` to `ref.watch()` for reactive updates
- Payments auto-generate instantly without app rebuild
- Dashboard updates immediately when payment status changes

#### 3. Enhanced Rent Payments UI
**File**: `lib/features/rent_payments/presentation/rent_payments_screen.dart`

**Improvements**:
- Converted to `ConsumerStatefulWidget` for filter state management
- Added payment filtering: All, Outstanding, Late, Paid
- Redesigned payment cards: Tenant name as H1, unit name, amount prominent
- Dynamic empty state messages based on active filter
- Type-safe tenant/unit lookups with proper null handling

#### 4. Dashboard Enhancements
**Files**:
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/dashboard/widgets/*.dart`

**UI Improvements**:
- Outstanding Rent Card: Total outstanding, late fees, late count
- Upcoming Payments Card: Next 30 days, sorted by due date
- Quick Actions: 2-column grid layout with uniform tile sizes
- Real-time updates on all dashboard metrics

### Technical Decisions

1. **One-Time Setup Philosophy**
   - Payments auto-generate on tenant create/update
   - No manual intervention needed for recurring payments
   - System-driven payment lifecycle management

2. **Provider Invalidation Strategy**
   - Used `ref.invalidate()` instead of manual state updates
   - Ensures all dependent UIs refresh automatically
   - Maintains single source of truth

3. **Type Safety**
   - Cast lists to `dynamic` for `firstWhere` with null `orElse`
   - Prevents runtime type errors
   - Graceful handling of missing references

4. **Grid Layout Uniformity**
   - `SizedBox.expand` fills grid cells completely
   - Fixed-height spacer (18px) for optional labels
   - `childAspectRatio: 1.2` for balanced proportions

### Bug Fixes

1. **Payment Auto-Generation Refresh** (Commit: 0805e5d)
   - Fixed: Payments only appeared after app rebuild
   - Solution: Invalidate provider after tenant operations

2. **Type Error in orElse** (Commit: ac5978d)
   - Fixed: `'() => Null' is not a subtype of '(() => Tenant)?'`
   - Solution: Cast to dynamic before firstWhere

3. **Dashboard Stale Data** (Commit: d54e094)
   - Fixed: Cards didn't reflect changes
   - Solution: Convert from FutureBuilder to ref.watch

4. **Grid Tile Sizing** (Commit: 9ddea13)
   - Fixed: Inconsistent quick action tile sizes
   - Solution: GridView + SizedBox.expand + fixed spacers

### Files Modified
- `lib/features/rent_payments/logic/payment_generator_service.dart` (NEW)
- `lib/features/rent_payments/logic/rent_payments_notifier.dart` (NEW)
- `lib/features/rent_payments/presentation/rent_payments_screen.dart` (ENHANCED)
- `lib/features/rent_payments/presentation/payment_form_screen.dart` (NEW)
- `lib/features/tenants/logic/tenants_notifier.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/dashboard/widgets/outstanding_rent_card.dart` (NEW)
- `lib/features/dashboard/widgets/upcoming_payments_card.dart` (NEW)
- `lib/data/repositories/providers.dart`

### Testing Performed
- Tenant create → Payments auto-generate instantly
- Tenant update → Payments regenerate and refresh
- Mark payment as paid → Dashboard updates immediately
- Payment filtering → All options work correctly
- Type safety → No runtime errors with missing references
- Grid layout → All tiles perfectly uniform

### Future Enhancements
- Payment reminder notifications (FCM)
- Configurable late fee percentage and grace period
- Bulk payment operations
- Payment export to CSV/PDF
- Advanced filtering (date range, amount range)

---

## December 30, 2024 - Data Model Enhancements

### Overview
Enhanced data models to support standalone units, lease payment terms, unit-level loans, and upkeep costs.

### Changes Made

#### 1. Standalone Units Support
**Problem**: Units were always required to belong to a property.
**Solution**: Made `Unit.propertyId` nullable to support independent units.
- Updated `units` table: `propertyId` column now nullable
- Updated `Unit` model constructor and methods
- Units can now be created without property assignment
- Existing units remain associated with properties

**Files Modified**:
- `lib/data/local/database.dart` - Schema change
- `lib/data/models/unit.dart` - Model update
- `lib/data/repositories/unit_repository.dart` - Repository mapping

#### 2. Unit Upkeep Amount
**Problem**: No way to track maintenance/service costs per unit.
**Solution**: Added `upkeepAmount` field to Unit model.
- New optional field in `units` table
- Display in unit forms and detail screens
- Helps calculate total unit operating costs

**Files Modified**:
- `lib/data/local/database.dart` - Added `upkeepAmount` column
- `lib/data/models/unit.dart` - Added field to model
- `lib/data/repositories/unit_repository.dart` - Repository mapping
- `lib/features/properties/presentation/widgets/unit_form_dialog.dart` - Form field
- `lib/features/properties/presentation/widgets/units_tab.dart` - Display

**Usage**:
```dart
Unit(
  id: '...',
  unitName: 'Unit 101',
  rentAmount: 1500.0,
  upkeepAmount: 150.0, // NEW: Monthly maintenance costs
  // ...
)
```

#### 3. Lease Payment Terms
**Problem**: No distinction between monthly and annual lease payments.
**Solution**: Added `LeaseTerm` enum and `leaseTerm` field to Tenant model.
- New enum: `LeaseTerm { monthly, annually }`
- Dropdown selector in tenant form
- Displayed in tenant detail screen
- Affects rent payment calculations (future Phase 6)

**Files Modified**:
- `lib/data/local/database.dart` - Added `leaseTerm` column (default: 'monthly')
- `lib/data/models/tenant.dart` - Added LeaseTerm enum and field
- `lib/data/repositories/tenant_repository.dart` - Repository mapping
- `lib/features/tenants/presentation/tenant_form_screen.dart` - Form dropdown
- `lib/features/tenants/presentation/tenant_detail_screen.dart` - Display

**Usage**:
```dart
Tenant(
  id: '...',
  name: 'John Doe',
  leaseTerm: LeaseTerm.monthly, // or LeaseTerm.annually
  // ...
)
```

#### 4. Unit-Level Loans
**Problem**: Loans could only be attached to properties, not individual units.
**Solution**: Made `Loan.propertyId` nullable and added `unitId` field.
- Loans can now be attached to specific units
- Property-level loans still supported (unitId = null)
- Future loan forms will support unit selection

**Files Modified**:
- `lib/data/local/database.dart` - Made `propertyId` nullable, added `unitId`
- `lib/data/models/loan.dart` - Model update (future implementation)

**Schema**:
```sql
loans:
  - propertyId: nullable (for property-level loans)
  - unitId: nullable (for unit-specific loans)
  - At least one must be set
```

### Database Migration

**Schema Version**: 1 → 2

**Migration Strategy**: 
- Existing data compatible (all new fields are nullable or have defaults)
- No data loss on upgrade
- `leaseTerm` defaults to 'monthly' for existing tenants
- Existing units keep property associations

### Testing Checklist

- [x] Unit form: Add/edit with upkeep amount
- [x] Unit display: Shows upkeep amount when set
- [x] Tenant form: Lease term selector (Monthly/Annually)
- [x] Tenant detail: Displays lease term
- [x] Database schema regenerated successfully
- [x] Flutter analyze passes
- [x] All imports resolved

### API Impact

**Breaking Changes**: None (all new fields are optional)

**New Fields**:
- `Unit.upkeepAmount?: double`
- `Unit.propertyId?: string` (nullable now)
- `Tenant.leaseTerm: LeaseTerm` (default: monthly)
- `Loan.unitId?: string`
- `Loan.propertyId?: string` (nullable now)

### Future Implications

**Phase 6 (Rent Payments)**:
- Use `Tenant.leaseTerm` for payment frequency
- Calculate based on monthly vs annually
- Track next payment date accordingly

**Phase 7 (Loans)**:
- Loan forms should support unit selection
- Display unit-level vs property-level loans
- Calculate loan allocations per unit

**Reporting**:
- Total unit costs: `rentAmount + upkeepAmount`
- Net operating income calculations
- Unit-level P&L statements

### Rollback Procedure

If issues arise:
1. Revert to previous commit
2. Schema version will stay at 2
3. App will ignore new columns
4. Or manually downgrade schema version to 1

### Related Issues

- Standalone units enable multi-unit management without property grouping
- Upkeep amounts improve financial tracking accuracy
- Lease terms critical for rent payment automation
- Unit-level loans support granular financial modeling

---

## Notes

- All changes backward compatible
- No existing data modified
- Schema migration automatic on app launch
- Forms updated with sensible defaults
