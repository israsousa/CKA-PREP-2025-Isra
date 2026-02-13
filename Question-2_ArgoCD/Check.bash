#!/bin/bash

# Definition of colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Starting validation for Question 2 - ArgoCD..."
echo "--------------------------------------------"

FAILURE=0

# 1. Check if the 'argocd' namespace exists
echo -n "Checking if namespace 'argocd' exists... "
if kubectl get namespace argocd > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Namespace 'argocd' not found.${NC}"
    FAILURE=1
fi

# 2. Check if the 'argocd' helm repo is added
echo -n "Checking if helm repo 'argocd' is added... "
if helm repo list | grep -q "https://argoproj.github.io/argo-helm"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Helm repo 'argocd' not found or URL is incorrect.${NC}"
    FAILURE=1
fi

# 3. Check if the file /root/argo-helm.yaml exists
FILE="/root/argo-helm.yaml"
echo -n "Checking if file '$FILE' exists... "
if [ -f "$FILE" ]; then
    echo -e "${GREEN}OK${NC}"
    
    # 4. Check if the file was generated with the correct version (7.7.3 implies chart version 7.7.3)
    echo -n "Checking if generated from correct chart version (7.7.3)... "
    if grep -q "argo-cd-7.7.3" "$FILE" || grep -q "version: 7.7.3" "$FILE"; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - Could not find version 7.7.3 in the manifest metadata.${NC}"
         FAILURE=1
    fi

    # 5. Check if CRDs are NOT installed (should not find Kind: CustomResourceDefinition)
    echo -n "Checking if CRDs are excluded from the manifest... "
    if grep -q "kind: CustomResourceDefinition" "$FILE"; then
        echo -e "${RED}FAIL - Found CustomResourceDefinitions in the file. Did you use --set crds.install=false?${NC}"
        FAILURE=1
    else
        echo -e "${GREEN}OK${NC}"
    fi

else
    echo -e "${RED}FAIL - File '$FILE' does not exist.${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then
    echo -e "${GREEN}SUCCESS! All validation steps passed.${NC}"
else
    echo -e "${RED}FAILURE! One or more steps failed. Please review the errors above.${NC}"
fi
