#!/bin/bash

# Question 3: Sidecar Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 3 - Sidecar..."

# 1. Check if sidecar container exists
echo -n "Checking for container 'sidecar' in Deployment 'wordpress'... "
HAS_SIDECAR=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].name}' 2>/dev/null)

if [ "$HAS_SIDECAR" == "sidecar" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Container 'sidecar' not found in deployment spec.${NC}"
    FAILURE=1
fi

# 2. Check image and command
if [ "$HAS_SIDECAR" == "sidecar" ]; then
    echo -n "Checking sidecar image and command... "
    IMAGE=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}')
    CMD=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command}')
    
    if [[ "$IMAGE" == "busybox:stable" ]] && [[ "$CMD" == *"/bin/sh"* ]] && [[ "$CMD" == *"tail -f /var/log/wordpress.log"* ]]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL - Image or command incorrect. Got Image: $IMAGE, Cmd: $CMD${NC}"
        FAILURE=1
    fi
fi

# 3. Check volume mounts (shared volume)
echo -n "Checking if 'wordpress' and 'sidecar' share a volume... "
WP_VOL=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)
SC_VOL=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")].name}' 2>/dev/null)

if [ -n "$WP_VOL" ] && [ "$WP_VOL" == "$SC_VOL" ]; then
     echo -e "${GREEN}OK${NC}"
else
     echo -e "${RED}FAIL - Containers do not seem to share a volume at /var/log.${NC}"
     FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
