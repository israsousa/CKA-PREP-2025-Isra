#!/bin/bash

# Question 11: Gateway API Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 11 - Gateway API..."

# 1. Check Gateway 'web-gateway'
echo -n "Checking Gateway 'web-gateway' exists... "
if kubectl get gateway web-gateway > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Gateway 'web-gateway' not found.${NC}"
    FAILURE=1
fi

if [ $FAILURE -eq 0 ]; then
    # Check Gateway details
    echo -n "Checking Gateway class (nginx-class) and listener (HTTPS/443)... "
    CLASS=$(kubectl get gateway web-gateway -o jsonpath='{.spec.gatewayClassName}')
    PORT=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
    PROTO=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].protocol}')
    TLS_MODE=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].tls.mode}')
    TLS_SECRET=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].tls.certificateRefs[0].name}')
    
    if [ "$CLASS" == "nginx-class" ] && [ "$PORT" -eq 443 ] && [ "$PROTO" == "HTTPS" ] && [ "$TLS_MODE" == "Terminate" ] && [ "$TLS_SECRET" == "web-tls" ]; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - Gateway config mismatch. Class:$CLASS Port:$PORT Proto:$PROTO TLS:$TLS_MODE Secret:$TLS_SECRET${NC}"
         FAILURE=1
    fi
fi

# 2. Check HTTPRoute 'web-route'
echo -n "Checking HTTPRoute 'web-route' exists... "
if kubectl get httproute web-route > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - HTTPRoute 'web-route' not found.${NC}"
    FAILURE=1
fi

if [ $FAILURE -eq 0 ]; then
    # Check HTTPRoute details
    echo -n "Checking HTTPRoute config... "
    PARENT=$(kubectl get httproute web-route -o jsonpath='{.spec.parentRefs[0].name}')
    HOST=$(kubectl get httproute web-route -o jsonpath='{.spec.hostnames[0]}')
    BACKEND=$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].name}')
    BPORT=$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].port}')

    if [ "$PARENT" == "web-gateway" ] && [ "$HOST" == "gateway.web.k8s.local" ] && [ "$BACKEND" == "web-service" ] && [ "$BPORT" -eq 80 ]; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}FAIL - HTTPRoute config mismatch. Parent:$PARENT Host:$HOST Backend:$BACKEND Port:$BPORT${NC}"
         FAILURE=1
    fi
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
