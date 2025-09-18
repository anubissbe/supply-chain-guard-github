# Security Policy

## 🛡️ Supported Versions

We actively maintain and provide security updates for the following versions:

| Version | Supported | Notes |
|---------|-----------|-------|
| 1.x.x   | ✅ | Current stable release |
| 0.9.x   | ⚠️ | Security fixes only until Jan 2025 |
| < 0.9   | ❌ | No longer supported |

### Component Version Support

| Component | Version | Support Status |
|-----------|---------|----------------|
| StepSecurity Harden-Runner | v2.11.1+ | ✅ Actively supported |
| Trivy Scanner | v0.23.0+ | ✅ Actively supported |
| GitHub Actions | Latest | ✅ Always use latest |

## 🚨 Reporting a Vulnerability

### Priority Classification

**🔴 Critical (P0)**: Immediate security risk requiring urgent action
- Remote code execution vulnerabilities
- Authentication bypass
- Privilege escalation in CI/CD pipelines
- Supply chain attack vectors

**🟠 High (P1)**: Significant security impact
- Information disclosure vulnerabilities
- Denial of service attacks
- Configuration bypass vulnerabilities

**🟡 Medium (P2)**: Moderate security impact
- Cross-site scripting in reports
- Information leakage
- Workflow manipulation

**🟢 Low (P3)**: Minor security impact
- Configuration recommendations
- Best practice improvements

### Reporting Process

#### 🔒 Private Reporting (Preferred)
For security vulnerabilities, please use **private disclosure**:

1. **GitHub Security Advisories** (Recommended)
   - Navigate to the repository's Security tab
   - Click "Report a vulnerability"
   - Fill out the private vulnerability report form

2. **Email Reporting**
   - **Email**: security@company.com
   - **Subject**: [SECURITY] Supply Chain Guard Vulnerability Report
   - **Encryption**: Use our GPG key for sensitive information

3. **Enterprise Customers**
   - Contact your dedicated security liaison
   - Use established enterprise communication channels
   - Include severity assessment and business impact

#### 📧 GPG Public Key
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[GPG Public Key for security@company.com would be here]
-----END PGP PUBLIC KEY BLOCK-----
```

### Response Timeline

| Severity | Acknowledgment | Initial Assessment | Resolution Target |
|----------|----------------|-------------------|-------------------|
| Critical (P0) | 4 hours | 24 hours | 7 days |
| High (P1) | 24 hours | 72 hours | 30 days |
| Medium (P2) | 72 hours | 1 week | 60 days |
| Low (P3) | 1 week | 2 weeks | 90 days |

### Security Response Process

#### 1. Vulnerability Assessment
- **Verification**: Confirm the vulnerability exists
- **Impact Analysis**: Assess potential impact and affected versions
- **CVSS Scoring**: Calculate severity using CVSS 3.1 framework
- **Affected Systems**: Identify all affected components and versions

#### 2. Coordinated Disclosure
- **Security Advisory**: Create GitHub Security Advisory
- **CVE Assignment**: Request CVE identifier if applicable
- **Stakeholder Notification**: Inform enterprise customers
- **Timeline Coordination**: Establish disclosure timeline with reporter

#### 3. Fix Development
- **Patch Development**: Develop and test security fixes
- **Security Review**: Conduct thorough security review of fixes
- **Regression Testing**: Ensure fixes don't introduce new issues
- **Documentation**: Update security documentation and advisories

#### 4. Release and Disclosure
- **Security Release**: Deploy fixes to supported versions
- **Public Disclosure**: Publish security advisory and CVE details
- **Customer Notification**: Notify all users of security updates
- **Post-Incident Review**: Conduct review to prevent similar issues

## 🔍 Security Auditing

### Regular Security Reviews
- **Code Audits**: Quarterly security code reviews
- **Dependency Scanning**: Automated vulnerability scanning for all dependencies
- **Configuration Review**: Monthly security configuration audits
- **Penetration Testing**: Annual third-party security assessments

### Automated Security Testing
- **SAST**: Static Application Security Testing in CI/CD
- **Dependency Scanning**: Automated vulnerability detection
- **Container Scanning**: Security scanning of all container images
- **Secrets Detection**: Automated detection of committed secrets

## 🏢 Enterprise Security Features

### Security Monitoring
- **Real-time Monitoring**: StepSecurity Harden-Runner provides runtime monitoring
- **Network Egress Control**: Comprehensive outbound connection monitoring
- **File Integrity Monitoring**: Detection of unauthorized file modifications
- **Process Activity Monitoring**: Behavioral analysis of CI/CD processes

### Compliance Standards
- **SOC 2 Type II**: Annual compliance validation
- **ISO 27001**: Information security management certification
- **NIST Framework**: Alignment with cybersecurity framework
- **Industry Standards**: Compliance with sector-specific requirements

### Enterprise Integration
- **SIEM Integration**: Forward security events to enterprise SIEM systems
- **Identity Management**: Integration with enterprise identity providers
- **Audit Logging**: Comprehensive audit trails for compliance
- **Incident Response**: Integration with enterprise incident response procedures

## 🛠️ Security Configuration

### Secure Defaults
- **Egress Policy**: Default-deny network egress policy
- **Action Pinning**: All actions pinned to specific commit SHAs
- **Minimal Permissions**: Least privilege access controls
- **Secrets Management**: Secure handling of sensitive information

### Hardening Guidelines
```yaml
# Example secure configuration
security_configuration:
  harden_runner:
    egress_policy: "block"  # Use "block" in production
    disable_sudo: true
    allowed_endpoints:
      - "github.com:443"
      - "api.github.com:443"
      # Minimal required endpoints only

  repository_rulesets:
    enforcement: "active"  # Enforce security requirements
    bypass_actors: []      # No bypass permissions
    required_status_checks:
      - "Supply Chain Security Enforcement"

  vulnerability_scanning:
    severity_threshold: "HIGH"  # Block HIGH and CRITICAL
    ignore_unfixed: false       # Include all vulnerabilities
    fail_build: true           # Fail on security issues
```

### Security Best Practices
1. **Regular Updates**: Keep all components updated to latest versions
2. **Principle of Least Privilege**: Grant minimal required permissions
3. **Defense in Depth**: Implement multiple security layers
4. **Continuous Monitoring**: Monitor all security events and anomalies
5. **Incident Preparedness**: Maintain incident response procedures

## 📋 Security Checklist

### Deployment Security
- [ ] All actions pinned to specific commit SHAs
- [ ] Egress policy set to "block" in production
- [ ] Vulnerability scanning enabled with appropriate thresholds
- [ ] Repository rulesets configured with "active" enforcement
- [ ] CODEOWNERS file configured for security reviews
- [ ] Security workflows required as status checks
- [ ] Secrets properly configured and scoped
- [ ] Network policies applied for self-hosted runners

### Operational Security
- [ ] Regular security monitoring and log review
- [ ] Quarterly security configuration audits
- [ ] Annual penetration testing completed
- [ ] Incident response procedures documented and tested
- [ ] Security training completed for all team members
- [ ] Vulnerability management process established
- [ ] Business continuity plans validated
- [ ] Compliance requirements verified

## 📊 Security Metrics

### Key Performance Indicators
- **Mean Time to Detection (MTTD)**: Average time to detect security issues
- **Mean Time to Response (MTTR)**: Average time to respond to security incidents
- **Vulnerability Fix Rate**: Percentage of vulnerabilities remediated within SLA
- **Security Training Completion**: Percentage of team members trained
- **Compliance Score**: Overall compliance with security standards

### Reporting
- **Monthly**: Security metrics dashboard for operations teams
- **Quarterly**: Executive security summary and trend analysis
- **Annually**: Comprehensive security posture assessment
- **As Needed**: Incident reports and security advisories

## 🔗 Additional Resources

### Documentation
- [Setup Guide](docs/20-setup-harden-runner.md) - Secure configuration setup
- [Verification Guide](docs/30-verification.md) - Security testing procedures
- [Operations Guide](docs/40-operations.md) - Ongoing security operations

### External Resources
- [StepSecurity Documentation](https://docs.stepsecurity.io/)
- [GitHub Security Best Practices](https://docs.github.com/en/actions/security-guides)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP CI/CD Security Guide](https://owasp.org/www-project-devsecops-guideline/)

### Support Channels
- **Community**: GitHub Discussions for general security questions
- **Enterprise**: Dedicated security liaison for enterprise customers
- **Emergency**: 24/7 security hotline for critical incidents
- **Training**: Security training and awareness programs

---

**Security Contact**: security@company.com
**Last Updated**: 2025-01-15
**Next Review**: 2025-04-15

*This security policy is reviewed quarterly and updated as needed to address emerging threats and changing requirements.*