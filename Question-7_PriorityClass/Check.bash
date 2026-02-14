#!/bin/bash

# Question 7: PriorityClass Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 7 - PriorityClass..."

# 1. Check PriorityClass 'high-priority' exists
echo -n "Checking PriorityClass 'high-priority'... "
if kubectl get priorityclass high-priority > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - PriorityClass 'high-priority' not found.${NC}"
    FAILURE=1
fi

# 2. Check Value (Should be < highest but > 0, typically 999 based on sol)
if [ $FAILURE -eq 0 ]; then
    echo -n "Checking PriorityClass value... "
    VAL=$(kubectl get priorityclass high-priority -o jsonpath='{.value}')
    if [[ "$VAL" =~ ^[0-9]+$ ]]; then
         echo -e "${GREEN}OK (Value: $VAL)${NC}"
    else
         echo -e "${RED}FAIL - Value invalid: $VAL${NC}"
         FAILURE=1
    fi
fi

# 3. Check Deployment usage
echo -n "Checking if 'busybox-logger' uses 'high-priority'... "
PC=$(kubectl get deployment busybox-logger -n priority -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null)
if [ "$PC" == "high-priority" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Deployment uses '$PC', expected 'high-priority'.${NC}"
    FAILURE=1
fi

# 4. Check Pod Priority
echo -n "Checking running pod priority... "
POD_PC=$(kubectl get pods -n priority -l app=busybox-logger -o jsonpath='{.items[0].spec.priorityClassName}' 2>/dev/null)
if [ "$POD_PC" == "high-priority" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Pod spec shows '$POD_PC'. Was the deployment rolled out?${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
