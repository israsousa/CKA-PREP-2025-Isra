#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

FAILURE=0

echo "Starting validation for MariaDB Persistent Volume Lab..."
echo ""

echo -n "Checking PVC 'mariadb' exists... "

if kubectl get pvc mariadb -n mariadb >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - PVC not found${NC}"
    FAILURE=1
fi

echo -n "Checking PVC specs (250Mi / ReadWriteOnce)... "

STORAGE=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
ACCESS=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)

if [[ "$STORAGE" == "250Mi" && "$ACCESS" == "ReadWriteOnce" ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Expected 250Mi/RWO but got ${STORAGE}/${ACCESS}${NC}"
    FAILURE=1
fi

echo -n "Checking PVC status... "

STATUS=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null)

if [[ "$STATUS" == "Bound" ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - PVC not Bound${NC}"
    FAILURE=1
fi

echo -n "Checking PV reuse... "

PV_NAME=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.spec.volumeName}' 2>/dev/null)

if [[ "$PV_NAME" == "mariadb-pv" ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - PVC not bound to expected PV${NC}"
    FAILURE=1
fi

echo -n "Checking Deployment exists... "

if kubectl get deployment maria-deployment -n mariadb >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Deployment not found${NC}"
    FAILURE=1
fi

echo -n "Checking Deployment uses PVC... "

if kubectl get deployment maria-deployment -n mariadb -o json | grep -q '"claimName": "mariadb"'; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Deployment does not mount PVC${NC}"
    FAILURE=1
fi

echo -n "Checking Pod status... "

POD_STATUS=$(kubectl get pods -n mariadb -l app=maria-deployment -o jsonpath='{.items[0].status.phase}' 2>/dev/null)

if [[ "$POD_STATUS" == "Running" ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Pod not running${NC}"
    FAILURE=1
fi

echo ""
echo "---------------------------------------"

if [[ $FAILURE -eq 0 ]]; then
    echo -e "${GREEN}SUCCESS! All checks passed.${NC}"
else
    echo -e "${RED}FAILURE! Some checks failed.${NC}"
fi