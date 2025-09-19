# GitHub Enterprise: NPM Supply Chain Attack Protection

## 🚨 Enterprise-Wide Emergency Deployment for GitHub

This guide provides step-by-step instructions to protect **ALL GitHub Enterprise organizations and repositories** at once from the active npm supply chain attack.

## Prerequisites

- GitHub Enterprise Cloud or Server
- Enterprise owner or organization admin access
- GitHub CLI (`gh`) installed
- Personal Access Token with admin:org and repo scopes

## Step 1: Enterprise-Level Policy (Fastest Protection)

### 1.1 Access Enterprise Settings

1. Go to `https://github.com/enterprises/YOUR-ENTERPRISE/settings`
2. Navigate to **Policies** → **Actions**

### 1.2 Create Required Workflow

Create a required workflow that runs for ALL organizations:

**Location**: `https://github.com/enterprises/YOUR-ENTERPRISE/settings/actions`

1. Click **New required workflow**
2. Select **All organizations**
3. Add this workflow:

```yaml
name: Enterprise NPM Security Check
on: [push, pull_request]

jobs:
  npm-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for malicious npm packages
        run: |
          # Known malicious hashes
          HASHES=(
            "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
            "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
            "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
            "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
          )

          FOUND=false
          for file in $(find . -name "*.js" -type f); do
            HASH=$(sha256sum "$file" | cut -d' ' -f1)
            for KNOWN in "${HASHES[@]}"; do
              if [ "$HASH" = "$KNOWN" ]; then
                echo "❌ INFECTED: $file"
                FOUND=true
              fi
            done
          done

          if [ "$FOUND" = true ]; then
            echo "⚠️ MALICIOUS FILES DETECTED!"
            exit 1
          fi
```

## Step 2: Organization-Wide Ruleset Deployment

### 2.1 Deploy to All Organizations via API

Save and run this script:

```bash
#!/bin/bash
# deploy-github-enterprise-protection.sh

ENTERPRISE="YOUR-ENTERPRISE"
TOKEN="YOUR-PAT-TOKEN"

# Get all organizations in enterprise
ORGS=$(gh api graphql -f query='
  query($enterprise: String!) {
    enterprise(slug: $enterprise) {
      organizations(first: 100) {
        nodes {
          login
        }
      }
    }
  }' -f enterprise="$ENTERPRISE" --jq '.data.enterprise.organizations.nodes[].login')

echo "Found organizations: $ORGS"

# Deploy ruleset to each organization
for ORG in $ORGS; do
  echo "Deploying to $ORG..."

  # Create organization ruleset
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    /orgs/$ORG/rulesets \
    -f name="Emergency NPM Attack Block" \
    -f enforcement="active" \
    -f target="branch" \
    -f bypass_actors='[]' \
    --field conditions='{"ref_name":{"include":["~ALL"],"exclude":[]}}' \
    --field rules='[
      {
        "type": "required_workflows",
        "parameters": {
          "required_workflows": [
            {
              "path": ".github/workflows/npm-security.yml",
              "repository_id": 0
            }
          ]
        }
      }
    ]'
done
```

### 2.2 Alternative: GitHub UI Deployment

For each organization in your enterprise:

1. Go to **Organization Settings** → **Repository** → **Rulesets**
2. Click **New ruleset** → **New branch ruleset**
3. Configure:
   - **Name**: Emergency NPM Attack Block
   - **Enforcement status**: Active
   - **Target repositories**: All repositories
   - **Target branches**: All branches
   - **Rules**:
     - ✅ Restrict creations
     - ✅ Restrict updates
     - ✅ Require status checks to pass
     - Add status check: `npm-security`

## Step 3: Mass Repository Workflow Deployment

### 3.1 Enterprise-Wide Script

This script deploys the security workflow to ALL repositories:

```bash
#!/bin/bash
# mass-deploy-npm-protection.sh

set -e

echo "🚨 GitHub Enterprise NPM Attack Protection"
echo "=========================================="

# Configuration
ENTERPRISE="${1:-YOUR-ENTERPRISE}"
WORKFLOW_FILE=".github/workflows/npm-hash-check.yml"

# Get workflow content
WORKFLOW_CONTENT='name: NPM Security Check
on: [push, pull_request]

permissions:
  contents: read
  security-events: write

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Scan for malicious hashes
        id: scan
        run: |
          echo "🔍 Scanning for known malicious npm packages..."

          MALICIOUS_HASHES=(
            "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
            "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
            "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
            "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
          )

          FOUND=false
          for file in $(find . -type f -name "*.js"); do
            if [ -f "$file" ]; then
              HASH=$(sha256sum "$file" | cut -d" " -f1)
              for KNOWN in "${MALICIOUS_HASHES[@]}"; do
                if [ "$HASH" = "$KNOWN" ]; then
                  echo "❌ MALICIOUS FILE: $file"
                  echo "   SHA256: $HASH"
                  FOUND=true
                fi
              done
            fi
          done

          if [ "$FOUND" = true ]; then
            echo "::error::Malicious npm packages detected!"
            exit 1
          else
            echo "✅ No known malicious files found"
          fi

      - name: Check bundle.js specifically
        run: |
          if [ -f "bundle.js" ]; then
            HASH=$(sha256sum bundle.js | cut -d" " -f1)
            echo "bundle.js hash: $HASH"

            KNOWN_BAD=(
              "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
              "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
              "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
              "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
            )

            for BAD in "${KNOWN_BAD[@]}"; do
              if [ "$HASH" = "$BAD" ]; then
                echo "::error::bundle.js is MALICIOUS!"
                exit 1
              fi
            done
          fi'

# Function to deploy to a repository
deploy_to_repo() {
    local org=$1
    local repo=$2

    echo -n "  Deploying to $org/$repo... "

    # Check if workflow already exists
    if gh api repos/$org/$repo/contents/.github/workflows/npm-hash-check.yml &>/dev/null; then
        echo "updating..."
        gh api \
          --method PUT \
          repos/$org/$repo/contents/.github/workflows/npm-hash-check.yml \
          -f message="Update NPM security check" \
          -f content="$(echo "$WORKFLOW_CONTENT" | base64)" \
          -f sha="$(gh api repos/$org/$repo/contents/.github/workflows/npm-hash-check.yml --jq .sha)" \
          &>/dev/null && echo "✅" || echo "⚠️"
    else
        echo "creating..."
        # Create workflow directory if needed
        gh api \
          --method PUT \
          repos/$org/$repo/contents/.github/workflows/npm-hash-check.yml \
          -f message="Add emergency NPM security check" \
          -f content="$(echo "$WORKFLOW_CONTENT" | base64)" \
          &>/dev/null && echo "✅" || echo "⚠️"
    fi
}

# Get all organizations
echo "Fetching enterprise organizations..."
ORGS=$(gh api graphql -f query='
  query($enterprise: String!) {
    enterprise(slug: $enterprise) {
      organizations(first: 100) {
        nodes {
          login
        }
      }
    }
  }' -f enterprise="$ENTERPRISE" --jq '.data.enterprise.organizations.nodes[].login')

# Deploy to each organization's repositories
for ORG in $ORGS; do
    echo ""
    echo "Organization: $ORG"
    echo "------------------------"

    # Get repositories for this org
    REPOS=$(gh api orgs/$ORG/repos --paginate --jq '.[].name')

    for REPO in $REPOS; do
        deploy_to_repo "$ORG" "$REPO"
    done
done

echo ""
echo "✅ Deployment complete!"
```

## Step 4: GitHub Enterprise Server (Self-Hosted)

For GitHub Enterprise Server installations:

### 4.1 Pre-receive Hook (Immediate Block)

SSH into your GitHub Enterprise Server and add this pre-receive hook:

```bash
#!/bin/bash
# /data/user/git-hooks/pre-receive-npm-security

# Known malicious hashes
MALICIOUS_HASHES="
46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09
b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777
dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c
4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db
"

while read oldrev newrev refname; do
  # Check all JS files in the push
  git diff --name-only $oldrev..$newrev | grep '\.js$' | while read file; do
    content=$(git show $newrev:$file 2>/dev/null)
    if [ -n "$content" ]; then
      hash=$(echo "$content" | sha256sum | cut -d' ' -f1)

      if echo "$MALICIOUS_HASHES" | grep -q "$hash"; then
        echo "❌ BLOCKED: Malicious npm package detected!"
        echo "   File: $file"
        echo "   Hash: $hash"
        echo ""
        echo "This push contains known malicious code and has been blocked."
        echo "Remove the infected files and try again."
        exit 1
      fi
    fi
  done
done

exit 0
```

Enable the hook:
```bash
sudo -u git cp pre-receive-npm-security /opt/github/git-hooks/
sudo -u git chmod +x /opt/github/git-hooks/pre-receive-npm-security
ghe-config app.github.pre-receive-hook-dir /opt/github/git-hooks
ghe-config-apply
```

## Step 5: Quick Verification

### Test the protection:

```bash
# Create a test file with known bad hash
echo "test" > test.js

# Get its hash
sha256sum test.js

# Try to push - it should be blocked if hash matches
```

## Step 6: Monitor & Alert

### 6.1 Set up webhook notifications:

```bash
# For all organizations
for ORG in $ORGS; do
  gh api \
    --method POST \
    /orgs/$ORG/hooks \
    -f name="web" \
    -f active=true \
    -f events='["push","workflow_run"]' \
    -f config='{"url":"https://your-webhook-endpoint.com","content_type":"json"}'
done
```

### 6.2 Enable security alerts:

Go to **Enterprise settings** → **Code security and analysis** → Enable all security features

## Emergency Contact Workflow

If malicious files are detected:

1. **Immediate**: Block the repository
2. **Within 1 hour**: Rotate all secrets
3. **Within 4 hours**: Full audit of recent commits
4. **Within 24 hours**: Security report to leadership

## Summary Commands

### Fastest deployment (copy-paste):

```bash
# Set your enterprise name
ENTERPRISE="your-enterprise"

# Deploy to all orgs
for ORG in $(gh api graphql -f query='query($e:String!){enterprise(slug:$e){organizations(first:100){nodes{login}}}}' -f e="$ENTERPRISE" --jq '.data.enterprise.organizations.nodes[].login'); do
  echo "Protecting $ORG..."
  gh api --method POST /orgs/$ORG/rulesets \
    -f name="NPM Attack Block" \
    -f enforcement="active" \
    -f target="branch" \
    --field conditions='{"ref_name":{"include":["~ALL"]}}' \
    --field rules='[{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"npm-security"}]}}]'
done
```

---

**Time to Deploy**: 5-10 minutes for entire enterprise
**Coverage**: All organizations and repositories
**Protection Level**: Immediate blocking of known malicious hashes