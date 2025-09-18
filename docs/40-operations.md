# 40 – Operations & Lifecycle

## A. Security Monitoring Operations

### Daily Operations
- **StepSecurity Dashboard Review**: Check for new security alerts and anomalies
- **Failed Workflow Investigation**: Analyze any security check failures
- **Allowlist Maintenance**: Review and approve new endpoint requests

### Weekly Operations
- **Security Metrics Review**: Analyze trends in security violations
- **Ruleset Effectiveness**: Evaluate enforcement success rates
- **Performance Impact Assessment**: Monitor workflow execution times

### Monthly Operations
- **Allowlist Audit**: Review all allowed endpoints for continued necessity
- **Security Policy Review**: Assess and update security requirements
- **Incident Response Testing**: Conduct tabletop exercises

## B. Allowlist Management Lifecycle

### Adding New Endpoints
1. **Request Process**: Developers submit endpoint requests via issue/ticket
2. **Security Review**: Security team validates business need and risk
3. **Approval**: Authorized approver signs off on addition
4. **Implementation**: Update workflow allowlists and deploy
5. **Verification**: Test that new endpoint works as expected

### Endpoint Review Process
```yaml
# Quarterly endpoint audit checklist
- [ ] Business justification still valid
- [ ] Endpoint still maintained and secure
- [ ] No alternative internal solutions available
- [ ] Minimal required permissions in use
- [ ] Endpoint usage monitored and logged
```

### Emergency Endpoint Addition
1. **Incident Declaration**: Security incident requiring emergency access
2. **Temporary Bypass**: Limited-time bypass with approval
3. **Post-Incident Review**: Analyze need and formalize if required
4. **Process Improvement**: Update procedures based on lessons learned

## C. Repository Ruleset Lifecycle

### Ruleset Updates
1. **Change Proposal**: Document proposed changes with justification
2. **Impact Assessment**: Analyze effect on existing repositories
3. **Testing**: Validate changes in test environment
4. **Staged Rollout**: Deploy to subset of repositories first
5. **Full Deployment**: Apply to all target repositories
6. **Monitoring**: Watch for issues and rollback if needed

### New Repository Onboarding
```yaml
# Automated repository setup checklist
- [ ] Security workflow template applied
- [ ] Repository rulesets inherited
- [ ] Custom properties configured
- [ ] Security team added to CODEOWNERS
- [ ] Branch protection rules active
- [ ] Initial security scan completed
```

## D. Incident Response Procedures

### Security Alert Response (Harden-Runner Detection)
1. **Alert Triage** (< 15 minutes)
   - Classify severity (Critical/High/Medium/Low)
   - Identify affected systems and data
   - Assign incident commander

2. **Immediate Response** (< 30 minutes)
   - Isolate affected runner/workflow
   - Preserve evidence (logs, network data)
   - Notify stakeholders per severity

3. **Investigation** (< 2 hours)
   - Analyze StepSecurity telemetry data
   - Review workflow logs and changes
   - Identify attack vector and scope

4. **Containment** (< 4 hours)
   - Update allowlists to block malicious endpoints
   - Revoke potentially compromised tokens
   - Update repository rulesets if needed

5. **Recovery** (< 24 hours)
   - Deploy patched workflows
   - Verify security controls effective
   - Resume normal operations

6. **Post-Incident** (< 1 week)
   - Document lessons learned
   - Update procedures and controls
   - Conduct stakeholder review

### Supply Chain Compromise Response
```yaml
# Critical supply chain incident checklist
- [ ] Isolate affected repositories and workflows
- [ ] Inventory potentially affected builds/deployments
- [ ] Scan for indicators of compromise (IoCs)
- [ ] Update dependency scanning rules
- [ ] Notify downstream consumers
- [ ] Coordinate with security vendors
- [ ] Update allowlists and security policies
```

## E. Continuous Improvement

### Security Metrics Collection
- **Detection Rate**: Percentage of attacks caught by Harden-Runner
- **False Positive Rate**: Legitimate activities incorrectly flagged
- **Response Time**: Time from detection to containment
- **Coverage**: Percentage of repositories with security controls

### Performance Monitoring
- **Workflow Duration**: Impact of security controls on build times
- **Runner Utilization**: Resource consumption by security monitoring
- **Developer Experience**: Friction introduced by security measures

### Regular Reviews
- **Quarterly Security Review**: Assess overall security posture
- **Annual Architecture Review**: Evaluate and update security design
- **Bi-annual Penetration Testing**: External validation of controls

## F. Documentation and Training

### Documentation Maintenance
- **Runbooks**: Keep incident response procedures current
- **Architecture Diagrams**: Update security control diagrams
- **Configuration Management**: Version control all security configs

### Training Program
- **Developer Onboarding**: Security workflow training for new team members
- **Security Awareness**: Regular updates on supply chain threats
- **Incident Response**: Tabletop exercises and simulations

## G. Vendor Management

### StepSecurity Relationship
- **Service Level Agreements**: Monitor compliance with SLAs
- **Feature Roadmap**: Stay informed about new capabilities
- **Support Escalation**: Maintain contacts for critical issues
- **Cost Optimization**: Regular review of usage and licensing

### Alternative Solutions
- **Market Assessment**: Monitor competitive landscape
- **Proof of Concepts**: Test alternative security solutions
- **Migration Planning**: Maintain readiness for vendor changes