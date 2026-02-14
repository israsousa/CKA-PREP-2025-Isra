#!/bin/bash

# Question 8: CNI Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 8 - CNI (Flannel/Calico)..."

# 1. Check for CNI Pods (Flannel or Calico)
echo -n "Checking for CNI pods... "
CALICO=$(kubectl get pods -n tigera-operator --no-headers 2>/dev/null | wc -l)
CALICO_NODE=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | wc -l)
FLANNEL=$(kubectl get pods -n kube-flannel --no-headers 2>/dev/null | wc -l)
FLANNEL_SYS=$(kubectl get pods -n kube-system -l app=flannel --no-headers 2>/dev/null | wc -l)

if [ "$CALICO" -gt 0 ] || [ "$CALICO_NODE" -gt 0 ]; then
    echo -e "${GREEN}OK (Calico detected)${NC}"
elif [ "$FLANNEL" -gt 0 ] || [ "$FLANNEL_SYS" -gt 0 ]; then
    echo -e "${GREEN}OK (Flannel detected)${NC}"
else
    echo -e "${RED}FAIL - No standard CNI pods (Calico/Flannel) found running.${NC}"
    FAILURE=1
fi

# 2. Check Node Status (should be Ready if CNI works)
echo -n "Checking if nodes are Ready... "
NOT_READY=$(kubectl get nodes --no-headers | grep "NotReady" | wc -l)
if [ "$NOT_READY" -eq 0 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - $NOT_READY nodes are NotReady. CNI might be failing.${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
