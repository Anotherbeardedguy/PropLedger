---
trigger: always_on
---

# AI Development Team Roles — Stage-Specific Responsibilities

Each stage of development comes with specific focus and role responsibilities. This spec aligns the Product Owner, Architect, Backend, Frontend, and QA roles to what’s expected per stage.

---

## [stage:QUICK_PROTOTYPE]
> Small, scrappy team. Speed over structure.

- **Product Owner**
  - Clarify core problem and rapid success criteria
  - Approve scrapping outcomes quickly
- **Architect**
  - Optional, or act as senior dev reviewing feasibility
- **Backend / Frontend**
  - 1-2 devs max, work full-stack
  - Skip layering, just prove the idea
- **QA**
  - Manual testing only
  - Focus: “Does it even work?”

---

## [stage:POC]
> Validate technical feasibility. Narrow team, fast iteration.

- **Product Owner**
  - Align technical success with business value
- **Architect**
  - Rough system design
  - Validate feasibility of future scalability
- **Backend**
  - Core logic for technical risk areas
  - API contracts optional
- **Frontend**
  - Just enough UI to show tech works
- **QA**
  - Manual edge-case testing encouraged

---

## [stage:MVP]
> Validate value with real users. Get feedback.

- **Product Owner**
  - Define core value props and key flows
  - Prioritize ruthless scoping
- **Architect**
  - Modular system planning
  - Anticipate scale while staying lean
- **Backend**
  - Define & implement stable APIs
  - Begin data model & persistence
- **Frontend**
  - Build real UI with interaction hooks
  - Accessibility and responsiveness start here
- **QA**
  - Define test plans
  - Manual + some automation (critical flows)

---

## [stage:ENTERPRISE]
> Software must be reliable, testable, scalable.

- **Product Owner**
  - Ensure alignment with enterprise stakeholder needs
  - Feature flag strategy + acceptance criteria enforcement
- **Architect**
  - Formal architecture review
  - Drive component boundaries, interfaces
- **Backend**
  - Enforce API contracts, security, validation layers
  - Cover DB migrations, caching, queuing
- **Frontend**
  - Integrate robust state management
  - Full test coverage, Storybook stories
- **QA**
  - Own test pyramid
  - E2E, regression, accessibility, performance

---

## [stage:SAAS]
> Full production lifecycle. Compliance, observability, uptime.

- **Product Owner**
  - Own OKRs, SLA/SLO targets, pricing & plan enforcement
  - Coordinate go-to-market with feedback loops
- **Architect**
  - Drive infra design, observability, horizontal scaling
  - Data isolation/multi-tenancy if needed
- **Backend**
  - Own uptime, traceability, DB integrity, rate limiting
- **Frontend**
  - Smooth UX, fallback states, multi-region readiness
- **QA**
  - Production incident drills
  - Define uptime monitors, track business KPIs

---

## 💡 Tip

Roles expand with scale. Same people may cover multiple roles in early stages — split responsibilities explicitly in `ENTERPRISE` and `SAAS`.
