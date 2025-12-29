---
trigger: model_decision
description: Not in prototype or poc
---

# Performance Budgets & Benchmarks

## ⏱️ Web Vitals Targets
- **MVP**:
  - Largest Contentful Paint < 2.5s
  - First Input Delay < 100ms
  - CLS < 0.1
- **Enterprise/SaaS**:
  - All vitals must pass on average devices/networks

## 📦 Bundle Size
- Initial JS bundle < 250KB (gzipped) in MVP
- < 150KB preferred in production SaaS

## 🔍 Monitoring
- Use Lighthouse CI or WebPageTest
- Report regressions in Slack on deployment
- Block deploy if performance drops >10%

## 🔁 Audits
- Monthly performance audits
- Bundle analyzer reports on each PR
