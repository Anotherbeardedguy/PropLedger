# Rental Portfolio App (Android)

## 1. Overview

**Purpose**  
A personal Android-only mobile application to manage a rental apartment portfolio, covering properties, units, tenants, rent, expenses, maintenance, documents, and loans.

**Target User**  
Single owner/operator managing a small-to-medium rental portfolio.

**Platform**  
- Android only
- Built with Flutter
- Backend: Firebase (Google Cloud)

**Design Philosophy**  
- Manual-first, low automation
- Fast data entry
- Financial clarity over visual polish
- Offline-tolerant

---

## 2. Tech Stack

### Frontend
- Flutter (stable channel)
- Dart
- State management: Riverpod or Bloc (pick one, be consistent)
- Local storage: SQLite / Drift

### Backend
- Firebase (Google Cloud)
- Firestore for database
- Firebase Auth for authentication (email + password, single user)
- Cloud Functions for server-side logic
- Firebase Cloud Messaging (FCM) for notifications

### Infrastructure
- Firebase project (free tier for development)
- Firestore automated backups
- Cloud Storage for file uploads

---

## 3. Core Data Models (Firestore Collections)

### Property
- id
- name
- address
- purchase_date
- purchase_price
- estimated_value
- notes

### Unit
- id
- property_id (relation)
- unit_name
- size_sqm
- rooms
- rent_amount
- status (vacant | occupied)
- notes

### Tenant
- id
- unit_id (relation)
- name
- phone
- email
- lease_start
- lease_end
- deposit_amount
- notes

### RentPayment
- id
- unit_id (relation)
- tenant_id (relation)
- due_date
- paid_date
- amount
- status (paid | late | missing)

### Expense
- id
- property_id (relation)
- unit_id (optional relation)
- category
- amount
- date
- recurring (bool)
- notes
- receipt_file

### MaintenanceTask
- id
- property_id (relation)
- unit_id (optional relation)
- description
- priority
- status (open | in_progress | done)
- due_date
- cost
- attachments

### Loan
- id
- property_id (relation)
- lender
- loan_type
- original_amount
- current_balance
- interest_rate
- interest_type
- payment_frequency
- start_date
- end_date
- notes

### LoanPayment
- id
- loan_id (relation)
- payment_date
- total_amount
- principal_amount
- interest_amount
- remaining_balance

### Document
- id
- linked_type (property | unit | tenant)
- linked_id
- document_type
- file
- expiry_date
- notes

---

## 4. App Structure & Navigation

- Splash / Auth
- Dashboard
- Properties
  - Property Detail
    - Units
    - Tenants
    - Loans
    - Documents
- Maintenance
- Expenses
- Reports
- Settings

Bottom navigation with 4–5 primary sections.

---

## 5. User Stories

### Dashboard
- As a user, I want to see outstanding rent so I know who hasn’t paid.
- As a user, I want to see upcoming lease expiries so I can act early.
- As a user, I want to see monthly cash flow so I understand performance.

### Properties & Units
- As a user, I want to create properties so I can organize my portfolio.
- As a user, I want to add units under properties so I can track rent per unit.

### Tenants & Rent
- As a user, I want to assign tenants to units so I know who lives where.
- As a user, I want to mark rent as paid so I can track income.
- As a user, I want to see late payments clearly flagged.

### Expenses
- As a user, I want to log expenses so I know my true costs.
- As a user, I want to attach receipts so I have records.

### Maintenance
- As a user, I want to log maintenance issues so nothing is forgotten.
- As a user, I want to track maintenance status so I know what’s open.

### Loans
- As a user, I want to record loans per property so I know my leverage.
- As a user, I want to log loan payments so I track principal vs interest.
- As a user, I want to see remaining balances per property.

### Documents
- As a user, I want to store leases and contracts so everything is in one place.
- As a user, I want expiry reminders so I don’t miss renewals.

---

## 6. Security & Access

- Single-user assumption
- Local biometric unlock
- Firebase Auth tokens securely stored
- HTTPS enforced by default with Firebase

---

## 7. MVP Scope (Strict)

Included:
- Properties, Units, Tenants
- Rent tracking
- Expenses
- Maintenance
- Loans & loan payments
- Documents
- Dashboard summaries

Excluded:
- Bank sync
- Tenant portal
- Multi-user access
- Automated accounting

---

## 8. Development TODO List

### Phase 1 – Foundation
- [ ] Set up Flutter project
- [ ] Create Firebase project
- [ ] Configure Firebase for Android
- [ ] Define Firestore collections & security rules
- [ ] Implement Firebase Authentication

### Phase 2 – Core Data
- [ ] Property CRUD
- [ ] Unit CRUD
- [ ] Tenant CRUD
- [ ] Loan CRUD

### Phase 3 – Financial Tracking
- [ ] Rent payment logic
- [ ] Expense logging
- [ ] Loan payment logging

### Phase 4 – Operations
- [ ] Maintenance tasks
- [ ] Document upload & storage
- [ ] Reminders logic

### Phase 5 – Dashboard & Reports
- [ ] Dashboard KPIs
- [ ] Monthly cash flow view
- [ ] Property financial snapshot

### Phase 6 – Polish
- [ ] Offline sync handling
- [ ] Error states
- [ ] Backup verification
- [ ] Android build & signing

---

## 9. Success Criteria

- All portfolio data is accessible offline
- Cash flow and debt per property visible in seconds
- No critical data duplication
- Manual workflows remain fast

---

This document is intended to be implementation-ready for a solo developer or freelancer build.

