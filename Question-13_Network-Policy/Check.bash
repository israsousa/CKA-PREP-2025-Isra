#!/bin/bash

# Question 13: Network Policy Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 13 - Network Policy..."

# 1. Check if NetworkPolicy exists in backend namespace
echo -n "Checking NetworkPolicy in 'backend' namespace... "
# The name might vary based on the applied file, but let's check for ANY netpol
NP_COUNT=$(kubectl get netpol -n backend --no-headers 2>/dev/null | wc -l)

if [ "$NP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}OK ($NP_COUNT policies found)${NC}"
else
    echo -e "${RED}FAIL - No NetworkPolicy found in backend namespace.${NC}"
    FAILURE=1
fi

# 2. Check for specific content (optional - loosely checking if allow-frontend or similar logic exists)
# Network-policy-3 usually has a PodSelector or NamespaceSelector for frontend
if [ $FAILURE -eq 0 ]; then
    echo -n "Checking if policy allows 'frontend'... "
    MATCH=$(kubectl get netpol -n backend -o yaml | grep -E "app: frontend|name: frontend" | wc -l)
    if [ "$MATCH" -gt 0 ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}WARNING - Could not confirm specific 'frontend' label selector in policy.${NC}"
        # Not marking as hard fail as names might vary
    fi
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
