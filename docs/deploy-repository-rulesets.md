# Deploying Repository Rulesets for NPM Security

## How Repository Rulesets Protect Against Malicious Files

**This protection requires two components:**

1. **Repository Ruleset** - Enforces required status checks at the organization level
2. **GitHub Actions Workflow** - Performs the actual security scanning and reports status

### Ruleset Enforcement

When set to **"Active"** enforcement, the ruleset restricts the following interactions:
- **Push restrictions** - Blocks direct pushes to protected branches if required status checks fail
- **Pull request merges** - Prevents merging when security checks report failure
- **Branch protection** - Applies rules to specified branch patterns
- **Bypass prevention** - Ensures even administrators cannot override failed checks (unless explicitly added to bypass list)

### Prerequisites:

Before deploying the ruleset, ensure:
1. The security workflow (`.github/workflows/emergency-npm-hash-check.yml`) is deployed to repositories
2. The workflow is configured to set status checks that match the ruleset requirements

## Complete Setup Process

### Step 1: Deploy the Security Workflow FIRST

The workflow must exist in repositories before the ruleset can work:

```bash
# Deploy workflow to all repositories
for repo in $(gh repo list YOUR-ORG --limit 1000 --json name -q '.[].name'); do
  gh api \
    --method PUT \
    /repos/YOUR-ORG/$repo/contents/.github/workflows/npm-security.yml \
    -f message="Add NPM security check" \
    -f content="$(base64 < .github/workflows/emergency-npm-hash-check.yml)" \
    2>/dev/null && echo "✓ $repo"
done
```

### Step 2: Deploy the Ruleset

Now deploy the ruleset using one of these methods:

## Method 1: GitHub Web UI

### Creating a Ruleset via Organization Settings
1. Navigate to your organization's main page on GitHub Enterprise Cloud
2. Click **Settings** in the organization navigation
3. In the "Code, planning, and automation" section, click **Repository** → **Repository rulesets**
4. Click **New ruleset**
5. Choose between:
   - **Import a ruleset** - Upload the JSON file directly
   - **New branch ruleset** - Configure manually

For importing:
- Select `npm-security-minimal.json` for basic protection
- Select `npm-security-ruleset.json` for comprehensive protection

## Method 2: GitHub CLI (Recommended)

### Deploy to Single Organization
```bash
# Set your organization
ORG="your-org-name"

# Deploy the ruleset
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/$ORG/rulesets \
  --input .github/rulesets/npm-security-minimal.json
```

### Deploy to Multiple Organizations
```bash
#!/bin/bash
# deploy-rulesets.sh

# List your organizations
ORGS=(
  "org1"
  "org2"
  "org3"
)

# Deploy to each organization
for ORG in "${ORGS[@]}"; do
  echo "Deploying ruleset to $ORG..."

  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /orgs/$ORG/rulesets \
    --input .github/rulesets/npm-security-minimal.json \
    && echo "Success: $ORG" \
    || echo "Failed: $ORG (may already exist)"
done
```

## Method 3: GitHub API with curl

### Using Personal Access Token
```bash
# Set variables
TOKEN="ghp_your_token_here"
ORG="your-org"

# Deploy ruleset
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/orgs/$ORG/rulesets \
  -d @.github/rulesets/npm-security-minimal.json
```

## Understanding the Ruleset

### Minimal Version (npm-security-minimal.json)
- **Target**: Default branch
- **Enforcement mode**: Active (immediate enforcement)
- **Required status checks**: `npm-security` must pass
- **Bypass list**: Empty (no bypasses allowed)

### Comprehensive Version (npm-security-ruleset.json)
- **Target**: All branches (`~ALL` pattern)
- **Enforcement mode**: Active (immediate enforcement)
- **Required status checks**: Multiple security checks
- **Additional rules**: Pull request approvals required
- **Bypass list**: Empty (administrators cannot override)

### Enforcement Modes Explained

- **Active**: Rules are enforced immediately, blocking non-compliant actions
- **Evaluate**: Rules are tested but not enforced (logs violations for review)
- **Disabled**: Ruleset is temporarily inactive

## Known Malicious Hashes Being Blocked

The workflow scans for these specific SHA256 hashes:

```
46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09
b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777
dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c
4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db
```

Files typically named `bundle.js` with these hashes will:
1. Cause the security workflow to fail
2. Set status check to "failed"
3. Block PR merges and pushes due to the ruleset

## Verification

### Check if Ruleset is Active
```bash
# List all rulesets
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/$ORG/rulesets

# Get specific ruleset details
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/$ORG/rulesets/RULESET_ID
```

### View Ruleset in UI
1. Go to: `https://github.com/organizations/YOUR-ORG/settings/rules`
2. You should see "NPM Security Check" in the list
3. Click to view details and enforcement status

## Updating Existing Rulesets

### Get Current Ruleset ID
```bash
RULESET_ID=$(gh api /orgs/$ORG/rulesets --jq '.[] | select(.name=="NPM Security Check") | .id')
```

### Update the Ruleset
```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/$ORG/rulesets/$RULESET_ID \
  --input .github/rulesets/npm-security-minimal.json
```

## Removing a Ruleset

```bash
# Delete by ID
gh api \
  --method DELETE \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/$ORG/rulesets/$RULESET_ID
```

## Troubleshooting

### "Ruleset already exists" Error
The ruleset name must be unique. Either:
1. Delete the existing ruleset first
2. Or update it using PUT instead of POST

### "Not found" Error
Check that you have:
- Organization owner permissions
- Correct organization name
- GitHub Enterprise Cloud (not Server)

### Status Check Not Running
Ensure:
1. The workflow file exists in repositories
2. The status check name matches exactly
3. The workflow has proper triggers (push, pull_request)

## Notes

- Repository rulesets are available in GitHub Enterprise Cloud
- They may not be available in GitHub Enterprise Server versions before 3.8
- Free GitHub.com accounts have limited ruleset features
- The ruleset applies to ALL repositories in the organization by default