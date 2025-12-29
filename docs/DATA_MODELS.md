# PropLedger - Data Models & Schema

## Overview

This document defines the data models for PropLedger, including both **local SQLite (Drift)** tables and **PocketBase collections**. The structure is designed for offline-first operation with background sync.

---

## 1. Property

Represents a physical rental property in the portfolio.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `name` | String | Yes | Property name/identifier |
| `address` | String | Yes | Full property address |
| `purchase_date` | DateTime | No | Date property was purchased |
| `purchase_price` | Decimal | No | Original purchase price |
| `estimated_value` | Decimal | No | Current estimated value |
| `notes` | Text | No | Additional notes |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Has Many**: Units
- **Has Many**: Loans
- **Has Many**: Expenses
- **Has Many**: MaintenanceTasks
- **Has Many**: Documents

### Business Rules
- Name and address are required
- Cannot delete property with active tenants
- Deleting property cascades to units (if vacant)

### PocketBase Collection Config
```javascript
{
  "name": "properties",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "address", "type": "text", "required": true},
    {"name": "purchase_date", "type": "date"},
    {"name": "purchase_price", "type": "number"},
    {"name": "estimated_value", "type": "number"},
    {"name": "notes", "type": "text"}
  ],
  "listRule": "@request.auth.id != ''",
  "viewRule": "@request.auth.id != ''",
  "createRule": "@request.auth.id != ''",
  "updateRule": "@request.auth.id != ''",
  "deleteRule": "@request.auth.id != ''"
}
```

---

## 2. Unit

Represents an individual rental unit within a property.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `property_id` | String (FK) | Yes | Reference to Property |
| `unit_name` | String | Yes | Unit identifier (apt #, etc.) |
| `size_sqm` | Decimal | No | Size in square meters |
| `rooms` | Integer | No | Number of rooms |
| `rent_amount` | Decimal | Yes | Monthly rent amount |
| `status` | Enum | Yes | `vacant` or `occupied` |
| `notes` | Text | No | Additional notes |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Property
- **Has Many**: Tenants
- **Has Many**: RentPayments
- **Has Many**: Expenses (optional)
- **Has Many**: MaintenanceTasks (optional)
- **Has Many**: Documents

### Business Rules
- Must belong to a property
- Rent amount must be > 0
- Status defaults to `vacant`
- Auto-updates to `occupied` when tenant assigned
- Cannot delete unit with active tenant

### PocketBase Collection Config
```javascript
{
  "name": "units",
  "schema": [
    {"name": "property_id", "type": "relation", "required": true, "options": {"collectionId": "properties"}},
    {"name": "unit_name", "type": "text", "required": true},
    {"name": "size_sqm", "type": "number"},
    {"name": "rooms", "type": "number"},
    {"name": "rent_amount", "type": "number", "required": true},
    {"name": "status", "type": "select", "required": true, "options": {"values": ["vacant", "occupied"]}},
    {"name": "notes", "type": "text"}
  ]
}
```

---

## 3. Tenant

Represents a tenant renting a unit.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `unit_id` | String (FK) | Yes | Reference to Unit |
| `name` | String | Yes | Tenant full name |
| `phone` | String | No | Contact phone number |
| `email` | String | No | Contact email |
| `lease_start` | DateTime | Yes | Lease start date |
| `lease_end` | DateTime | Yes | Lease end date |
| `deposit_amount` | Decimal | No | Security deposit amount |
| `notes` | Text | No | Additional notes |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Unit
- **Has Many**: RentPayments
- **Has Many**: Documents

### Business Rules
- Must be assigned to a unit
- Lease end must be after lease start
- Only one active tenant per unit
- Ending lease auto-updates unit to `vacant`

### PocketBase Collection Config
```javascript
{
  "name": "tenants",
  "schema": [
    {"name": "unit_id", "type": "relation", "required": true, "options": {"collectionId": "units"}},
    {"name": "name", "type": "text", "required": true},
    {"name": "phone", "type": "text"},
    {"name": "email", "type": "email"},
    {"name": "lease_start", "type": "date", "required": true},
    {"name": "lease_end", "type": "date", "required": true},
    {"name": "deposit_amount", "type": "number"},
    {"name": "notes", "type": "text"}
  ]
}
```

---

## 4. RentPayment

Records rent payments from tenants.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `unit_id` | String (FK) | Yes | Reference to Unit |
| `tenant_id` | String (FK) | Yes | Reference to Tenant |
| `due_date` | DateTime | Yes | Date rent was due |
| `paid_date` | DateTime | No | Date rent was actually paid |
| `amount` | Decimal | Yes | Payment amount |
| `status` | Enum | Yes | `paid`, `late`, or `missing` |
| `notes` | Text | No | Payment notes |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Unit
- **Belongs To**: Tenant

### Business Rules
- Amount must be > 0
- Status auto-calculated:
  - `paid` if paid_date exists
  - `late` if paid_date > due_date
  - `missing` if paid_date is null and due_date < today
- Due date typically monthly

### PocketBase Collection Config
```javascript
{
  "name": "rent_payments",
  "schema": [
    {"name": "unit_id", "type": "relation", "required": true, "options": {"collectionId": "units"}},
    {"name": "tenant_id", "type": "relation", "required": true, "options": {"collectionId": "tenants"}},
    {"name": "due_date", "type": "date", "required": true},
    {"name": "paid_date", "type": "date"},
    {"name": "amount", "type": "number", "required": true},
    {"name": "status", "type": "select", "required": true, "options": {"values": ["paid", "late", "missing"]}},
    {"name": "notes", "type": "text"}
  ]
}
```

---

## 5. Expense

Tracks property-related expenses.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `property_id` | String (FK) | Yes | Reference to Property |
| `unit_id` | String (FK) | No | Optional reference to Unit |
| `category` | String | Yes | Expense category |
| `amount` | Decimal | Yes | Expense amount |
| `date` | DateTime | Yes | Expense date |
| `recurring` | Boolean | No | Is this a recurring expense? |
| `notes` | Text | No | Description/notes |
| `receipt_file` | File | No | Receipt attachment |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Property
- **Belongs To**: Unit (optional)

### Categories
- Maintenance
- Utilities
- Property Tax
- Insurance
- HOA Fees
- Management Fees
- Repairs
- Improvements
- Other

### Business Rules
- Must belong to a property
- Amount must be > 0
- Can optionally link to specific unit

### PocketBase Collection Config
```javascript
{
  "name": "expenses",
  "schema": [
    {"name": "property_id", "type": "relation", "required": true, "options": {"collectionId": "properties"}},
    {"name": "unit_id", "type": "relation", "options": {"collectionId": "units"}},
    {"name": "category", "type": "text", "required": true},
    {"name": "amount", "type": "number", "required": true},
    {"name": "date", "type": "date", "required": true},
    {"name": "recurring", "type": "bool"},
    {"name": "notes", "type": "text"},
    {"name": "receipt_file", "type": "file", "options": {"maxSelect": 1, "maxSize": 5242880}}
  ]
}
```

---

## 6. MaintenanceTask

Tracks maintenance and repair tasks.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `property_id` | String (FK) | Yes | Reference to Property |
| `unit_id` | String (FK) | No | Optional reference to Unit |
| `description` | Text | Yes | Task description |
| `priority` | Enum | Yes | `low`, `medium`, `high` |
| `status` | Enum | Yes | `open`, `in_progress`, `done` |
| `due_date` | DateTime | No | Target completion date |
| `cost` | Decimal | No | Actual cost (when complete) |
| `attachments` | File | No | Photos/documents |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Property
- **Belongs To**: Unit (optional)

### Business Rules
- Must belong to a property
- Status defaults to `open`
- Overdue if due_date < today and status != `done`

### PocketBase Collection Config
```javascript
{
  "name": "maintenance_tasks",
  "schema": [
    {"name": "property_id", "type": "relation", "required": true, "options": {"collectionId": "properties"}},
    {"name": "unit_id", "type": "relation", "options": {"collectionId": "units"}},
    {"name": "description", "type": "text", "required": true},
    {"name": "priority", "type": "select", "required": true, "options": {"values": ["low", "medium", "high"]}},
    {"name": "status", "type": "select", "required": true, "options": {"values": ["open", "in_progress", "done"]}},
    {"name": "due_date", "type": "date"},
    {"name": "cost", "type": "number"},
    {"name": "attachments", "type": "file", "options": {"maxSelect": 5, "maxSize": 5242880}}
  ]
}
```

---

## 7. Loan

Represents a mortgage or loan on a property.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `property_id` | String (FK) | Yes | Reference to Property |
| `lender` | String | Yes | Lender name |
| `loan_type` | String | No | Mortgage, HELOC, etc. |
| `original_amount` | Decimal | Yes | Original loan amount |
| `current_balance` | Decimal | Yes | Current outstanding balance |
| `interest_rate` | Decimal | Yes | Annual interest rate (%) |
| `interest_type` | Enum | Yes | `fixed` or `variable` |
| `payment_frequency` | Enum | Yes | `monthly`, `quarterly`, etc. |
| `start_date` | DateTime | Yes | Loan start date |
| `end_date` | DateTime | No | Expected payoff date |
| `notes` | Text | No | Additional notes |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Property
- **Has Many**: LoanPayments

### Business Rules
- Must belong to a property
- Current balance auto-updates with payments
- Interest rate must be >= 0

### PocketBase Collection Config
```javascript
{
  "name": "loans",
  "schema": [
    {"name": "property_id", "type": "relation", "required": true, "options": {"collectionId": "properties"}},
    {"name": "lender", "type": "text", "required": true},
    {"name": "loan_type", "type": "text"},
    {"name": "original_amount", "type": "number", "required": true},
    {"name": "current_balance", "type": "number", "required": true},
    {"name": "interest_rate", "type": "number", "required": true},
    {"name": "interest_type", "type": "select", "required": true, "options": {"values": ["fixed", "variable"]}},
    {"name": "payment_frequency", "type": "select", "required": true, "options": {"values": ["monthly", "quarterly", "annually"]}},
    {"name": "start_date", "type": "date", "required": true},
    {"name": "end_date", "type": "date"},
    {"name": "notes", "type": "text"}
  ]
}
```

---

## 8. LoanPayment

Records individual loan payments.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `loan_id` | String (FK) | Yes | Reference to Loan |
| `payment_date` | DateTime | Yes | Date payment was made |
| `total_amount` | Decimal | Yes | Total payment amount |
| `principal_amount` | Decimal | Yes | Principal portion |
| `interest_amount` | Decimal | Yes | Interest portion |
| `remaining_balance` | Decimal | Yes | Balance after payment |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Relationships
- **Belongs To**: Loan

### Business Rules
- total_amount = principal_amount + interest_amount
- Auto-updates loan.current_balance
- remaining_balance must match loan balance

### PocketBase Collection Config
```javascript
{
  "name": "loan_payments",
  "schema": [
    {"name": "loan_id", "type": "relation", "required": true, "options": {"collectionId": "loans"}},
    {"name": "payment_date", "type": "date", "required": true},
    {"name": "total_amount", "type": "number", "required": true},
    {"name": "principal_amount", "type": "number", "required": true},
    {"name": "interest_amount", "type": "number", "required": true},
    {"name": "remaining_balance", "type": "number", "required": true}
  ]
}
```

---

## 9. Document

Stores files related to properties, units, or tenants.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String (UUID) | Yes | Unique identifier |
| `linked_type` | Enum | Yes | `property`, `unit`, or `tenant` |
| `linked_id` | String | Yes | ID of linked entity |
| `document_type` | String | Yes | Lease, insurance, deed, etc. |
| `file` | File | Yes | Uploaded file (PDF/image) |
| `expiry_date` | DateTime | No | Document expiration date |
| `notes` | Text | No | Additional notes |
| `created` | DateTime | Auto | Record creation timestamp |
| `updated` | DateTime | Auto | Last update timestamp |

### Document Types
- Lease Agreement
- Insurance Policy
- Property Deed
- Inspection Report
- Tax Document
- Contract
- Other

### Business Rules
- Must link to valid entity
- File required
- Expiring if expiry_date < 30 days from now

### PocketBase Collection Config
```javascript
{
  "name": "documents",
  "schema": [
    {"name": "linked_type", "type": "select", "required": true, "options": {"values": ["property", "unit", "tenant"]}},
    {"name": "linked_id", "type": "text", "required": true},
    {"name": "document_type", "type": "text", "required": true},
    {"name": "file", "type": "file", "required": true, "options": {"maxSelect": 1, "maxSize": 10485760}},
    {"name": "expiry_date", "type": "date"},
    {"name": "notes", "type": "text"}
  ]
}
```

---

## 10. SyncQueue (Local Only)

Tracks offline changes for background sync.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | Integer | Yes | Auto-increment ID |
| `collection` | String | Yes | PocketBase collection name |
| `record_id` | String | Yes | ID of affected record |
| `operation` | Enum | Yes | `create`, `update`, `delete` |
| `payload` | JSON | No | Record data for sync |
| `status` | Enum | Yes | `pending`, `syncing`, `failed` |
| `retry_count` | Integer | Yes | Number of retry attempts |
| `created` | DateTime | Auto | Timestamp |

### Business Rules
- Processed in FIFO order
- Max 3 retries before marking as failed
- Cleared after successful sync

---

## Entity Relationship Diagram

```
Property (1) ──── (*) Unit (1) ──── (*) Tenant
    │                  │                  │
    │                  │                  │
    │                  └──── (*) RentPayment (*) ──┘
    │                  │
    ├──── (*) Loan (1) ──── (*) LoanPayment
    │
    ├──── (*) Expense
    │
    ├──── (*) MaintenanceTask
    │
    └──── (*) Document
```

---

## Indexing Strategy

### Local Database (Drift)
- Index on `property_id` for all related tables
- Index on `unit_id` for tenant-related tables
- Index on `status` for payments and tasks
- Index on `due_date` and `expiry_date`

### PocketBase
- Auto-indexes on relation fields
- Custom index on `status` fields for filtering
- Index on date fields for range queries
