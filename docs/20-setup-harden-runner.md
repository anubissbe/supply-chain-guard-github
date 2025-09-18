# 20 – Setup: StepSecurity Harden-Runner

## A. Choose Your Runner Strategy

### GitHub-hosted Runners (Recommended)
- **Built-in security**: Ephemeral VMs with network isolation
- **Zero maintenance**: Automatically updated and secured
- **Harden-Runner support**: Full monitoring and egress control
- **Enterprise features**: ARM runners, eBPF monitoring (Enterprise tier)

### Self-hosted Runners
- **VM runners**: Create golden images with GitLab Runner + security hardening
- **Kubernetes runners**: Use GitHub Actions Runner Controller (ARC) with NetworkPolicies
- **Security responsibility**: You manage the infrastructure security

## B. Basic Harden-Runner Setup

### Step 1: Add to Workflow
Add as the **first step** in every job:

```yaml
steps:
  - name: Harden Runner
    uses: step-security/harden-runner@17d0e2bd7d51742c71671bd19fa12bdc9d40a3d6 # v2.8.1
    with:
      egress-policy: block
      allowed-endpoints: >
        github.com:443
        api.github.com:443
        registry.npmjs.org:443
        pypi.org:443
```

### Step 2: Configure Egress Policy
- **audit**: Monitor and learn (start here)
- **block**: Enforce allowlist (production setting)

### Step 3: Monitor Dashboard
- Access insights at: https://app.stepsecurity.io/
- Review detected network calls and anomalies
- Refine allowlist based on legitimate traffic

## C. Enterprise Configuration

### Multi-Organization Setup
1. **Template repository**: Create `.github` repository with security workflows
2. **Repository rulesets**: Require Harden-Runner in all workflows
3. **Enterprise policies**: Apply across all organizations

### Advanced Features (Enterprise Tier)
- **ARM runner support**: GitHub-hosted ARM runners
- **eBPF monitoring**: Advanced kernel-level monitoring
- **HTTPS request monitoring**: HTTP method and path tracking
- **Private repository support**: Extended security for private repos

## D. Self-hosted Runner Hardening

### Kubernetes (ARC) Setup
1. Install Actions Runner Controller
2. Deploy Harden-Runner daemonset
3. Configure NetworkPolicies (see `network-policies/`)
4. Enable eBPF monitoring

### VM Runner Setup
1. Create golden image with security hardening
2. Install Harden-Runner agent
3. Configure VPC/firewall egress rules
4. Tag runners with security labels

## E. Verification
Test your setup:
```bash
# Should fail if egress is properly blocked
curl -fsS --max-time 5 http://1.1.1.1/

# Should succeed for allowed endpoints
curl -fsS --max-time 5 https://github.com
```