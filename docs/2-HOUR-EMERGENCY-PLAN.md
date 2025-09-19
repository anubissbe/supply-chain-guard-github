# 🚨 2-HOUR EMERGENCY NPM ATTACK PROTECTION PLAN

## Time: 2 Hours | Repos: 1600 | Orgs: 10

### FASTEST OPTION: Organization Rulesets + Automated Workflow Deploy (90 minutes)

This is the ONLY realistic option that can protect 1600 repos in 2 hours.

## Minute-by-Minute Implementation Plan

### ⏱️ Minutes 0-10: Preparation

```bash
# 1. Clone the repo with scripts
git clone https://github.com/anubissbe/supply-chain-guard-github.git
cd supply-chain-guard-github

# 2. Set up GitHub CLI authentication
gh auth login
gh auth status

# 3. Edit organization names
vi scripts/deploy-org-ruleset-enterprise-cloud.sh
# Update the ORGANIZATIONS array with your 10 org names

vi scripts/enterprise-mass-deployment.sh
# Update ENTERPRISE and ORGS variables
```

### ⏱️ Minutes 10-30: Deploy Organization Rulesets

**This blocks merges/pushes immediately even before workflows are deployed!**

```bash
# Deploy rulesets to all 10 organizations (20 minutes)
./scripts/deploy-org-ruleset-enterprise-cloud.sh

# Verify rulesets are active
for org in org1 org2 org3; do
  echo "Checking $org..."
  gh api "/orgs/$org/rulesets" --jq '.[] | .name'
done
```

**Result**: All PRs now require "NPM Security Check" status to merge

### ⏱️ Minutes 30-90: Mass Deploy Security Workflow

```bash
# Increase parallel jobs for speed
sed -i 's/PARALLEL_JOBS=10/PARALLEL_JOBS=20/g' scripts/enterprise-mass-deployment.sh

# Start deployment (60 minutes for 1600 repos)
./scripts/enterprise-mass-deployment.sh

# Monitor progress in another terminal
tail -f deployment-logs-*/deployment.log
grep -c "Success" deployment-logs-*/success.log
```

### ⏱️ Minutes 90-100: Verify Protection

```bash
# Quick verification (10 minutes)
./scripts/deployment-monitor.sh | head -50

# Check a sample of repos
gh api "/orgs/org1/repos" --jq '.[0:5] | .[].name' | while read repo; do
  echo -n "$repo: "
  gh api "repos/org1/$repo/contents/.github/workflows/npm-security.yml" \
    --jq '.name' 2>/dev/null && echo "✓" || echo "✗"
done
```

### ⏱️ Minutes 100-120: Handle Failed Deployments

```bash
# Retry failed repos (20 minutes)
if [ -f deployment-logs-*/failed.log ]; then
  while IFS= read -r line; do
    org=$(echo $line | cut -d'/' -f1)
    repo=$(echo $line | cut -d'/' -f2 | cut -d':' -f1)

    gh api \
      --method PUT \
      "repos/$org/$repo/contents/.github/workflows/npm-security.yml" \
      -f message="Emergency NPM security" \
      -f content="$(base64 -w 0 < .github/workflows/emergency-npm-hash-check.yml)"
  done < deployment-logs-*/failed.log
fi
```

## ALTERNATIVE: Pre-receive Hook (30 minutes) - GitHub Enterprise Server Only

If you have GitHub Enterprise Server (self-hosted), this is the FASTEST:

### ⏱️ Total Time: 30 minutes

```bash
# SSH into GitHub Enterprise Server
ssh admin@your-github-server

# Create pre-receive hook
sudo -u git cat > /opt/github/git-hooks/npm-block << 'EOF'
#!/bin/bash
BLOCKED_HASHES="46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09 b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777 dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c 4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"

while read oldrev newrev refname; do
  for file in $(git diff-tree --no-commit-id --name-only -r $newrev | grep '\.js$'); do
    hash=$(git show $newrev:$file 2>/dev/null | sha256sum | cut -d' ' -f1)
    if echo "$BLOCKED_HASHES" | grep -q "$hash"; then
      echo "BLOCKED: Malicious NPM package detected!"
      exit 1
    fi
  done
done
EOF

# Enable globally
sudo -u git chmod +x /opt/github/git-hooks/npm-block
ghe-config app.github.pre-receive-hook-script /opt/github/git-hooks/npm-block
ghe-config-apply
```

**Result**: ALL 1600 repos protected in 30 minutes at Git level

## EMERGENCY MANUAL OPTION: Critical Repos Only (2 hours)

If automation fails, protect critical repos manually:

### Identify Critical Repos (20 most important)

```bash
# List your most critical repos
CRITICAL_REPOS=(
  "org1/payment-api"
  "org1/auth-service"
  "org2/main-app"
  # ... add 17 more
)

# Deploy to critical repos only
for repo in "${CRITICAL_REPOS[@]}"; do
  echo "Protecting $repo..."

  # Add workflow
  gh api \
    --method PUT \
    "repos/$repo/contents/.github/workflows/npm-security.yml" \
    -f message="EMERGENCY: Block NPM attack" \
    -f content="$(base64 -w 0 < .github/workflows/emergency-npm-hash-check.yml)"

  # Add branch protection
  gh api \
    --method PUT \
    "repos/$repo/branches/main/protection" \
    -f required_status_checks='{"strict":true,"contexts":["NPM Security Check"]}' \
    -f enforce_admins=true \
    -f required_pull_request_reviews='{"required_approving_review_count":1}'
done
```

## What Gets Protected in 2 Hours

### With Automated Approach:
- ✅ **100% of organizations** get rulesets (30 min)
- ✅ **80-90% of repositories** get workflows (90 min)
- ✅ **Failed repos** can be retried later
- ✅ **Immediate blocking** via rulesets even if workflow deploy is incomplete

### With Pre-receive Hook:
- ✅ **100% protection** in 30 minutes
- ✅ **Zero repository changes** needed
- ✅ **Blocks at Git level** before GitHub Actions

### With Manual Approach:
- ✅ **20-50 critical repositories** fully protected
- ✅ **Highest risk repos** covered first
- ⚠️ **Remaining repos** vulnerable until later

## Recommended Approach

1. **If GitHub Enterprise Server**: Use pre-receive hook (30 min)
2. **If GitHub Enterprise Cloud**: Use automated deployment (90 min)
3. **If automation fails**: Protect critical repos manually

## Post-2-Hour Follow-up

After the emergency window:

```bash
# 1. Complete failed deployments
./scripts/enterprise-mass-deployment.sh

# 2. Verify full coverage
./scripts/deployment-monitor.sh > protection-report.csv

# 3. Add monitoring
crontab -e
0 * * * * /path/to/deployment-monitor.sh

# 4. Document protected repos
gh api "/orgs/org1/repos" --paginate --jq '.[].name' | while read repo; do
  if gh api "repos/org1/$repo/contents/.github/workflows/npm-security.yml" &>/dev/null; then
    echo "$repo: PROTECTED" >> protected-repos.txt
  else
    echo "$repo: VULNERABLE" >> vulnerable-repos.txt
  fi
done
```

## SUCCESS CRITERIA for 2 Hours

✅ Organization rulesets active on all 10 orgs
✅ 80%+ repositories have security workflow
✅ All PR merges require security check
✅ Critical repositories fully protected
✅ Monitoring script confirms protection

## START NOW - TIME IS CRITICAL!

Begin with Step 1 immediately. The automated approach can realistically protect 1300+ of your 1600 repos within 2 hours.