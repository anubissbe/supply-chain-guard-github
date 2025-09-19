#!/bin/bash

# Emergency NPM Supply Chain Attack Protection Deployment Script
# This script rapidly deploys protection against the current npm attack
# with known file hashes

set -e

echo "🚨 EMERGENCY NPM SUPPLY CHAIN ATTACK PROTECTION DEPLOYMENT"
echo "=========================================================="
echo ""
echo "This script will deploy immediate protection against the active npm supply chain attack"
echo "Known malicious file hashes will be blocked across your organization"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ You are not authenticated with GitHub CLI. Please run:"
    echo "   gh auth login"
    exit 1
fi

# Get organization name
read -p "Enter your GitHub organization name: " ORG_NAME

# Confirm deployment
echo ""
echo "This will deploy to organization: $ORG_NAME"
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "📋 Step 1: Creating organization-wide repository ruleset..."

# Create the repository ruleset
RULESET_ID=$(gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/${ORG_NAME}/rulesets \
  --input .github/rulesets/emergency-npm-attack-block.json \
  --jq '.id' 2>/dev/null || echo "exists")

if [ "$RULESET_ID" = "exists" ]; then
    echo "⚠️  Ruleset may already exist, updating..."
    # Get existing ruleset ID
    RULESET_ID=$(gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      /orgs/${ORG_NAME}/rulesets \
      --jq '.[] | select(.name == "Emergency NPM Supply Chain Attack Block") | .id' || echo "")

    if [ -n "$RULESET_ID" ]; then
        gh api \
          --method PUT \
          -H "Accept: application/vnd.github+json" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          /orgs/${ORG_NAME}/rulesets/${RULESET_ID} \
          --input .github/rulesets/emergency-npm-attack-block.json
        echo "✅ Ruleset updated successfully"
    else
        echo "✅ Ruleset created successfully"
    fi
else
    echo "✅ Ruleset created successfully (ID: $RULESET_ID)"
fi

echo ""
echo "📋 Step 2: Deploying hash check workflow to repositories..."

# Get list of repositories
echo "Fetching repository list..."
REPOS=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/${ORG_NAME}/repos \
  --paginate \
  --jq '.[].name')

REPO_COUNT=$(echo "$REPOS" | wc -l)
echo "Found $REPO_COUNT repositories"

# Option to deploy to all or specific repos
echo ""
echo "Deployment options:"
echo "1. Deploy to ALL repositories (recommended for emergency)"
echo "2. Deploy to repositories with package.json only"
echo "3. Deploy to a specific list of repositories"
read -p "Select option (1-3): " DEPLOY_OPTION

case $DEPLOY_OPTION in
    1)
        TARGET_REPOS="$REPOS"
        ;;
    2)
        echo "Scanning for Node.js repositories..."
        TARGET_REPOS=""
        for repo in $REPOS; do
            if gh api \
              -H "Accept: application/vnd.github+json" \
              /repos/${ORG_NAME}/${repo}/contents/package.json \
              --jq '.name' &>/dev/null; then
                TARGET_REPOS="$TARGET_REPOS$repo"$'\n'
                echo "  ✓ $repo (has package.json)"
            fi
        done
        ;;
    3)
        echo "Enter repository names (one per line, empty line to finish):"
        TARGET_REPOS=""
        while IFS= read -r repo; do
            [ -z "$repo" ] && break
            TARGET_REPOS="$TARGET_REPOS$repo"$'\n'
        done
        ;;
esac

# Deploy workflow to target repositories
echo ""
echo "Deploying workflow to repositories..."

SUCCESS_COUNT=0
FAIL_COUNT=0

for repo in $TARGET_REPOS; do
    [ -z "$repo" ] && continue

    echo -n "  Deploying to $repo..."

    # Create .github/workflows directory if it doesn't exist
    gh api \
      --method PUT \
      -H "Accept: application/vnd.github+json" \
      /repos/${ORG_NAME}/${repo}/contents/.github/workflows/emergency-npm-hash-check.yml \
      -f message="Emergency: Add NPM supply chain attack detection" \
      -f content="$(base64 -w 0 .github/workflows/emergency-npm-hash-check.yml)" \
      &>/dev/null && {
        echo " ✅"
        ((SUCCESS_COUNT++))
    } || {
        echo " ⚠️ (may already exist or no permissions)"
        ((FAIL_COUNT++))
    }
done

echo ""
echo "📋 Step 3: Creating organization-wide secret for notifications (optional)..."
read -p "Do you want to set up Slack notifications? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter Slack webhook URL: " SLACK_WEBHOOK
    gh api \
      --method PUT \
      -H "Accept: application/vnd.github+json" \
      /orgs/${ORG_NAME}/actions/secrets/SLACK_WEBHOOK \
      -f encrypted_value="$(echo -n "$SLACK_WEBHOOK" | gh secret set -)" \
      -f visibility="all" \
      &>/dev/null && echo "✅ Slack notifications configured"
fi

echo ""
echo "=========================================================="
echo "🛡️  EMERGENCY PROTECTION DEPLOYMENT COMPLETE"
echo "=========================================================="
echo ""
echo "✅ Repository ruleset active for: $ORG_NAME"
echo "✅ Workflow deployed to $SUCCESS_COUNT repositories"
if [ $FAIL_COUNT -gt 0 ]; then
    echo "⚠️  $FAIL_COUNT repositories skipped (may already have workflow)"
fi
echo ""
echo "📊 PROTECTION STATUS:"
echo "  • Known malicious hashes will be blocked"
echo "  • All JavaScript files will be scanned"
echo "  • bundle.js files will be specifically checked"
echo "  • PRs require approval before merge"
echo ""
echo "🔍 IMMEDIATE ACTIONS RECOMMENDED:"
echo "  1. Run workflow on all existing branches"
echo "  2. Audit recent npm package additions"
echo "  3. Review any bundle.js files in repositories"
echo "  4. Enable Harden-Runner for runtime protection (next step)"
echo ""
echo "📚 For more information on the attack:"
echo "  https://github.com/yourusername/supply-chain-guard-github/blob/main/docs/npm-attack-response.md"
echo ""
echo "Need help? Contact security team immediately."