# Deploying Repository Rulesets for NPM Security

## Method 1: GitHub Web UI

### Navigate to Organization Rulesets
1. Go to your organization: `https://github.com/YOUR-ORG`
2. Click **Settings** → **Repository** → **Repository rulesets**
3. Click **New ruleset** → **Import a ruleset**
4. Upload one of these JSON files:
   - `npm-security-ruleset.json` (comprehensive protection)
   - `npm-security-minimal.json` (minimal, just the security check)

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
- **Target**: Default branch only
- **Enforcement**: Active immediately
- **Required check**: `npm-security` status must pass
- **No bypass**: Nobody can skip this check

### Comprehensive Version (npm-security-ruleset.json)
- **Target**: All branches
- **Enforcement**: Active immediately
- **Multiple checks**: NPM security + general security scan
- **Pull request rules**: Requires approval and review
- **Required workflow**: Links to the security workflow
- **Bypass**: Only repository admins in emergencies

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