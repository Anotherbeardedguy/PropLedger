# PropLedger - User Stories

## Epic 1: Authentication & Security

### US-001: User Login
**As a** property owner  
**I want to** log in with email and password  
**So that** only I can access my portfolio data

**Acceptance Criteria**
- Email and password fields with validation
- Secure token storage
- "Remember me" functionality
- Clear error messages for invalid credentials

### US-002: Biometric Unlock
**As a** user  
**I want to** unlock the app with fingerprint/face ID  
**So that** I can access my data quickly and securely

**Acceptance Criteria**
- Biometric prompt on app launch
- Fallback to password if biometric fails
- Can enable/disable in settings
- Works offline

---

## Epic 2: Dashboard & Overview

### US-003: View Dashboard Summary
**As a** user  
**I want to** see key metrics on the dashboard  
**So that** I understand my portfolio performance at a glance

**Acceptance Criteria**
- Outstanding rent total and count
- Monthly cash flow summary
- Upcoming lease expiries (next 30 days)
- Open maintenance tasks count
- Total portfolio value

### US-004: See Outstanding Rent
**As a** user  
**I want to** see which tenants haven't paid rent  
**So that** I can follow up promptly

**Acceptance Criteria**
- List of unpaid/late rent payments
- Tenant name, unit, amount, due date
- Days overdue highlighted
- Tap to view tenant details

### US-005: View Upcoming Lease Expiries
**As a** user  
**I want to** see leases expiring soon  
**So that** I can plan renewals or find new tenants

**Acceptance Criteria**
- List of leases expiring in next 60 days
- Tenant name, unit, expiry date
- Days until expiry
- Tap to view lease details

### US-006: View Monthly Cash Flow
**As a** user  
**I want to** see my monthly income vs expenses  
**So that** I understand my profitability

**Acceptance Criteria**
- Current month income (rent received)
- Current month expenses
- Net cash flow calculation
- Month-over-month comparison

---

## Epic 3: Properties & Units

### US-007: Create Property
**As a** user  
**I want to** add a new property to my portfolio  
**So that** I can track it separately

**Acceptance Criteria**
- Name, address, purchase date, purchase price
- Optional estimated value and notes
- Validation on required fields
- Success confirmation

### US-008: View Property List
**As a** user  
**I want to** see all my properties  
**So that** I can navigate to property details

**Acceptance Criteria**
- Scrollable list of properties
- Property name and address visible
- Tap to view details
- Search/filter option

### US-009: View Property Details
**As a** user  
**I want to** see comprehensive property information  
**So that** I can manage it effectively

**Acceptance Criteria**
- Property details displayed
- Tabs: Units, Tenants, Loans, Documents
- Financial summary (value, equity, cash flow)
- Edit and delete options

### US-010: Add Unit to Property
**As a** user  
**I want to** add units under a property  
**So that** I can track rent per unit

**Acceptance Criteria**
- Unit name/number, size, rooms, rent amount
- Status: vacant or occupied
- Linked to parent property
- Can add multiple units

### US-011: Update Unit Status
**As a** user  
**I want to** mark units as vacant or occupied  
**So that** I know availability

**Acceptance Criteria**
- Quick toggle between vacant/occupied
- Status visible in unit list
- Vacant units highlighted

---

## Epic 4: Tenants & Leases

### US-012: Add Tenant to Unit
**As a** user  
**I want to** assign a tenant to a unit  
**So that** I know who lives where

**Acceptance Criteria**
- Tenant name, phone, email
- Lease start/end dates
- Deposit amount
- Auto-mark unit as occupied

### US-013: View Tenant Details
**As a** user  
**I want to** see tenant information  
**So that** I can contact them or review lease terms

**Acceptance Criteria**
- Full tenant details displayed
- Lease dates and deposit shown
- Contact buttons (call, email)
- Rent payment history

### US-014: End Lease
**As a** user  
**I want to** mark a lease as ended  
**So that** I can track tenant turnover

**Acceptance Criteria**
- Set lease end date
- Auto-mark unit as vacant
- Archive tenant record
- Deposit return tracking

---

## Epic 5: Rent Payments

### US-015: Record Rent Payment
**As a** user  
**I want to** mark rent as paid  
**So that** I track income accurately

**Acceptance Criteria**
- Select tenant/unit
- Payment date and amount
- Payment method (optional)
- Auto-update outstanding rent

### US-016: View Payment History
**As a** user  
**I want to** see all rent payments for a tenant  
**So that** I can verify payment patterns

**Acceptance Criteria**
- Chronological list of payments
- Amount, date, status
- Filter by date range
- Export to CSV (future)

### US-017: Flag Late Payments
**As a** user  
**I want to** see late payments clearly highlighted  
**So that** I can follow up immediately

**Acceptance Criteria**
- Payments overdue by 1+ days flagged red
- Days late displayed
- Notification badge on dashboard
- Sort by days overdue

---

## Epic 6: Expenses

### US-018: Log Expense
**As a** user  
**I want to** record an expense  
**So that** I know my true costs

**Acceptance Criteria**
- Category (maintenance, utilities, tax, etc.)
- Amount, date, notes
- Link to property or unit
- Mark as recurring if applicable

### US-019: Attach Receipt
**As a** user  
**I want to** attach receipt photos to expenses  
**So that** I have documentation

**Acceptance Criteria**
- Capture photo or select from gallery
- View attached receipt in expense detail
- Store securely in Firebase Cloud Storage
- Can replace or delete receipt

### US-020: View Expense History
**As a** user  
**I want to** see all expenses  
**So that** I can analyze spending

**Acceptance Criteria**
- List view with category, amount, date
- Filter by property, category, date range
- Total expenses displayed
- Tap to view details

---

## Epic 7: Maintenance

### US-021: Create Maintenance Task
**As a** user  
**I want to** log maintenance issues  
**So that** nothing is forgotten

**Acceptance Criteria**
- Description, priority, due date
- Link to property or unit
- Optional cost estimate
- Status: open, in progress, done

### US-022: Update Maintenance Status
**As a** user  
**I want to** track maintenance progress  
**So that** I know what's outstanding

**Acceptance Criteria**
- Update status (open → in progress → done)
- Record actual cost when complete
- Add completion notes
- Attach photos

### US-023: View Maintenance Tasks
**As a** user  
**I want to** see all maintenance tasks  
**So that** I can prioritize work

**Acceptance Criteria**
- Filter by status, property, priority
- Sort by due date or priority
- Overdue tasks highlighted
- Quick action buttons

---

## Epic 8: Loans

### US-024: Add Loan to Property
**As a** user  
**I want to** record loans per property  
**So that** I know my leverage

**Acceptance Criteria**
- Lender, loan type, amount
- Interest rate, payment frequency
- Start and end dates
- Linked to specific property

### US-025: Record Loan Payment
**As a** user  
**I want to** log loan payments  
**So that** I track principal vs interest

**Acceptance Criteria**
- Payment date and total amount
- Principal and interest breakdown
- Auto-update remaining balance
- Payment history visible

### US-026: View Loan Summary
**As a** user  
**I want to** see remaining loan balances per property  
**So that** I understand my debt

**Acceptance Criteria**
- Original amount vs current balance
- Total interest paid to date
- Next payment due date
- Payoff date estimate

---

## Epic 9: Documents

### US-027: Upload Document
**As a** user  
**I want to** store leases and contracts  
**So that** everything is in one place

**Acceptance Criteria**
- Link to property, unit, or tenant
- Document type (lease, insurance, etc.)
- Upload PDF or image
- Optional expiry date

### US-028: View Documents
**As a** user  
**I want to** access stored documents  
**So that** I can reference them when needed

**Acceptance Criteria**
- List view grouped by type
- Thumbnail preview for images
- Tap to view full document
- Search by name or type

### US-029: Document Expiry Alerts
**As a** user  
**I want to** be reminded of expiring documents  
**So that** I don't miss renewals

**Acceptance Criteria**
- Expiring documents shown on dashboard
- 30-day advance warning
- Badge notification count
- Tap to view document details

---

## Epic 10: Reports & Analytics

### US-030: Property Financial Snapshot
**As a** user  
**I want to** see financial performance per property  
**So that** I can evaluate ROI

**Acceptance Criteria**
- Total rent collected (YTD, all-time)
- Total expenses (YTD, all-time)
- Net cash flow
- Property value vs debt

### US-031: Portfolio Overview Report
**As a** user  
**I want to** see aggregated portfolio metrics  
**So that** I understand overall performance

**Acceptance Criteria**
- Total portfolio value
- Total equity (value - debt)
- Occupancy rate
- Average rent per unit
- YTD income and expenses

---

## Epic 11: Settings & Configuration

### US-032: Configure App Settings
**As a** user  
**I want to** customize app preferences  
**So that** it works how I like

**Acceptance Criteria**
- Currency selection
- Date format preference
- Biometric toggle
- Sync frequency
- Theme selection (light/dark)

### US-033: Backup & Restore
**As a** user  
**I want to** ensure my data is backed up  
**So that** I don't lose information

**Acceptance Criteria**
- View last sync time
- Manual sync trigger
- Export data option
- Restore from backup (future)

---

## Non-Functional User Stories

### US-034: Offline Access
**As a** user  
**I want to** access and edit data offline  
**So that** I'm not dependent on internet

**Acceptance Criteria**
- All CRUD operations work offline
- Changes queued for sync
- Sync when connection restored
- Conflict resolution handled

### US-035: Fast Data Entry
**As a** user  
**I want to** add records quickly  
**So that** data entry isn't tedious

**Acceptance Criteria**
- Forms auto-focus first field
- Smart defaults (today's date, etc.)
- Minimal required fields
- Quick save shortcuts
