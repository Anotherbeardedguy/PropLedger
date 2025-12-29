# PocketBase Setup Guide

This guide walks you through setting up PocketBase for PropLedger.

## Option 1: Local Development Setup

### Download PocketBase

1. Visit [PocketBase releases](https://github.com/pocketbase/pocketbase/releases)
2. Download the appropriate version for your OS
3. Extract the executable

### Run PocketBase

```bash
# Windows
pocketbase.exe serve

# Linux/Mac
./pocketbase serve
```

PocketBase will start on `http://127.0.0.1:8090`

### Create Admin Account

1. Open `http://127.0.0.1:8090/_/` in your browser
2. Create an admin account
3. You'll be logged into the admin dashboard

## Option 2: Production VPS Setup

### Prerequisites
- A VPS (Ubuntu 20.04+ recommended)
- Domain name (optional but recommended)
- SSH access

### Installation Steps

```bash
# SSH into your VPS
ssh user@your-server.com

# Download PocketBase
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip

# Extract
unzip pocketbase_0.20.0_linux_amd64.zip

# Make executable
chmod +x pocketbase

# Create systemd service
sudo nano /etc/systemd/system/pocketbase.service
```

### Systemd Service File

```ini
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/home/your-username/pocketbase
ExecStart=/home/your-username/pocketbase/pocketbase serve --http="0.0.0.0:8090"
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Enable and Start Service

```bash
sudo systemctl enable pocketbase
sudo systemctl start pocketbase
sudo systemctl status pocketbase
```

### Setup Nginx Reverse Proxy (Optional)

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Setup SSL with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Configure Collections

### 1. Users Collection (Built-in)

Already exists by default. Ensure these settings:
- Auth enabled: ✓
- API rules configured for authenticated users

### 2. Create Collections via Admin UI

Navigate to `Settings > Collections` and create the following:

#### Properties Collection
```json
{
  "name": "properties",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "address", "type": "text", "required": true},
    {"name": "purchase_date", "type": "date"},
    {"name": "purchase_price", "type": "number"},
    {"name": "estimated_value", "type": "number"},
    {"name": "notes", "type": "text"}
  ]
}
```

**API Rules:**
- List: `@request.auth.id != ""`
- View: `@request.auth.id != ""`
- Create: `@request.auth.id != ""`
- Update: `@request.auth.id != ""`
- Delete: `@request.auth.id != ""`

#### Units Collection
```json
{
  "name": "units",
  "schema": [
    {"name": "property_id", "type": "relation", "required": true, "options": {"collectionId": "properties", "cascadeDelete": true}},
    {"name": "unit_name", "type": "text", "required": true},
    {"name": "size_sqm", "type": "number"},
    {"name": "rooms", "type": "number"},
    {"name": "rent_amount", "type": "number", "required": true},
    {"name": "status", "type": "select", "required": true, "options": {"values": ["vacant", "occupied"]}},
    {"name": "notes", "type": "text"}
  ]
}
```

**API Rules:** Same as Properties

#### Tenants Collection
```json
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

**API Rules:** Same as Properties

#### RentPayments Collection
```json
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

**API Rules:** Same as Properties

#### Expenses Collection
```json
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

**API Rules:** Same as Properties

#### MaintenanceTasks Collection
```json
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

**API Rules:** Same as Properties

#### Loans Collection
```json
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

**API Rules:** Same as Properties

#### LoanPayments Collection
```json
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

**API Rules:** Same as Properties

#### Documents Collection
```json
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

**API Rules:** Same as Properties

## Configure App Environment

Create `.env` file in project root:

```env
# For local development
POCKETBASE_URL=http://10.0.2.2:8090
APP_ENV=development

# For production
# POCKETBASE_URL=https://your-domain.com
# APP_ENV=production
```

**Note:** `10.0.2.2` is the Android emulator's alias for localhost.

## Backup Configuration

### Automated Backups

Create a backup script:

```bash
#!/bin/bash
BACKUP_DIR="/backups/pocketbase"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
cp -r /home/user/pocketbase/pb_data "$BACKUP_DIR/pb_data_$DATE"
find $BACKUP_DIR -mtime +7 -delete
```

Add to crontab:
```bash
0 2 * * * /path/to/backup-script.sh
```

## Testing Authentication

### Create Test User

1. Go to PocketBase Admin > Collections > users
2. Click "New record"
3. Fill in:
   - Email: `test@propledger.com`
   - Password: `testpassword123`
4. Save

### Test in App

1. Run the Flutter app
2. Enter test credentials
3. You should be logged in and see the dashboard

## Troubleshooting

### CORS Issues
Add to PocketBase startup:
```bash
pocketbase serve --origins="*"
```

### Connection Refused
- Check firewall rules
- Ensure PocketBase is running
- Verify URL in `.env` file

### Authentication Failed
- Verify user exists in PocketBase admin
- Check email/password are correct
- Review PocketBase logs for errors

## Security Recommendations

1. **Change admin password** immediately after setup
2. **Enable HTTPS** in production
3. **Restrict API rules** to authenticated users only
4. **Set up backups** before going to production
5. **Use environment variables** for sensitive data
6. **Keep PocketBase updated** to latest version

## Next Steps

Once PocketBase is configured:
1. Create your first user via admin panel
2. Test login in the app
3. Start building CRUD operations for collections
4. Implement local Drift database for offline support
