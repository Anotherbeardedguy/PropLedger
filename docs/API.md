# PropLedger - API Documentation

## PocketBase API Integration

PropLedger uses PocketBase REST API for backend operations. This document outlines the key endpoints and usage patterns.

## Base Configuration

```dart
const String baseUrl = 'https://your-pocketbase-instance.com';
const String apiPath = '/api';
```

## Authentication

### Login
```
POST /api/collections/users/auth-with-password
Body: {
  "identity": "user@example.com",
  "password": "password123"
}
Response: {
  "token": "jwt_token",
  "record": {...}
}
```

### Token Refresh
```
POST /api/collections/users/auth-refresh
Headers: Authorization: Bearer {token}
Response: {
  "token": "new_jwt_token",
  "record": {...}
}
```

## CRUD Operations Pattern

All collections follow standard PocketBase CRUD:

### List Records
```
GET /api/collections/{collection}/records
Query params: ?page=1&perPage=50&filter=...&sort=-created
```

### Get Single Record
```
GET /api/collections/{collection}/records/{id}
```

### Create Record
```
POST /api/collections/{collection}/records
Body: JSON object with fields
```

### Update Record
```
PATCH /api/collections/{collection}/records/{id}
Body: JSON object with fields to update
```

### Delete Record
```
DELETE /api/collections/{collection}/records/{id}
```

## Collections

- `properties`
- `units`
- `tenants`
- `rent_payments`
- `expenses`
- `maintenance_tasks`
- `loans`
- `loan_payments`
- `documents`

## File Upload

For collections with file fields (expenses, maintenance_tasks, documents):

```
POST /api/collections/{collection}/records
Content-Type: multipart/form-data
Body: form data with file field
```

## Error Handling

Standard HTTP status codes:
- 200: Success
- 400: Bad request
- 401: Unauthorized
- 404: Not found
- 500: Server error

## Rate Limiting

No explicit rate limits for self-hosted instances.

## Filtering Examples

```
// Get vacant units
?filter=(status='vacant')

// Get overdue rent
?filter=(status='late')

// Get properties by date
?filter=(purchase_date>='2023-01-01')
```

See PocketBase documentation for complete filtering syntax.
