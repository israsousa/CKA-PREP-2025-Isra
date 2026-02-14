#!/bin/bash

# Question 1: MariaDB Persistent Volume Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 1 - MariaDB Persistent Volume..."

# 1. Check PVC 'mariadb' in 'mariadb' namespace
echo -n "Checking if PVC 'mariadb' exists in namespace 'mariadb'... "
if kubectl get pvc mariadb -n mariadb > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - PVC 'mariadb' not found in namespace 'mariadb'.${NC}"
    FAILURE=1
fi

# 2. Check PVC capacity and access modes
if [ $FAILURE -eq 0 ]; then
    echo -n "Checking PVC specs (250Mi, ReadWriteOnce)... "
    STORAGE=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.resources.requests.storage}')
    ACCESS=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.accessModes[0]}')
    
    if [ "$STORAGE" == "250Mi" ] && [ "$ACCESS" == "ReadWriteOnce" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL - Expected 250Mi/ReadWriteOnce, got ${STORAGE}/${ACCESS}.${NC}"
        FAILURE=1
    fi
fi

# 3. Check if PVC is Bound
echo -n "Checking if PVC is Bound... "
STATUS=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$STATUS" == "Bound" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - PVC status is ${STATUS} (expected Bound).${NC}"
    FAILURE=1
fi

# 4. Check Deployment
echo -n "Checking if Deployment 'mariadb' is using the PVC... "
# Fetch the full JSON of the deployment and check for the claimName in the volumes section
if kubectl get deployment mariadb -n mariadb -o json | grep -q '"claimName": "mariadb"'; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Deployment does not seem to mount PVC 'mariadb'.${NC}"
    # Optional debug output
    echo "Debug: Volumes found:"
    kubectl get deployment mariadb -n mariadb -o jsonpath='{.spec.template.spec.volumes}' 2>/dev/null
    FAILURE=1
fi

# 5. Check Pod status
echo -n "Checking if MariaDB pods are running... "
POD_STATUS=$(kubectl get pods -n mariadb -l app=mariadb -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" == "Running" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Pod status is ${POD_STATUS}.${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
