# Enterprise Central Enforcement - No Pipeline Modifications Needed

## The Problem
- 1600 repositories with existing build pipelines
- Cannot modify each pipeline individually
- Need centralized enforcement

## The Solution: Enterprise-Level Enforcement

### Method 1: GitHub Enterprise Required Workflows (Best Option)

**Location**: GitHub Enterprise Settings → Actions → Required workflows

This creates a SINGLE workflow that runs on ALL repositories automatically, WITHOUT modifying any existing pipelines.

#### Step 1: Create Required Workflow at Enterprise Level

Navigate to: `https://github.com/enterprises/YOUR-ENTERPRISE/settings/actions`

Create this required workflow that runs BEFORE any other workflows:

```yaml
name: Enterprise NPM Security Gate
on:
  workflow_run:
    workflows: ["*"]
    types: [requested]
  pull_request:
    types: [opened, synchronize, reopened]
  push:
    branches: ["*"]

jobs:
  security-gate:
    name: Security Gate Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for malicious npm packages
        run: |
          MALICIOUS_HASHES=(
            "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
            "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
            "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
            "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
          )

          FOUND=false
          for file in $(find . -type f -name "*.js" -o -name "*.mjs" -o -name "*.cjs" 2>/dev/null); do
            if [ -f "$file" ]; then
              HASH=$(sha256sum "$file" | cut -d" " -f1)
              for KNOWN in "${MALICIOUS_HASHES[@]}"; do
                if [ "$HASH" = "$KNOWN" ]; then
                  echo "::error::CRITICAL: Malicious npm package detected"
                  echo "File: $file"
                  echo "SHA256: $HASH"
                  FOUND=true
                fi
              done
            fi
          done

          if [ "$FOUND" = true ]; then
            echo "::error::Security gate FAILED - All workflows blocked"
            exit 1
          fi
```

#### Step 2: Configure Required Workflow Settings

1. **Scope**: All organizations in enterprise
2. **Repository selection**: All repositories
3. **Enforcement**: Immediately active
4. **Bypass list**: Empty (no one can bypass)

### Method 2: Organization-Level Rulesets with Required Status Checks

If Required Workflows aren't available, use Organization Rulesets that enforce status checks WITHOUT touching pipelines:

#### Deploy to All 10 Organizations

```bash
#!/bin/bash
# Deploy organization rulesets that require security checks

ORGS="org1 org2 org3 org4 org5 org6 org7 org8 org9 org10"

for ORG in $ORGS; do
  echo "Creating ruleset for $ORG..."

  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /orgs/$ORG/rulesets \
    -f name="Enterprise NPM Security" \
    -f target="branch" \
    -f enforcement="active" \
    --field conditions='{
      "ref_name": {
        "include": ["~ALL"],
        "exclude": []
      }
    }' \
    --field rules='[
      {
        "type": "required_workflows",
        "parameters": {
          "required_workflows": [
            {
              "path": ".github/workflows/npm-security.yml",
              "repository_id": YOUR_SECURITY_REPO_ID,
              "ref": "main"
            }
          ]
        }
      }
    ]' \
    --field bypass_actors='[]'
done
```

### Method 3: Pre-receive Hooks (GitHub Enterprise Server)

For GitHub Enterprise Server, use pre-receive hooks that block at the Git level:

```bash
#!/bin/bash
# Pre-receive hook - blocks at Git push level
# Place in: /data/user/git-hooks/pre-receive-npm-security

MALICIOUS_HASHES="
46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09
b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777
dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c
4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db
"

while read oldrev newrev refname; do
  # Check all JS files in the push
  for file in $(git diff-tree --no-commit-id --name-only -r $newrev | grep '\.js$\|\.mjs$\|\.cjs$'); do
    content=$(git show $newrev:$file 2>/dev/null || true)
    if [ -n "$content" ]; then
      hash=$(echo "$content" | sha256sum | cut -d' ' -f1)

      if echo "$MALICIOUS_HASHES" | grep -q "$hash"; then
        echo "ERROR: Push rejected - malicious npm package detected"
        echo "File: $file"
        echo "SHA256: $hash"
        echo ""
        echo "This push contains known malicious code and has been blocked."
        echo "Contact security team for assistance."
        exit 1
      fi
    fi
  done
done

exit 0
```

Enable globally:
```bash
sudo -u git cp pre-receive-npm-security /opt/github/git-hooks/
sudo -u git chmod +x /opt/github/git-hooks/pre-receive-npm-security
ghe-config app.github.pre-receive-hook-dir /opt/github/git-hooks
ghe-config-apply
```

### Method 4: GitHub Advanced Security Custom Patterns

If you have GitHub Advanced Security, create custom secret scanning patterns:

```yaml
patterns:
  - pattern: |
      46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09|
      b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777|
      dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c|
      4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db
    type: malicious_npm_hash
    severity: critical
    message: "Malicious npm package detected"
```

## How Each Method Works WITHOUT Modifying Pipelines

### Required Workflows (Method 1)
- ✅ Runs AUTOMATICALLY on every push/PR
- ✅ Runs BEFORE user pipelines
- ✅ Blocks ALL downstream workflows if it fails
- ✅ No changes to existing pipelines needed
- ✅ Centrally managed from Enterprise settings

### Organization Rulesets (Method 2)
- ✅ Creates required status check
- ✅ Blocks merges if check fails
- ✅ Applies to ALL branches
- ✅ No pipeline modifications
- ✅ Works with existing CI/CD

### Pre-receive Hooks (Method 3)
- ✅ Blocks at Git level (before GitHub Actions)
- ✅ Works regardless of pipelines
- ✅ Cannot be bypassed by users
- ✅ Instant rejection of malicious code
- ✅ No workflow needed at all

### Advanced Security (Method 4)
- ✅ Automatic scanning on push
- ✅ Blocks PR merges
- ✅ Security alerts
- ✅ No workflow changes
- ✅ Enterprise-wide coverage

## Recommended Approach for 1600 Repos

**For GitHub Enterprise Cloud:**
1. Use Required Workflows (Method 1) if available
2. Fall back to Organization Rulesets (Method 2)
3. Enable Advanced Security patterns (Method 4) as additional layer

**For GitHub Enterprise Server:**
1. Use Pre-receive Hooks (Method 3) - most effective
2. Add Organization Rulesets as secondary protection

## Implementation Without Pipeline Changes

### Step 1: Choose Your Method
- Check if Required Workflows is enabled in your Enterprise
- If not, use Organization Rulesets or Pre-receive Hooks

### Step 2: Deploy Centrally
- ONE configuration at Enterprise/Organization level
- Applies to ALL 1600 repositories instantly
- No need to touch individual pipelines

### Step 3: Test on One Organization
```bash
# Test with one org first
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /orgs/TEST-ORG/rulesets \
  --input npm-security-minimal.json
```

### Step 4: Deploy to All Organizations
```bash
# Deploy to all 10 organizations
./scripts/deploy-organization-rulesets.sh
```

## Key Points

1. **NO PIPELINE MODIFICATIONS NEEDED** - All methods work at enterprise/org level
2. **INSTANT COVERAGE** - Protects all 1600 repos immediately
3. **CENTRALLY MANAGED** - One place to update/maintain
4. **CANNOT BE BYPASSED** - Users can't disable in their pipelines
5. **WORKS WITH EXISTING CI/CD** - Doesn't interfere with current builds

## Summary

You do NOT need to modify 1600 build pipelines. The protection can be enforced at:
- **Enterprise level** (Required Workflows)
- **Organization level** (Rulesets)
- **Git level** (Pre-receive Hooks)
- **Security scanning level** (Advanced Security)

All these methods work WITHOUT touching individual repository pipelines!