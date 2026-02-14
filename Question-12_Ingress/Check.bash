#!/bin/bash

# Question 12: Ingress & Service Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 12 - Ingress..."

# 1. Check Service 'echo-service' in 'echo-sound'
echo -n "Checking Service 'echo-service'... "
SVC_PORT=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
SVC_TYPE=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.type}' 2>/dev/null)

if [ "$SVC_PORT" -eq 8080 ] && [ "$SVC_TYPE" == "NodePort" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Service missing or config mismatch (Port:$SVC_PORT Type:$SVC_TYPE).${NC}"
    FAILURE=1
fi

# 2. Check Ingress 'echo'
echo -n "Checking Ingress 'echo'... "
HOST=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
PATH_VAL=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
BACKEND=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
BPORT=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)

if [ "$HOST" == "example.org" ] && [ "$PATH_VAL" == "/echo" ] && [ "$BACKEND" == "echo-service" ] && [ "$BPORT" -eq 8080 ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Ingress mismatch. Host:$HOST, Path:$PATH_VAL, Backend:$BACKEND:$BPORT${NC}"
    FAILURE=1
fi

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
