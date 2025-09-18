# Supply‑Chain Guard Kit for **GitHub Enterprise** (Multi‑Org)

**Purpose**: A practical, open‑source kit to **prevent**, **verify** and **enforce** S1ngularity‑style exfiltration attacks in CI/CD pipelines across GitHub Enterprise organizations.

Focus: **GitHub Enterprise Cloud/Server** with multiple organizations and **self-hosted + GitHub-hosted runners**.

> **TL;DR**
> - Use **StepSecurity Harden‑Runner** for **runtime monitoring** and **egress control**
> - Enforce **organization-wide** via **Repository Rulesets** that require security workflows
> - Add extra checks (Trivy vulnerability scanning, npm install without scripts)

**Key Advantage**: StepSecurity Harden‑Runner **natively supports both GitHub-hosted and self-hosted runners** with comprehensive runtime security monitoring.

### What's in this repository

- `docs/` — Human guides (architecture, setup, verification, operations)
- `.github/workflows/` — **Required security workflows** (Harden-Runner, egress verification, Trivy scanning)
- `.github/rulesets/` — **Repository Ruleset** examples for organization-wide enforcement
- `network-policies/` — **Kubernetes NetworkPolicy** examples for self-hosted runner egress control

---

## 🚀 Quick Start

1. **Enable Harden-Runner** on your workflows
2. **Create Repository Rulesets** to enforce security workflows
3. **Configure runner security** (self-hosted) or rely on GitHub-hosted security
4. **Monitor and verify** through StepSecurity dashboard

## 🏢 Enterprise Multi-Organization Support

- **Enterprise Rulesets**: Enforce security across all organizations
- **Template Repositories**: Share security workflows across orgs
- **Custom Repository Properties**: Classify and secure repositories by sensitivity

---

**Last updated**: 2025-09-18