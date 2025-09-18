# 00 – Scope & Assumptions

- **Platform**: GitHub Enterprise (GitHub.com or GitHub Enterprise Server)
- **Runners**: Supports both **GitHub-hosted** and **self-hosted runners**
- **Why GitHub-hosted is secure**: GitHub provides ephemeral VMs with network isolation and encrypted storage
- **Why self-hosted needs hardening**: You control the infrastructure, so you're responsible for security
- **Multi-organization**: Enterprise-level policies can enforce security across all organizations
- **StepSecurity Harden-Runner**: Native support for both runner types with runtime monitoring

## Key Advantages over GitLab Approach

- **Native runtime security**: StepSecurity Harden-Runner provides EDR-like monitoring
- **Proven detection**: Real-world attack detections in 2025 (tj-actions/changed-files compromise)
- **Enterprise scalability**: Over 1 million workflow runs protected weekly
- **Multi-platform support**: GitHub-hosted, self-hosted, ARM runners all supported