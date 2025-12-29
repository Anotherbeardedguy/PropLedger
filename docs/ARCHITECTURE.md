# PropLedger - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────┐
│         Flutter App (Android)       │
├─────────────────────────────────────┤
│  Presentation Layer (UI/Widgets)    │
│  State Management (Riverpod/Bloc)   │
│  Business Logic (Repositories)      │
│  Data Layer (Local + Remote)        │
└─────────────────────────────────────┘
           ↓            ↑
        [HTTPS]      [Offline]
           ↓            ↑
┌─────────────────────────────────────┐
│        PocketBase Backend           │
│  (REST API + File Storage)          │
└─────────────────────────────────────┘
```

## Offline-First Strategy

1. **All reads** from local SQLite database
2. **All writes** go to local first, then queued for sync
3. **Background sync** when network available
4. **Conflict resolution** uses last-write-wins

## Key Design Patterns

- **Repository Pattern**: Abstracts data sources
- **Write-Through Cache**: Local + remote writes
- **State Management**: Single source of truth
- **Error Boundaries**: Graceful degradation

## Technology Stack Summary

| Layer | Technology |
|-------|------------|
| UI | Flutter Material 3 |
| State | Riverpod/Bloc |
| Local DB | SQLite + Drift |
| Network | Dio HTTP client |
| Backend | PocketBase |
| Auth | JWT tokens |
| Storage | flutter_secure_storage |

## Security Layers

1. HTTPS transport encryption
2. JWT authentication
3. Secure local token storage
4. Input validation (client + server)
5. File upload restrictions
