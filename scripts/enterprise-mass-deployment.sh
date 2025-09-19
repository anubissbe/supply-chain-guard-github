#!/bin/bash

# GitHub Enterprise Mass Deployment Script
# Deploys NPM security protection to 1600+ repositories across 10 organizations
# Optimized for large-scale deployment with parallel processing

set -euo pipefail

# Configuration
ENTERPRISE="YOUR-ENTERPRISE"
LOG_DIR="./deployment-logs-$(date +%Y%m%d-%H%M%S)"
PARALLEL_JOBS=10  # Number of parallel deployments
BATCH_SIZE=50     # Repositories per batch
RETRY_ATTEMPTS=3
RETRY_DELAY=5

# Create log directory
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_DIR/deployment.log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_DIR/deployment.log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_DIR/deployment.log"
}

# Progress tracking
TOTAL_REPOS=0
DEPLOYED_REPOS=0
FAILED_REPOS=0
SKIPPED_REPOS=0

# Workflow content
WORKFLOW_CONTENT='name: NPM Security Check
on:
  push:
    branches: ["main", "master", "develop", "release/*"]
  pull_request:
    branches: ["main", "master", "develop", "release/*"]

permissions:
  contents: read
  statuses: write

jobs:
  npm-security:
    name: NPM Security Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check for malicious npm packages
        id: security-check
        run: |
          echo "Scanning for known malicious npm packages..."

          MALICIOUS_HASHES=(
            "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
            "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
            "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
            "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
          )

          FOUND=false
          MALICIOUS_FILES=""

          for file in $(find . -type f -name "*.js" -o -name "*.mjs" -o -name "*.cjs" 2>/dev/null); do
            if [ -f "$file" ]; then
              HASH=$(sha256sum "$file" | cut -d" " -f1)
              for KNOWN in "${MALICIOUS_HASHES[@]}"; do
                if [ "$HASH" = "$KNOWN" ]; then
                  echo "CRITICAL: Malicious file detected: $file"
                  echo "SHA256: $HASH"
                  MALICIOUS_FILES="$MALICIOUS_FILES$file (SHA256: $HASH)\n"
                  FOUND=true
                fi
              done
            fi
          done

          if [ "$FOUND" = true ]; then
            echo "::error::Malicious npm packages detected in repository"
            echo -e "Malicious files found:\n$MALICIOUS_FILES"
            exit 1
          else
            echo "Security check passed: No malicious files detected"
          fi

      - name: Report status
        if: always()
        run: |
          if [ "${{ steps.security-check.outcome }}" = "failure" ]; then
            echo "Security check FAILED - Push blocked"
            exit 1
          else
            echo "Security check PASSED"
          fi'

# Function to deploy workflow to a single repository
deploy_to_repo() {
    local org=$1
    local repo=$2
    local attempt=1

    while [ $attempt -le $RETRY_ATTEMPTS ]; do
        # Check if workflow already exists
        if gh api "repos/$org/$repo/contents/.github/workflows/npm-security.yml" &>/dev/null 2>&1; then
            # Update existing workflow
            local sha=$(gh api "repos/$org/$repo/contents/.github/workflows/npm-security.yml" --jq .sha 2>/dev/null)

            if gh api \
                --method PUT \
                "repos/$org/$repo/contents/.github/workflows/npm-security.yml" \
                -f message="Update NPM security check workflow" \
                -f content="$(echo "$WORKFLOW_CONTENT" | base64 -w 0)" \
                -f sha="$sha" &>/dev/null 2>&1; then

                echo "$org/$repo: Updated" >> "$LOG_DIR/success.log"
                ((DEPLOYED_REPOS++))
                return 0
            fi
        else
            # Create new workflow
            if gh api \
                --method PUT \
                "repos/$org/$repo/contents/.github/workflows/npm-security.yml" \
                -f message="Add NPM security check workflow" \
                -f content="$(echo "$WORKFLOW_CONTENT" | base64 -w 0)" &>/dev/null 2>&1; then

                echo "$org/$repo: Created" >> "$LOG_DIR/success.log"
                ((DEPLOYED_REPOS++))
                return 0
            fi
        fi

        if [ $attempt -lt $RETRY_ATTEMPTS ]; then
            sleep $RETRY_DELAY
            ((attempt++))
        else
            echo "$org/$repo: Failed after $RETRY_ATTEMPTS attempts" >> "$LOG_DIR/failed.log"
            ((FAILED_REPOS++))
            return 1
        fi
    done
}

# Function to deploy ruleset to organization
deploy_ruleset_to_org() {
    local org=$1

    log_info "Deploying ruleset to organization: $org"

    # Check if ruleset already exists
    local ruleset_exists=$(gh api "/orgs/$org/rulesets" --jq '.[] | select(.name=="NPM Security Check") | .id' 2>/dev/null || echo "")

    if [ -n "$ruleset_exists" ]; then
        log_info "Ruleset already exists for $org (ID: $ruleset_exists)"
        echo "$org: Ruleset already exists" >> "$LOG_DIR/rulesets.log"
    else
        # Create new ruleset
        if gh api \
            --method POST \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "/orgs/$org/rulesets" \
            -f name="NPM Security Check" \
            -f target="branch" \
            -f enforcement="active" \
            --field conditions='{
                "ref_name": {
                    "include": ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/master"],
                    "exclude": []
                }
            }' \
            --field rules='[
                {
                    "type": "required_status_checks",
                    "parameters": {
                        "required_status_checks": [
                            {
                                "context": "NPM Security Check"
                            }
                        ],
                        "strict_required_status_checks_policy": true
                    }
                }
            ]' \
            --field bypass_actors='[]' &>/dev/null 2>&1; then

            log_info "Successfully created ruleset for $org"
            echo "$org: Ruleset created" >> "$LOG_DIR/rulesets.log"
        else
            log_error "Failed to create ruleset for $org"
            echo "$org: Ruleset creation failed" >> "$LOG_DIR/rulesets.log"
        fi
    fi
}

# Function to process repositories in parallel
process_batch() {
    local org=$1
    shift
    local repos=("$@")

    for repo in "${repos[@]}"; do
        deploy_to_repo "$org" "$repo" &

        # Control parallel jobs
        while [ $(jobs -r | wc -l) -ge $PARALLEL_JOBS ]; do
            sleep 0.1
        done
    done

    # Wait for remaining jobs in batch
    wait
}

# Main deployment
main() {
    log_info "Starting mass deployment to GitHub Enterprise"
    log_info "Log directory: $LOG_DIR"

    # Get all organizations
    log_info "Fetching organizations..."
    ORGS=$(gh api graphql -f query='
        query($enterprise: String!) {
            enterprise(slug: $enterprise) {
                organizations(first: 100) {
                    nodes {
                        login
                    }
                }
            }
        }' -f enterprise="$ENTERPRISE" --jq '.data.enterprise.organizations.nodes[].login' 2>/dev/null || echo "")

    if [ -z "$ORGS" ]; then
        log_error "No organizations found or unable to fetch organizations"
        log_info "Trying alternative method to list organizations..."

        # Alternative: List specific organizations if enterprise query fails
        ORGS="org1 org2 org3 org4 org5 org6 org7 org8 org9 org10"
        log_warning "Using predefined organization list: $ORGS"
    fi

    # Process each organization
    for ORG in $ORGS; do
        log_info "Processing organization: $ORG"

        # Deploy ruleset to organization first
        deploy_ruleset_to_org "$ORG"

        # Get all repositories for this organization
        log_info "Fetching repositories for $ORG..."
        REPOS=$(gh api "orgs/$ORG/repos" --paginate --jq '.[].name' 2>/dev/null || echo "")

        if [ -z "$REPOS" ]; then
            log_warning "No repositories found for $ORG"
            continue
        fi

        # Convert to array
        readarray -t REPO_ARRAY <<< "$REPOS"
        REPO_COUNT=${#REPO_ARRAY[@]}
        TOTAL_REPOS=$((TOTAL_REPOS + REPO_COUNT))

        log_info "Found $REPO_COUNT repositories in $ORG"

        # Process repositories in batches
        for ((i=0; i<$REPO_COUNT; i+=BATCH_SIZE)); do
            batch_end=$((i + BATCH_SIZE))
            if [ $batch_end -gt $REPO_COUNT ]; then
                batch_end=$REPO_COUNT
            fi

            log_info "Processing batch $((i/BATCH_SIZE + 1)) (repos $((i+1))-$batch_end of $REPO_COUNT)"

            # Get batch of repositories
            batch=("${REPO_ARRAY[@]:$i:$BATCH_SIZE}")

            # Process batch in parallel
            process_batch "$ORG" "${batch[@]}"

            # Show progress
            log_info "Progress: $DEPLOYED_REPOS deployed, $FAILED_REPOS failed, $SKIPPED_REPOS skipped"
        done
    done

    # Final report
    log_info "========================================="
    log_info "Deployment Complete"
    log_info "========================================="
    log_info "Total repositories processed: $TOTAL_REPOS"
    log_info "Successfully deployed: $DEPLOYED_REPOS"
    log_info "Failed deployments: $FAILED_REPOS"
    log_info "Skipped: $SKIPPED_REPOS"
    log_info "========================================="
    log_info "Detailed logs available in: $LOG_DIR"
    log_info "  - Success log: $LOG_DIR/success.log"
    log_info "  - Failed log: $LOG_DIR/failed.log"
    log_info "  - Ruleset log: $LOG_DIR/rulesets.log"
    log_info "  - Main log: $LOG_DIR/deployment.log"

    # Generate summary report
    cat > "$LOG_DIR/summary.txt" <<EOF
GitHub Enterprise NPM Security Deployment Summary
Generated: $(date)
================================================

Organizations Processed: $(echo "$ORGS" | wc -w)
Total Repositories: $TOTAL_REPOS
Successful Deployments: $DEPLOYED_REPOS
Failed Deployments: $FAILED_REPOS
Skipped Repositories: $SKIPPED_REPOS

Success Rate: $(awk "BEGIN {printf \"%.2f\", ($DEPLOYED_REPOS/$TOTAL_REPOS)*100}")%

Logs Directory: $LOG_DIR
EOF

    log_info "Summary report saved to: $LOG_DIR/summary.txt"

    # Exit with appropriate code
    if [ $FAILED_REPOS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Check prerequisites
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    log_error "Not authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

# Run main deployment
main "$@"