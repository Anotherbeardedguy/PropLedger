---
trigger: model_decision
description: minimum requirement: Stage = MVP
---

# Security & Compliance Checklist

## 🔐 Secrets Management
- ❌ No secrets in code
- ✅ Use `.env` + `.env.example` template
- ✅ Add `.env*` to `.gitignore`

## ✅ Authentication & Authorization
- MVP+: Token-based auth required (JWT or similar)
- Enterprise+: Role-based access enforcement
- SaaS: Multi-tenant auth isolation

## 🧼 Data Practices
- PII must be encrypted at rest (SaaS)
- Purge test data from staging weekly
- GDPR opt-out and retention policies documented

## 🧪 Security Tests
- Lint for secrets (e.g., GitLeaks)
- SAST and SCA scans in CI (Enterprise+)
- Dependency audits weekly

## 📜 Policies
- Incident response doc (SaaS)
- Audit logs for sensitive actions
