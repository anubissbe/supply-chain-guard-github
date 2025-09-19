# 🚨 2-HOUR EMERGENCY PLAN - GITHUB ENTERPRISE CLOUD ONLY

## Your Situation
- **Platform**: GitHub Enterprise Cloud (github.com)
- **Repos**: 1600
- **Organizations**: 10
- **Time**: 2 hours
- **Goal**: Block npm attack with known hashes

## THE ONLY VIABLE APPROACH: Rulesets + Parallel Workflow Deployment

### What You'll Achieve in 2 Hours
- ✅ **100% PR merge blocking** via Organization Rulesets (30 min)
- ✅ **80-90% workflow coverage** (1300+ repos) via parallel deployment
- ✅ **Zero changes to existing pipelines**

---

## ⏱️ MINUTE-BY-MINUTE EXECUTION PLAN

### 🟢 START: Minutes 0-5 - Quick Setup

```bash
# 1. Get the scripts
git clone https://github.com/anubissbe/supply-chain-guard-github.git
cd supply-chain-guard-github

# 2. Verify GitHub CLI auth
gh auth status
# If not authenticated: gh auth login

# 3. Quick test on your personal repo first
gh api repos/anubissbe/supply-chain-guard-github --jq '.name'
```

### 🟡 Minutes 5-15 - Configure Your Organizations

```bash
# Edit organization names (CRITICAL - must be exact)
nano scripts/deploy-org-ruleset-enterprise-cloud.sh

# Change this section:
ORGANIZATIONS=(
    "your-org-1"
    "your-org-2"
    "your-org-3"
    "your-org-4"
    "your-org-5"
    "your-org-6"
    "your-org-7"
    "your-org-8"
    "your-org-9"
    "your-org-10"
)

# Also edit the mass deployment script
nano scripts/enterprise-mass-deployment.sh

# Update these lines:
ENTERPRISE="your-enterprise-name"
# And if enterprise API fails, list orgs manually:
ORGS="your-org-1 your-org-2 your-org-3..."
```

### 🔴 Minutes 15-30 - Deploy Organization Rulesets (CRITICAL)

**This is your FIRST line of defense - do this immediately!**

```bash
# Deploy rulesets to all 10 organizations
./scripts/deploy-org-ruleset-enterprise-cloud.sh

# Quick verification (should see "NPM Security Protection" for each)
for org in your-org-1 your-org-2; do
  gh api "/orgs/$org/rulesets" --jq '.[].name'
done
```

**✅ At 30 minutes: ALL pull requests now require security checks to merge!**

### ⚡ Minutes 30-90 - Mass Deploy Workflows (FAST MODE)

```bash
# Optimize for speed - increase parallel jobs
sed -i 's/PARALLEL_JOBS=10/PARALLEL_JOBS=25/g' scripts/enterprise-mass-deployment.sh
sed -i 's/BATCH_SIZE=50/BATCH_SIZE=100/g' scripts/enterprise-mass-deployment.sh
sed -i 's/RETRY_ATTEMPTS=3/RETRY_ATTEMPTS=1/g' scripts/enterprise-mass-deployment.sh

# START THE MASS DEPLOYMENT
nohup ./scripts/enterprise-mass-deployment.sh > deployment.log 2>&1 &

# Monitor progress (in another terminal)
tail -f deployment.log
watch -n 5 'grep -c "Success" deployment-logs-*/success.log 2>/dev/null || echo 0'
```

### 📊 Minutes 90-110 - Monitor & Verify

```bash
# Check deployment status
./scripts/deployment-monitor.sh | tee protection-status.txt

# Quick stats
echo "Protected repos: $(grep -c "Fully Protected" protection-status.txt)"
echo "Partial protection: $(grep -c "Partially Protected" protection-status.txt)"
echo "Unprotected: $(grep -c "Unprotected" protection-status.txt)"

# List any critical repos that failed
grep "payment\|auth\|prod\|main" deployment-logs-*/failed.log 2>/dev/null
```

### 🔧 Minutes 110-120 - Handle Critical Failures

```bash
# Quick retry for critical repos only
CRITICAL_KEYWORDS="payment auth billing api prod main core"

for keyword in $CRITICAL_KEYWORDS; do
  grep "$keyword" deployment-logs-*/failed.log 2>/dev/null | while IFS=: read -r repo status; do
    echo "Retrying critical repo: $repo"
    org=$(echo $repo | cut -d'/' -f1)
    name=$(echo $repo | cut -d'/' -f2)

    gh api \
      --method PUT \
      "repos/$repo/contents/.github/workflows/npm-security.yml" \
      -f message="CRITICAL: Emergency NPM protection" \
      -f content="$(cat .github/workflows/emergency-npm-hash-check.yml | base64 -w 0)"
  done
done
```

---

## 🎯 SIMPLIFIED WORKFLOW CONTENT

If the full workflow is too complex, use this minimal version for speed:

```yaml
name: NPM Security Check
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          for f in $(find . -name "*.js" 2>/dev/null); do
            h=$(sha256sum "$f" | cut -d' ' -f1)
            case $h in
              46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09|\
              b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777|\
              dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c|\
              4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db)
                echo "::error::Malicious file: $f"; exit 1 ;;
            esac
          done
```

---

## ✅ SUCCESS METRICS AT 2 HOURS

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Org Rulesets | 10/10 | 10/10 | 8/10 |
| Workflows Deployed | 1600 | 1300+ | 1000+ |
| Critical Repos | 100% | 100% | 95% |
| PR Blocking Active | Yes | Yes | Yes |

---

## 🚀 IF YOU ONLY HAVE 30 MINUTES

Do ONLY these steps:

1. **Deploy Organization Rulesets** (15 min)
2. **Deploy to top 50 critical repos** (15 min)

```bash
# Quick critical protection
./scripts/deploy-org-ruleset-enterprise-cloud.sh

# Get top 50 most active repos
for org in your-org-1 your-org-2; do
  gh api "orgs/$org/repos?sort=pushed&per_page=25" --jq '.[].full_name'
done | head -50 | while read repo; do
  echo "Protecting $repo"
  # Deploy workflow to each
done
```

---

## 🔥 EMERGENCY HOTLINE COMMANDS

If something goes wrong:

```bash
# Check if rulesets are blocking
gh api /repos/YOUR-ORG/REPO-NAME/branches/main/protection/required_status_checks

# Force-deploy to a single critical repo
gh api --method PUT \
  repos/YOUR-ORG/CRITICAL-REPO/contents/.github/workflows/npm-security.yml \
  -f message="EMERGENCY" \
  -f content="$(base64 -w 0 < .github/workflows/emergency-npm-hash-check.yml)"

# Check GitHub API rate limit
gh api rate_limit --jq '.rate'

# Emergency rollback (remove rulesets)
for org in your-org-1 your-org-2; do
  ruleset_id=$(gh api "/orgs/$org/rulesets" --jq '.[] | select(.name=="NPM Security Protection") | .id')
  [ -n "$ruleset_id" ] && gh api --method DELETE "/orgs/$org/rulesets/$ruleset_id"
done
```

---

## 📋 POST-2-HOUR CHECKLIST

After the emergency window:

- [ ] Complete deployment to remaining repos
- [ ] Document which repos are protected
- [ ] Set up monitoring dashboard
- [ ] Create incident report
- [ ] Schedule daily verification
- [ ] Plan for ongoing hash updates

---

## START NOW! Every minute counts!

The Organization Rulesets are your fastest protection - deploy them FIRST!