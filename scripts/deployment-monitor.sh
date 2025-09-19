#!/bin/bash

# Deployment Monitoring Script
# Monitors the status of NPM security deployment across the enterprise

set -euo pipefail

# Configuration
ENTERPRISE="YOUR-ENTERPRISE"
OUTPUT_FILE="deployment-status-$(date +%Y%m%d-%H%M%S).csv"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_ORGS=0
TOTAL_REPOS=0
PROTECTED_REPOS=0
UNPROTECTED_REPOS=0
PARTIAL_REPOS=0

echo "Organization,Repository,Workflow Status,Ruleset Status,Protection Level" > "$OUTPUT_FILE"

# Function to check repository status
check_repo_status() {
    local org=$1
    local repo=$2
    local workflow_status="Not Deployed"
    local ruleset_status="Not Active"
    local protection_level="Unprotected"

    # Check for workflow
    if gh api "repos/$org/$repo/contents/.github/workflows/npm-security.yml" &>/dev/null 2>&1; then
        workflow_status="Deployed"
    fi

    # Check for active ruleset on repository
    local repo_id=$(gh api "repos/$org/$repo" --jq '.id' 2>/dev/null || echo "")
    if [ -n "$repo_id" ]; then
        local has_ruleset=$(gh api graphql -f query='
            query($org: String!, $repo: String!) {
                repository(owner: $org, name: $repo) {
                    rulesets(first: 100) {
                        nodes {
                            name
                            enforcement
                        }
                    }
                }
            }' -f org="$org" -f repo="$repo" --jq '.data.repository.rulesets.nodes[] | select(.name=="NPM Security Check" and .enforcement=="ACTIVE") | .name' 2>/dev/null || echo "")

        if [ -n "$has_ruleset" ]; then
            ruleset_status="Active"
        fi
    fi

    # Determine protection level
    if [ "$workflow_status" = "Deployed" ] && [ "$ruleset_status" = "Active" ]; then
        protection_level="Fully Protected"
        ((PROTECTED_REPOS++))
    elif [ "$workflow_status" = "Deployed" ] || [ "$ruleset_status" = "Active" ]; then
        protection_level="Partially Protected"
        ((PARTIAL_REPOS++))
    else
        ((UNPROTECTED_REPOS++))
    fi

    echo "$org,$repo,$workflow_status,$ruleset_status,$protection_level" >> "$OUTPUT_FILE"

    # Display status with color coding
    case "$protection_level" in
        "Fully Protected")
            echo -e "${GREEN}✓${NC} $org/$repo - ${GREEN}Fully Protected${NC}"
            ;;
        "Partially Protected")
            echo -e "${YELLOW}⚠${NC} $org/$repo - ${YELLOW}Partially Protected${NC} (Workflow: $workflow_status, Ruleset: $ruleset_status)"
            ;;
        "Unprotected")
            echo -e "${RED}✗${NC} $org/$repo - ${RED}Unprotected${NC}"
            ;;
    esac
}

# Function to check organization ruleset
check_org_ruleset() {
    local org=$1

    echo -e "\n${BLUE}Checking organization: $org${NC}"
    echo "========================================="

    # Check for organization-level ruleset
    local org_ruleset=$(gh api "/orgs/$org/rulesets" --jq '.[] | select(.name=="NPM Security Check") | .name' 2>/dev/null || echo "")

    if [ -n "$org_ruleset" ]; then
        echo -e "${GREEN}✓${NC} Organization ruleset: Active"
    else
        echo -e "${RED}✗${NC} Organization ruleset: Not found"
    fi

    # Get repositories
    local repos=$(gh api "orgs/$org/repos" --paginate --jq '.[].name' 2>/dev/null || echo "")

    if [ -z "$repos" ]; then
        echo -e "${YELLOW}No repositories found in $org${NC}"
        return
    fi

    local repo_count=$(echo "$repos" | wc -l)
    echo "Found $repo_count repositories"
    echo ""

    ((TOTAL_ORGS++))

    # Check each repository
    while IFS= read -r repo; do
        if [ -n "$repo" ]; then
            ((TOTAL_REPOS++))
            check_repo_status "$org" "$repo"
        fi
    done <<< "$repos"
}

# Main monitoring function
main() {
    echo -e "${BLUE}GitHub Enterprise NPM Security Deployment Monitor${NC}"
    echo "=================================================="
    echo ""

    # Check prerequisites
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
        exit 1
    fi

    # Get organizations
    echo "Fetching organizations..."
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
        echo -e "${YELLOW}Using alternative organization list...${NC}"
        ORGS="org1 org2 org3 org4 org5 org6 org7 org8 org9 org10"
    fi

    # Check each organization
    for ORG in $ORGS; do
        check_org_ruleset "$ORG"
    done

    # Display summary
    echo ""
    echo "=================================================="
    echo -e "${BLUE}Deployment Summary${NC}"
    echo "=================================================="
    echo "Total Organizations: $TOTAL_ORGS"
    echo "Total Repositories: $TOTAL_REPOS"
    echo -e "${GREEN}Fully Protected: $PROTECTED_REPOS ($(awk "BEGIN {printf \"%.1f\", ($PROTECTED_REPOS/$TOTAL_REPOS)*100}")%)${NC}"
    echo -e "${YELLOW}Partially Protected: $PARTIAL_REPOS ($(awk "BEGIN {printf \"%.1f\", ($PARTIAL_REPOS/$TOTAL_REPOS)*100}")%)${NC}"
    echo -e "${RED}Unprotected: $UNPROTECTED_REPOS ($(awk "BEGIN {printf \"%.1f\", ($UNPROTECTED_REPOS/$TOTAL_REPOS)*100}")%)${NC}"
    echo ""
    echo "Detailed report saved to: $OUTPUT_FILE"

    # Generate recommendations if needed
    if [ $UNPROTECTED_REPOS -gt 0 ] || [ $PARTIAL_REPOS -gt 0 ]; then
        echo ""
        echo "=================================================="
        echo -e "${YELLOW}Recommendations${NC}"
        echo "=================================================="

        if [ $UNPROTECTED_REPOS -gt 0 ]; then
            echo -e "${RED}• $UNPROTECTED_REPOS repositories need immediate protection${NC}"
            echo "  Run: ./enterprise-mass-deployment.sh"
        fi

        if [ $PARTIAL_REPOS -gt 0 ]; then
            echo -e "${YELLOW}• $PARTIAL_REPOS repositories have partial protection${NC}"
            echo "  Check deployment logs for failed components"
        fi
    else
        echo ""
        echo -e "${GREEN}All repositories are fully protected!${NC}"
    fi
}

# Run main function
main "$@"