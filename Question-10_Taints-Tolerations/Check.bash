#!/bin/bash

# Question 10: Taints & Tolerations Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 10 - Taints & Tolerations..."

# 1. Check Taint on node01
echo -n "Checking taint on node01 (PERMISSION=granted:NoSchedule)... "
TAINT=$(kubectl get node node01 -o jsonpath='{.spec.taints[?(@.key=="PERMISSION")]}' 2>/dev/null)
if [[ "$TAINT" == *"granted"* ]] && [[ "$TAINT" == *"NoSchedule"* ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Taint not found or incorrect on node01.${NC}"
    FAILURE=1
fi

# 2. Check scheduled Pods on node01
echo -n "Checking for pods running on node01... "
# Excluding kube-system to check for user pod (Task 2)
POD_ON_NODE=$(kubectl get pods --all-namespaces --field-selector spec.nodeName=node01 --no-headers | grep -v "kube-system" | wc -l)
if [ "$POD_ON_NODE" -ge 1 ]; then
    echo -e "${GREEN}OK ($POD_ON_NODE user pods found)${NC}"
else
    echo -e "${RED}FAIL - No user pods found on node01. Did you add the toleration?${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
