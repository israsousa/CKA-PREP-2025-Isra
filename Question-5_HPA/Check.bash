#!/bin/bash

# Question 5: HPA Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 5 - HPA..."

# 1. Check if HPA exists
echo -n "Checking if HPA 'apache-server' exists in 'autoscale' namespace... "
if kubectl get hpa apache-server -n autoscale > /dev/null 2>&1; then
     echo -e "${GREEN}OK${NC}"
else
     echo -e "${RED}FAIL - HPA not found.${NC}"
     FAILURE=1
fi

if [ $FAILURE -eq 0 ]; then
    # 2. Check Target Ref
    echo -n "Checking HPA target... "
    TARGET=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.scaleTargetRef.name}')
    if [ "$TARGET" == "apache-deployment" ]; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - Targeted $TARGET, expected apache-deployment.${NC}"
         FAILURE=1
    fi

    # 3. Check Min/Max Replicas
    echo -n "Checking Min/Max replicas (1/4)... "
    MIN=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.minReplicas}')
    MAX=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.maxReplicas}')
    if [ "$MIN" -eq 1 ] && [ "$MAX" -eq 4 ]; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - Got Min:$MIN Max:$MAX.${NC}"
         FAILURE=1
    fi

    # 4. Check CPU Target (50%)
    echo -n "Checking CPU target (50%)... "
    CPU=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}')
    if [ "$CPU" -eq 50 ]; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - Expected 50, got $CPU.${NC}"
         FAILURE=1
    fi

    # 5. Check Stabilization Window
    echo -n "Checking ScaleDown stabilization window (30s)... "
    WINDOW=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}')
    if [ "$WINDOW" -eq 30 ]; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - Expected 30, got $WINDOW.${NC}"
         FAILURE=1
    fi
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
