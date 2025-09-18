# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Supply-Chain Guard Kit for GitHub Enterprise** designed to prevent S1ngularity-style exfiltration attacks in CI/CD pipelines across GitHub organizations. The kit leverages StepSecurity Harden-Runner for runtime security monitoring and GitHub Repository Rulesets for organization-wide enforcement.

**Key Security Strategy:**
- StepSecurity Harden-Runner for runtime monitoring and egress control
- Repository Rulesets for organization-wide security workflow enforcement
- Multi-organization support via Enterprise-level policies
- Comprehensive vulnerability scanning and dependency hygiene

## Architecture

### Core Components

1. **Security Workflows** (`.github/workflows/`)
   - `supply-chain-security.yml`: Main security enforcement workflow with Harden-Runner
   - Egress verification, Trivy scanning, package hygiene checks
   - Designed to run on both GitHub-hosted and self-hosted runners

2. **Repository Rulesets** (`.github/rulesets/`)
   - `organization-security-ruleset.json`: Organization-level security enforcement
   - `enterprise-security-ruleset.json`: Enterprise-wide security policies
   - Require security workflows as status checks for PR merging

3. **Network Policies** (`network-policies/`)
   - Kubernetes NetworkPolicy examples for self-hosted runners
   - Default-deny egress with selective allowlisting
   - GitHub endpoint allowlists for necessary connectivity

### Security Layers

1. **Runtime Security**: StepSecurity Harden-Runner monitors network, file, and process activity
2. **Organization Enforcement**: Repository Rulesets require security workflows on all repositories
3. **Vulnerability Scanning**: Trivy scans for HIGH/CRITICAL vulnerabilities
4. **Package Hygiene**: Install dependencies without executing potentially malicious scripts

## Common Commands

### Local Development Testing
```bash
# Test the security workflow locally (requires act or similar)
act pull_request -W .github/workflows/supply-chain-security.yml

# Validate JSON rulesets
cat .github/rulesets/organization-security-ruleset.json | jq .

# Test network policies (requires kubectl)
kubectl apply -f network-policies/ --dry-run=client
```

### Repository Setup
```bash
# Apply security workflow to new repository
cp .github/workflows/supply-chain-security.yml /path/to/new/repo/.github/workflows/

# Import organization ruleset (via GitHub CLI)
gh api -X POST /orgs/ORGNAME/rulesets \
  --input .github/rulesets/organization-security-ruleset.json
```

### Harden-Runner Integration
```yaml
# Add to any workflow as the first step
- name: Harden Runner
  uses: step-security/harden-runner@17d0e2bd7d51742c71671bd19fa12bdc9d40a3d6 # v2.8.1
  with:
    egress-policy: block
    allowed-endpoints: >
      github.com:443
      api.github.com:443
```

## Multi-Organization Deployment

### Enterprise Setup
1. **Enterprise Rulesets**: Create at enterprise level to apply across all organizations
2. **Template Repositories**: Use `.github` repository in each organization for workflow templates
3. **Custom Properties**: Define repository classification (environment, security_level)
4. **Graduated Enforcement**: Start with 'evaluate' mode, progress to 'active' enforcement

### Organization Configuration
1. Create organization `.github` repository
2. Add `workflow-templates/` with security workflows
3. Configure organization-level rulesets referencing security checks
4. Set up CODEOWNERS for security team review

## Security Verification

### Testing Egress Controls
The security workflow includes automated testing:
- Attempts connection to `1.1.1.1` (should fail)
- Verifies allowed endpoints are accessible
- Reports results in workflow logs

### Monitoring Dashboard
- StepSecurity dashboard: https://app.stepsecurity.io/
- Review network connections, file changes, process activity
- Configure alerts for security violations

## Integration Points

### GitHub Features
- **Repository Rulesets**: Enforce security workflows as required status checks
- **Branch Protection**: Prevent direct pushes to protected branches
- **CODEOWNERS**: Require security team review for sensitive changes
- **Security Advisories**: Integration with GitHub's vulnerability database

### Third-party Tools
- **StepSecurity Harden-Runner**: Primary runtime security monitoring
- **Trivy Scanner**: Vulnerability scanning for dependencies and containers
- **Kubernetes NetworkPolicies**: Network-level egress control for self-hosted runners

## Documentation Structure

- `docs/00-scope.md`: Platform scope and assumptions
- `docs/10-why-it-works.md`: Attack model and defense strategy
- `docs/20-setup-harden-runner.md`: StepSecurity Harden-Runner configuration
- `docs/25-repository-rulesets.md`: Organization-wide enforcement setup
- `docs/30-verification.md`: Testing and validation procedures
- `docs/40-operations.md`: Lifecycle management and incident response

## Enterprise Considerations

### Compliance and Governance
- Repository custom properties for classification
- Delegated bypass controls for emergency situations
- Audit trails for all security policy changes
- Regular review cycles for allowlists and policies

### Performance Impact
- Harden-Runner adds ~10-30 seconds to workflow execution
- Network monitoring overhead is minimal on modern runners
- Vulnerability scanning time depends on codebase size

### Scalability
- Supports unlimited repositories per organization
- Enterprise rulesets can target thousands of repositories
- StepSecurity handles millions of workflow runs weekly