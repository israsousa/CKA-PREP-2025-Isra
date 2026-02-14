#!/bin/bash

# Question 15: Etcd-Fix Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 15 - Etcd Fix..."

# 1. Check API Server connectivity
echo -n "Checking if 'kubectl get nodes' works (API Server is responding)... "
if kubectl get nodes > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - API Server does not seem to be responding.${NC}"
    FAILURE=1
fi

# 2. Check kube-apiserver pod status
echo -n "Checking kube-apiserver pod status... "
POD_STATUS=$(kubectl -n kube-system get pods -l component=kube-apiserver -o jsonpath='{.items[0].status.phase}' 2>/dev/null)

if [ "$POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - kube-apiserver pod is '$POD_STATUS' (expected Running).${NC}"
    # Note: On some managed clusters checking static pods like this might differ, but for CKA/Kind/Killer it works
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
