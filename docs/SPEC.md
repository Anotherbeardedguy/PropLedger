# PropLedger - Technical Specification

## 1. System Overview

### Purpose
PropLedger is a personal Android mobile application for managing rental property portfolios, providing offline-first property, tenant, financial, and maintenance tracking.

### Architecture Pattern
- **Presentation Layer**: Flutter widgets with Material 3
- **State Management**: Riverpod or Bloc (to be decided)
- **Business Logic**: Repository pattern
- **Data Layer**: Dual-source (Local SQLite + Remote PocketBase)
- **Sync Strategy**: Write-through caching with manual conflict resolution

### Tech Stack

#### Frontend
- **Framework**: Flutter (stable channel)
- **Language**: Dart 3.x
- **UI**: Material 3 design system
- **State Management**: Riverpod/Bloc (single choice enforced)
- **Local Database**: SQLite with Drift ORM
- **Secure Storage**: flutter_secure_storage
- **HTTP Client**: dio with retry logic

#### Backend
- **Backend-as-a-Service**: PocketBase (self-hosted)
- **API Protocol**: REST
- **Authentication**: JWT with email/password
- **File Storage**: PocketBase file storage
- **Backup**: Daily automated backups (server-side)

#### Infrastructure
- **Hosting**: VPS or local server for PocketBase
- **Transport**: HTTPS only
- **Database**: SQLite (PocketBase internal)

## 2. Application Structure

### Navigation Architecture
```
Root
├── Splash/Auth Flow
└── Main App (Bottom Navigation)
    ├── Dashboard
    ├── Properties
    │   └── Property Detail
    │       ├── Units Tab
    │       ├── Tenants Tab
    │       ├── Loans Tab
    │       └── Documents Tab
    ├── Maintenance
    ├── Expenses
    ├── Reports
    └── Settings
```

### Module Structure
```
lib/
├── app/
│   ├── app.dart                    # MaterialApp configuration
│   ├── routes.dart                 # App routing
│   └── env.dart                    # Environment config
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants
│   │   └── api_constants.dart      # API endpoints
│   ├── theme/
│   │   ├── app_theme.dart          # Material 3 theme
│   │   └── colors.dart             # Color palette
│   ├── utils/
│   │   ├── date_utils.dart         # Date formatting
│   │   ├── currency_utils.dart     # Money formatting
│   │   └── validators.dart         # Input validation
│   └── errors/
│       └── exceptions.dart         # Custom exceptions
├── data/
│   ├── models/
│   │   ├── property.dart
│   │   ├── unit.dart
│   │   ├── tenant.dart
│   │   ├── rent_payment.dart
│   │   ├── expense.dart
│   │   ├── maintenance_task.dart
│   │   ├── loan.dart
│   │   ├── loan_payment.dart
│   │   └── document.dart
│   ├── repositories/
│   │   ├── property_repository.dart
│   │   ├── tenant_repository.dart
│   │   ├── financial_repository.dart
│   │   └── auth_repository.dart
│   ├── local/
│   │   ├── database.dart           # Drift database
│   │   └── dao/                    # Data access objects
│   └── remote/
│       ├── pocketbase_client.dart  # PB API client
│       └── sync_service.dart       # Sync logic
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   ├── logic/
│   │   └── widgets/
│   ├── dashboard/
│   ├── properties/
│   ├── tenants/
│   ├── expenses/
│   ├── maintenance/
│   ├── loans/
│   ├── documents/
│   └── reports/
└── main.dart
```

## 3. Data Flow

### Write Flow
1. User action in UI
2. State management dispatches event
3. Repository validates input
4. Write to local SQLite (immediate)
5. Queue sync to PocketBase
6. Update UI from local data
7. Background sync when online

### Read Flow
1. UI requests data via state layer
2. Repository checks local cache
3. Return cached data immediately
4. Optional: trigger background refresh
5. If refresh returns new data, update local
6. Notify UI of changes

### Sync Strategy
- **Priority**: Local-first (UI always reads from SQLite)
- **Conflicts**: Last-write-wins
- **Retry**: Exponential backoff for failed syncs
- **Queue**: Persistent sync queue in local DB

## 4. Security Architecture

### Authentication
- **Method**: Email + Password via PocketBase
- **Token Storage**: flutter_secure_storage
- **Token Lifecycle**: Refresh before expiry
- **Biometric**: Local biometric unlock (optional)
- **Logout**: Clear local token + secure storage

### Data Protection
- **Transport**: HTTPS enforced
- **At Rest**: SQLite file encryption (optional)
- **Files**: Secure file paths, no public storage
- **Logging**: No PII in production logs

### Input Validation
- Client-side validation for UX
- Server-side validation (PocketBase rules)
- Sanitization before display
- File upload restrictions (type, size)

## 5. Performance Requirements

### App Performance
- **Cold Start**: < 3 seconds
- **List Scrolling**: 60fps
- **Database Queries**: < 100ms for lists
- **Navigation**: < 16ms transition animations

### Network
- **API Timeout**: 30 seconds
- **Retry Logic**: 3 attempts with exponential backoff
- **Offline Tolerance**: Full CRUD operations offline

### Storage
- **Initial App Size**: < 50MB
- **Local DB Growth**: Optimized for 1000+ records
- **File Storage**: User-managed via PocketBase

## 6. Quality Standards

### Code Quality
- Dart analyzer warnings at zero
- Explicit return types for functions
- Null safety enforced
- No unused imports

### Testing Strategy (MVP)
- **Manual Testing**: Primary QA method
- **Critical Path Coverage**: Auth, CRUD, sync
- **Edge Cases**: Offline, empty states, errors

### Error Handling
- All network calls wrapped in try-catch
- User-friendly error messages
- Detailed logging for debugging
- Fallback UI for error states

## 7. MVP Constraints

### In Scope
- Android only (iOS excluded)
- Single user authentication
- Manual data entry only
- Offline CRUD operations
- Basic dashboard analytics

### Out of Scope
- Multi-user/multi-tenancy
- Bank account integration
- Automated rent reminders (push notifications)
- Tenant self-service portal
- Accounting software integration
- Real-time collaboration

## 8. Deployment Architecture

### Development
- Local PocketBase instance for testing
- Flutter debug builds

### Production
- PocketBase on VPS or dedicated server
- Flutter release build (signed APK)
- Daily automated backups
- Manual updates via APK distribution

## 9. Monitoring & Observability

### Logging
- Error logs stored locally
- Optional crash reporting (future)
- Network request logging (debug only)

### Analytics (Future)
- App usage patterns
- Feature adoption
- Performance metrics

## 10. Success Metrics

### Technical
- Zero critical bugs in core flows
- < 1% data sync failures
- Offline mode fully functional

### User Experience
- All data accessible in < 3 taps
- Cash flow visible on dashboard load
- No data duplication or loss

### Performance
- 60fps scrolling performance
- < 2 second screen transitions
- < 100ms local database queries
