# PropLedger - Rental Portfolio Management App

**A personal Android mobile application for managing rental property portfolios**

## Overview

PropLedger is a Flutter-based Android application designed for single owner/operators managing small-to-medium rental portfolios. It provides comprehensive property, tenant, financial, and maintenance tracking with offline-first capabilities.

## Key Features

- **Portfolio Management**: Properties, units, tenants
- **Automated Rent Payments**: One-time setup rent collection system
  - Auto-generates recurring payments based on lease terms (monthly/annually)
  - Real-time payment tracking and status updates
  - Late payment detection with automatic interest calculation
  - Outstanding and upcoming payment dashboard cards
  - Payment filtering (All, Outstanding, Late, Paid)
- **Financial Tracking**: Rent payments, expenses, loans
- **Operations**: Maintenance tasks, document storage
- **Analytics**: Dashboard KPIs, cash flow analysis
- **Offline-First**: SQLite local storage with PocketBase sync

## Tech Stack

### Frontend
- **Framework**: Flutter (stable channel)
- **Language**: Dart
- **State Management**: Riverpod/Bloc
- **Local Database**: SQLite/Drift

### Backend
- **BaaS**: PocketBase (self-hosted)
- **API**: REST
- **Authentication**: Email + Password (single user)

## Project Structure

```
PropLedger/
├── docs/                    # Documentation
│   ├── SPEC.md             # Technical specification
│   ├── USER_STORIES.md     # User stories
│   ├── TODO.md             # Development tasks
│   ├── DATA_MODELS.md      # Database schema
│   └── API.md              # API documentation
├── lib/                     # Flutter source code
│   ├── app/                # App configuration
│   ├── core/               # Constants, theming, utils
│   ├── data/               # Models, repositories
│   ├── features/           # Feature modules
│   └── main.dart           # App entry point
└── rental_portfolio_app_development_document.md
```

## MVP Scope

### Included
- Properties, Units, Tenants CRUD
- Rent tracking & payment recording
- Expense logging with receipts
- Maintenance task management
- Loan tracking & payment history
- Document storage with expiry alerts
- Dashboard summaries

### Excluded
- Bank account synchronization
- Tenant portal/self-service
- Multi-user access control
- Automated accounting integration

## Design Philosophy

- **One-time setup automation**: Configure once, runs automatically
- **Manual-first control**: Low automation for complex workflows, user control
- **Fast data entry**: Optimized for quick updates
- **Financial clarity**: Clear view of cash flow and debt
- **Real-time updates**: Instant UI refresh across all screens
- **Offline-tolerant**: Works without internet connection

## Development Status

**Current Stage**: MVP (Minimum Viable Product)  
**Version**: 1.1.0

### Recent Updates (v1.1.0)
- ✅ Automated rent payment system with one-time setup
- ✅ Recurring payment generation based on lease terms
- ✅ Late payment detection and interest calculation
- ✅ Real-time dashboard updates
- ✅ Payment filtering and status tracking
- ✅ Unit-level standalone properties and loans
- ✅ Lease term support (monthly/annually)

See `docs/TODO.md` for detailed development roadmap.

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio / VS Code
- PocketBase instance (self-hosted or cloud)

### Setup
```bash
# Clone the repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### PocketBase Configuration
1. Set up PocketBase instance
2. Configure collections (see `docs/DATA_MODELS.md`)
3. Update `.env` with PocketBase URL and credentials

## Security

- Single-user authentication
- Biometric unlock support
- Secure token storage (flutter_secure_storage)
- HTTPS enforced for all API calls
- No sensitive data in logs

## Success Criteria

- All portfolio data accessible offline
- Cash flow and debt visible in seconds
- No critical data duplication
- Manual workflows remain fast

## License

MIT License - See LICENSE file for details

## Documentation

Full development documentation available in `docs/` folder:
- [Technical Specification](docs/SPEC.md)
- [User Stories](docs/USER_STORIES.md)
- [TODO List](docs/TODO.md)
- [Data Models](docs/DATA_MODELS.md)

---

**Target User**: Property owners/operators managing rental portfolios  
**Platform**: Android only  
**Stage**: MVP Development
