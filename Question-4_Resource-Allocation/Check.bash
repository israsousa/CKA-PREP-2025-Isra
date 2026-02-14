#!/bin/bash

# Question 4: Resource Allocation Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 4 - Resource Allocation..."

# 1. Check Replica Count
echo -n "Checking if replicas are set to 3... "
REPLICAS=$(kubectl get deployment wordpress -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" -eq 3 ]; then
     echo -e "${GREEN}OK${NC}"
else
     echo -e "${RED}FAIL - Expected 3 replicas, got $REPLICAS.${NC}"
     FAILURE=1
fi

# 2. Check if resources are defined and equal across containers
echo -n "Checking if resources are defined and equal for all containers... "
# Get resources for main container
MAIN_CPU_REQ=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
MAIN_MEM_REQ=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
MAIN_CPU_LIM=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
MAIN_MEM_LIM=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')

# Get resources for init container
INIT_CPU_REQ=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}')
INIT_MEM_REQ=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.memory}')
INIT_CPU_LIM=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.cpu}')
INIT_MEM_LIM=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.memory}')

if [ -z "$MAIN_CPU_REQ" ] || [ -z "$INIT_CPU_REQ" ]; then
    echo -e "${RED}FAIL - Resources not fully defined.${NC}"
    FAILURE=1
elif [ "$MAIN_CPU_REQ" == "$INIT_CPU_REQ" ] && [ "$MAIN_MEM_REQ" == "$INIT_MEM_REQ" ] && \
     [ "$MAIN_CPU_LIM" == "$INIT_CPU_LIM" ] && [ "$MAIN_MEM_LIM" == "$INIT_MEM_LIM" ]; then
     echo -e "${GREEN}OK${NC}"
else
     echo -e "${RED}FAIL - Resources mismatch between Init and Main containers.${NC}"
     echo "Main: $MAIN_CPU_REQ / $MAIN_MEM_REQ / $MAIN_CPU_LIM / $MAIN_MEM_LIM"
     echo "Init: $INIT_CPU_REQ / $INIT_MEM_REQ / $INIT_CPU_LIM / $INIT_MEM_LIM"
     FAILURE=1
fi

# 3. Check Pod Status
echo -n "Checking if pods are running... "
RUNNING_PODS=$(kubectl get pods -l app=wordpress --field-selector=status.phase=Running --no-headers | wc -l)
if [ "$RUNNING_PODS" -ge 3 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Expected 3 running pods, found $RUNNING_PODS.${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
