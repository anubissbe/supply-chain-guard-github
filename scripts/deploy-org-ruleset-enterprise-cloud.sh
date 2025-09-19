#!/bin/bash

# GitHub Enterprise Cloud - Organization Ruleset Deployment
# Compatible with current GitHub Enterprise Cloud as per docs:
# https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization

set -euo pipefail

# Configuration - Update these for your enterprise
ORGANIZATIONS=(
    "org1"
    "org2"
    "org3"
    "org4"
    "org5"
    "org6"
    "org7"
    "org8"
    "org9"
    "org10"
)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "GitHub Enterprise Cloud - Organization Ruleset Deployment"
echo "========================================================"
echo ""

# Function to create/update organization ruleset
deploy_org_ruleset() {
    local ORG=$1

    echo -e "${YELLOW}Processing organization: $ORG${NC}"

    # Check if ruleset already exists
    EXISTING_RULESET=$(gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/orgs/$ORG/rulesets" \
        --jq '.[] | select(.name=="NPM Security Protection") | .id' \
        2>/dev/null || echo "")

    if [ -n "$EXISTING_RULESET" ]; then
        echo -e "${YELLOW}  Updating existing ruleset (ID: $EXISTING_RULESET)${NC}"

        # Update existing ruleset
        gh api \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "/orgs/$ORG/rulesets/$EXISTING_RULESET" \
            --input - <<EOF
{
    "name": "NPM Security Protection",
    "target": "branch",
    "enforcement": "active",
    "conditions": {
        "ref_name": {
            "include": [
                "~DEFAULT_BRANCH",
                "refs/heads/main",
                "refs/heads/master",
                "refs/heads/develop",
                "refs/heads/release/*"
            ],
            "exclude": []
        },
        "repository_name": {
            "include": ["*"],
            "exclude": [],
            "protected": false
        }
    },
    "rules": [
        {
            "type": "required_status_checks",
            "parameters": {
                "required_status_checks": [
                    {
                        "context": "NPM Security Check",
                        "integration_id": null
                    },
                    {
                        "context": "Emergency NPM Attack Detection",
                        "integration_id": null
                    }
                ],
                "strict_required_status_checks_policy": true
            }
        },
        {
            "type": "creation"
        },
        {
            "type": "update",
            "parameters": {
                "update_allows_fetch_and_merge": false
            }
        },
        {
            "type": "deletion"
        },
        {
            "type": "non_fast_forward"
        }
    ],
    "bypass_actors": []
}
EOF

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✓ Ruleset updated successfully${NC}"
        else
            echo -e "${RED}  ✗ Failed to update ruleset${NC}"
            return 1
        fi

    else
        echo -e "${YELLOW}  Creating new ruleset${NC}"

        # Create new ruleset
        gh api \
            --method POST \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "/orgs/$ORG/rulesets" \
            --input - <<EOF
{
    "name": "NPM Security Protection",
    "target": "branch",
    "enforcement": "active",
    "conditions": {
        "ref_name": {
            "include": [
                "~DEFAULT_BRANCH",
                "refs/heads/main",
                "refs/heads/master",
                "refs/heads/develop",
                "refs/heads/release/*"
            ],
            "exclude": []
        },
        "repository_name": {
            "include": ["*"],
            "exclude": [],
            "protected": false
        }
    },
    "rules": [
        {
            "type": "required_status_checks",
            "parameters": {
                "required_status_checks": [
                    {
                        "context": "NPM Security Check",
                        "integration_id": null
                    },
                    {
                        "context": "Emergency NPM Attack Detection",
                        "integration_id": null
                    }
                ],
                "strict_required_status_checks_policy": true
            }
        },
        {
            "type": "creation"
        },
        {
            "type": "update",
            "parameters": {
                "update_allows_fetch_and_merge": false
            }
        },
        {
            "type": "deletion"
        },
        {
            "type": "non_fast_forward"
        }
    ],
    "bypass_actors": []
}
EOF

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✓ Ruleset created successfully${NC}"
        else
            echo -e "${RED}  ✗ Failed to create ruleset${NC}"
            return 1
        fi
    fi

    # Verify the ruleset is active
    echo -e "${YELLOW}  Verifying ruleset status...${NC}"

    RULESET_STATUS=$(gh api \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/orgs/$ORG/rulesets" \
        --jq '.[] | select(.name=="NPM Security Protection") | .enforcement' \
        2>/dev/null || echo "")

    if [ "$RULESET_STATUS" = "active" ]; then
        echo -e "${GREEN}  ✓ Ruleset is ACTIVE and enforcing${NC}"
    else
        echo -e "${RED}  ✗ Ruleset status: $RULESET_STATUS${NC}"
    fi

    echo ""
}

# Main deployment
main() {
    # Check prerequisites
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
        exit 1
    fi

    # Check authentication
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
        echo "Please run: gh auth login"
        exit 1
    fi

    # Deploy to each organization
    SUCCESS_COUNT=0
    FAILED_COUNT=0

    for ORG in "${ORGANIZATIONS[@]}"; do
        if deploy_org_ruleset "$ORG"; then
            ((SUCCESS_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    done

    # Summary
    echo "========================================================"
    echo -e "${GREEN}Deployment Complete${NC}"
    echo "========================================================"
    echo "Organizations processed: ${#ORGANIZATIONS[@]}"
    echo -e "${GREEN}Successful: $SUCCESS_COUNT${NC}"
    if [ $FAILED_COUNT -gt 0 ]; then
        echo -e "${RED}Failed: $FAILED_COUNT${NC}"
    fi
    echo ""
    echo "Note: The rulesets will enforce on:"
    echo "  - Default branches"
    echo "  - main, master, develop branches"
    echo "  - release/* branches"
    echo "  - ALL repositories in each organization"
    echo ""
    echo "The rulesets require these status checks to pass:"
    echo "  - NPM Security Check"
    echo "  - Emergency NPM Attack Detection"
    echo ""
    echo "To view ruleset history, visit:"
    echo "https://github.com/organizations/YOUR-ORG/settings/rules"
}

# Run main function
main "$@"