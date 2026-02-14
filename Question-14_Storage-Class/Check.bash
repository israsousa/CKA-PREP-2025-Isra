#!/bin/bash

# Question 14: Storage Class Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 14 - Storage Class..."

# 1. Check SC 'local-storage'
echo -n "Checking StorageClass 'local-storage' exists... "
if kubectl get sc local-storage > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - StorageClass 'local-storage' not found.${NC}"
    FAILURE=1
fi

if [ $FAILURE -eq 0 ]; then
    # 2. Check Provisioner and BindingMode
    echo -n "Checking Provisioner and BindingMode... "
    PROV=$(kubectl get sc local-storage -o jsonpath='{.provisioner}')
    MODE=$(kubectl get sc local-storage -o jsonpath='{.volumeBindingMode}')
    
    if [ "$PROV" == "rancher.io/local-path" ] && [ "$MODE" == "WaitForFirstConsumer" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL - Config mismatch. Prov:$PROV, Mode:$MODE${NC}"
        FAILURE=1
    fi

    # 3. Check if it is Default (annotation)
    echo -n "Checking if 'local-storage' is the DEFAULT... "
    DEF=$(kubectl get sc local-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}')
    if [ "$DEF" == "true" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL - Not marked as default class.${NC}"
        FAILURE=1
    fi

    # 4. Check if 'local-path' is NOT default
    echo -n "Checking if 'local-path' is NOT default... "
    DEF_OTHER=$(kubectl get sc local-path -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null)
    if [ "$DEF_OTHER" != "true" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL - 'local-path' is still marked as default.${NC}"
        FAILURE=1
    fi
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
