# 25 – Repository Rulesets (Organization-wide Enforcement)

With **Repository Rulesets**, you can enforce security workflows across multiple repositories from a single configuration point. This replaces the deprecated "Required Workflows" feature.

## Enterprise-Level Rulesets (2025)

### Step 1: Create Enterprise Ruleset
1. Navigate to **Enterprise Settings** → **Policies** → **Repository rulesets**
2. Click **New ruleset** → **New branch ruleset**
3. Configure targeting:
   - **Target**: All repositories or specific organizations
   - **Branches**: Default branches (main/master)
   - **Repository properties**: Production/staging environments

### Step 2: Configure Security Rules
```json
{
  "name": "Enterprise Supply Chain Guard",
  "enforcement": "active",
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [
          {
            "context": "Supply Chain Security Enforcement"
          },
          {
            "context": "Security / Harden Runner"
          }
        ],
        "strict_required_status_checks_policy": true
      }
    }
  ]
}
```

## Organization-Level Rulesets

### Step 1: Create Security Workflow Template
1. Create a `.github` repository in your organization
2. Add `workflow-templates/supply-chain-security.yml`
3. Include the Harden-Runner workflow from this repository

### Step 2: Organization Ruleset Setup
1. Go to **Organization Settings** → **Rules** → **Rulesets**
2. Create new branch ruleset
3. Target: All repositories or filtered by name/property
4. Add required status checks for security workflows

## Repository Properties (Custom Classification)

### Define Security Levels
```yaml
# Repository custom properties
environment:
  - production
  - staging
  - development

security_level:
  - critical
  - high
  - medium
  - low

compliance_framework:
  - sox
  - pci-dss
  - hipaa
  - gdpr
```

### Conditional Rulesets
Create different rulesets based on repository properties:
- **Critical**: Require 2 approvals + all security checks
- **High**: Require 1 approval + security checks
- **Medium**: Security checks only

## Multi-Organization Strategy

### Centralized Security Repository
1. Create `org-security-policies` repository
2. Store reusable workflows and rulesets
3. Reference from organization templates

### Cross-Organization Sharing
```yaml
# In organization .github repository
name: Import Enterprise Security
on: [push, pull_request]

jobs:
  security:
    uses: enterprise-org/security-policies/.github/workflows/supply-chain-security.yml@main
```

## Enforcement Levels

### Evaluate Mode
- **Purpose**: Test rulesets without blocking
- **Action**: Log violations, allow merge
- **Use case**: Initial rollout and testing

### Active Mode
- **Purpose**: Enforce all rules strictly
- **Action**: Block merge on violations
- **Use case**: Production enforcement

## Best Practices

### Gradual Rollout
1. Start with **evaluate** mode
2. Monitor violations and adjust rules
3. Switch to **active** mode for enforcement
4. Use bypass sparingly and with approval

### Bypass Controls
- **Delegated bypass**: Require approval for emergency changes
- **Time-limited**: Set expiration on bypass permissions
- **Audit trail**: Track all bypass usage

### Rule Management
- **Version control**: Store ruleset configs in git
- **Testing**: Validate rulesets in test organizations
- **Documentation**: Clearly document rule purposes