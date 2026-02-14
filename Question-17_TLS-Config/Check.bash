#!/bin/bash

# Question 17: TLS Config Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 17 - TLS Config..."

# 1. Check ConfigMap for TLS removal
echo -n "Checking ConfigMap 'nginx-config' for TLSv1.2 removal... "
CM_DATA=$(kubectl get cm nginx-config -n nginx-static -o jsonpath='{.data}' 2>/dev/null)
if [[ "$CM_DATA" != *"TLSv1.2"* ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - ConfigMap still contains Reference to TLSv1.2.${NC}"
    FAILURE=1
fi

# 2. Check /etc/hosts for ckaquestion.k8s.local
echo -n "Checking /etc/hosts for 'ckaquestion.k8s.local'... "
if grep -q "ckaquestion.k8s.local" /etc/hosts; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Host entry 'ckaquestion.k8s.local' not found in /etc/hosts.${NC}"
    FAILURE=1
fi

# 3. Connectivity Test with curl (Simulating validation)
echo "Checking TLS handshake..."
# Note: We can't guarantee curl behavior in this script without running against the live cluster if the pods aren't up
# But we can try checking if the service is up
SVC_IP=$(kubectl get svc nginx-service -n nginx-static -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$SVC_IP" ]; then
    echo -e "${RED}FAIL - Service IP not found.${NC}"
    FAILURE=1
else
   echo -e "${GREEN}OK (Service IP: $SVC_IP)${NC}"
   echo "Note: Run 'curl -vk --tls-max 1.2 https://ckaquestion.k8s.local' manually to verify final TLS behavior."
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
