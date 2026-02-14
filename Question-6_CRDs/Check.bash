#!/bin/bash

# Question 6: CRDs Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 6 - CRDs..."

# 1. Check file /root/resources.yaml exists
echo -n "Checking if /root/resources.yaml exists... "
if [ -f "/root/resources.yaml" ]; then
     echo -e "${GREEN}OK${NC}"
     # Check content roughly
     if grep -q "cert-manager" "/root/resources.yaml"; then
         echo -e "   > Content looks valid (contains 'cert-manager')"
     else
         echo -e "${RED}FAIL - File does not contain 'cert-manager'.${NC}"
         FAILURE=1
     fi
else
     echo -e "${RED}FAIL - File not found.${NC}"
     FAILURE=1
fi

# 2. Check file /root/subject.yaml exists
echo -n "Checking if /root/subject.yaml exists... "
if [ -f "/root/subject.yaml" ]; then
     echo -e "${GREEN}OK${NC}"
     # Check content roughly (should contain explanation)
     if grep -q "KIND:.*Certificate" "/root/subject.yaml" || grep -q "FIELD:.*subject" "/root/subject.yaml"; then
         echo -e "   > Content looks valid"
     else
         echo -e "${RED}FAIL - File does not seem to contain correct explanation.${NC}"
         FAILURE=1
     fi
else
     echo -e "${RED}FAIL - File not found.${NC}"
     FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
