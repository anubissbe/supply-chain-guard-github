# 10 – Why This Works (and What It Doesn't)

## Attack Model (S1ngularity-class)
- A developer or pipeline **installs a malicious dependency** with `postinstall` scripts or runs a **compromised build tool**
- The script **searches the runner** for secrets/tokens and **exfiltrates** via HTTP(S)/DNS
- Sometimes **runtime tampering** occurs (modifying source/artifacts on-the-fly)

## Defense in This Kit

### 1. Runtime Security (StepSecurity Harden-Runner)
- **Network egress monitoring**: Detects and blocks unauthorized outbound connections
- **File integrity monitoring**: Catches source code tampering during builds
- **Process activity monitoring**: Identifies suspicious runtime behavior
- **Real-time detection**: Works like an EDR for CI/CD environments

### 2. Organization-wide Enforcement (Repository Rulesets)
- **Required status checks**: Ensures security workflows run on every PR/push
- **Enterprise rulesets**: Apply security policies across all organizations
- **No bypass options**: Security checks cannot be skipped

### 3. Dependency Hygiene
- **Trivy vulnerability scanning**: Blocks HIGH/CRITICAL vulnerabilities
- **Package install protection**: `npm ci --ignore-scripts` for Node.js builds
- **Dependency analysis**: Automated scanning for malicious packages

### 4. Egress Control (Self-hosted Runners)
- **Kubernetes NetworkPolicies**: Block unauthorized network access
- **Allowlist approach**: Only explicitly permitted endpoints accessible
- **DNS filtering**: Control domain resolution for enhanced security

## What This Doesn't Do
- **GitHub-hosted runner host control**: You can't modify the underlying VM (but Harden-Runner provides runtime monitoring)
- **0-day guarantee**: No tool catches everything, but egress controls provide final safety net
- **Advanced evasion techniques**: Sophisticated attackers may find ways around detection

## Real-World Effectiveness (2025)
- **Detected attacks**: tj-actions/changed-files compromise (CVE-2025-30066)
- **Microsoft project**: Azure Karpenter Provider attack detected within 1 hour
- **Google project**: Flank supply chain attack prevented
- **Scale**: 1M+ workflows protected weekly across 5,000+ projects