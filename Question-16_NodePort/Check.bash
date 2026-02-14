#!/bin/bash

# Question 16: NodePort Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 16 - NodePort..."

# 1. Check Deployment container port
echo -n "Checking Deployment port 80/TCP... "
DEP_PORT=$(kubectl get deployment nodeport-deployment -n relative -o jsonpath='{.spec.template.spec.containers[0].ports[?(@.containerPort==80)].containerPort}' 2>/dev/null)
if [ "$DEP_PORT" -eq 80 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Deployment does not have containerPort 80.${NC}"
    FAILURE=1
fi

# 2. Check Service
echo -n "Checking Service 'nodeport-service'... "
SVC_PORT=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
NODE_PORT=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

if [ "$SVC_PORT" -eq 80 ] && [ "$NODE_PORT" -eq 30080 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Service invalid. Port:$SVC_PORT NodePort:$NODE_PORT (Expected 80/30080).${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
