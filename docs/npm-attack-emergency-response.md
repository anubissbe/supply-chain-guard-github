# 🚨 EMERGENCY: NPM Supply Chain Attack Response

**CRITICAL**: Active npm supply chain attack detected with known malicious file hashes

## Immediate Action Required

### 1-Minute Emergency Deployment

```bash
# Clone the protection kit
git clone https://github.com/anubissbe/supply-chain-guard-github.git
cd supply-chain-guard-github

# Run emergency deployment
./scripts/emergency-npm-protection.sh
```

This will:
- ✅ Block known malicious file hashes
- ✅ Scan all JavaScript files for compromise
- ✅ Require PR approval before any merges
- ✅ Generate security reports

## Known Malicious Hashes (IOCs)

Files with these SHA256 hashes are **confirmed malicious**:

```
46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09
b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777
dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c
4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db
```

**File typically named**: `bundle.js`

## Manual Quick Check

Check your repositories NOW:

```bash
# Find all bundle.js files
find . -name "bundle.js" -type f

# Check hash of suspicious files
sha256sum bundle.js

# Compare with known malicious hashes above
```

## GitHub CLI Quick Protection

If you can't run the full script, deploy manually:

```bash
# 1. Add the workflow to a repository
curl -o .github/workflows/npm-hash-check.yml \
  https://raw.githubusercontent.com/anubissbe/supply-chain-guard-github/main/.github/workflows/emergency-npm-hash-check.yml

# 2. Commit and push
git add .github/workflows/npm-hash-check.yml
git commit -m "SECURITY: Add npm attack detection"
git push

# 3. Run the workflow
gh workflow run "Emergency NPM Attack Detection"
```

## Enterprise-Wide Protection

For GitHub Enterprise organizations:

### Option A: Repository Ruleset (Fastest)

1. Go to **Organization Settings** → **Repository** → **Repository rulesets**
2. Click **New ruleset**
3. Configure:
   - **Name**: Emergency NPM Attack Block
   - **Enforcement**: Active
   - **Target**: All repositories
   - **Rules**:
     - ✅ Require status checks: `security/file-hash-check`
     - ✅ Require pull request reviews
     - ✅ Block force pushes

### Option B: GitHub Actions Required Workflow

```yaml
# .github/workflows/required/npm-security.yml
name: Required NPM Security Check
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check for malicious hashes
        run: |
          # Paste the hash check script here
          # (from emergency-npm-hash-check.yml)
```

## Detection Script

Quick bash script for immediate detection:

```bash
#!/bin/bash
# Save as check-npm-attack.sh

MALICIOUS_HASHES=(
  "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
  "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
  "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
  "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
)

echo "Scanning for malicious npm packages..."
FOUND=false

for file in $(find . -name "*.js" -type f); do
  HASH=$(sha256sum "$file" | cut -d' ' -f1)
  for KNOWN in "${MALICIOUS_HASHES[@]}"; do
    if [ "$HASH" = "$KNOWN" ]; then
      echo "❌ INFECTED: $file"
      FOUND=true
    fi
  done
done

if [ "$FOUND" = true ]; then
  echo "⚠️ CRITICAL: Malicious files detected!"
  exit 1
else
  echo "✅ No known malicious files found"
fi
```

## If You're Already Infected

1. **IMMEDIATELY**:
   - Rotate ALL secrets and tokens
   - Review git history for unauthorized commits
   - Check CI/CD logs for data exfiltration

2. **Clean the infection**:
   ```bash
   # Remove infected packages
   rm -rf node_modules package-lock.json

   # Reinstall with scripts disabled
   npm install --ignore-scripts

   # Audit all dependencies
   npm audit
   ```

3. **Prevent reinfection**:
   - Enable the security workflow
   - Use `--ignore-scripts` for all npm installs
   - Pin all dependency versions

## Contact

**Security Team**: security@yourcompany.com
**Incident Response**: [Create Issue](https://github.com/anubissbe/supply-chain-guard-github/issues/new?labels=security&title=NPM%20Attack%20Detection)

## References

- [GitHub Advisory](https://github.com/advisories)
- [NPM Security](https://docs.npmjs.com/auditing-package-dependencies-for-security-vulnerabilities)
- [StepSecurity Blog](https://blog.stepsecurity.io)

---

**Last Updated**: Real-time
**Severity**: CRITICAL
**Attack Active**: YES