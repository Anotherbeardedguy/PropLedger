# Decisions and Changes Log

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
