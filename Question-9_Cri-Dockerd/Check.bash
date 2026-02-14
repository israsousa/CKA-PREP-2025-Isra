#!/bin/bash

# Question 9: Cri-Dockerd Check
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILURE=0

echo "Starting validation for Question 9 - Cri-Dockerd..."

# 1. Check Service Status
echo -n "Checking status of 'cri-docker' service (systemd)... "
if systemctl is-active cri-docker > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL - Service 'cri-docker' is not active.${NC}"
    FAILURE=1
fi

# 2. Check Sysctl Parameters
check_sysctl() {
    PARAM=$1
    EXPECTED=$2
    VAL=$(sysctl -n $PARAM 2>/dev/null)
    if [ "$VAL" == "$EXPECTED" ]; then
        echo -e "Checking $PARAM = $EXPECTED... ${GREEN}OK${NC}"
    else
        echo -e "Checking $PARAM = $EXPECTED... ${RED}FAIL (Got '$VAL')${NC}"
        FAILURE=1
    fi
}

check_sysctl "net.bridge.bridge-nf-call-iptables" "1"
check_sysctl "net.ipv6.conf.all.forwarding" "1"
check_sysctl "net.ipv4.ip_forward" "1"
check_sysctl "net.netfilter.nf_conntrack_max" "131072"

echo "--------------------------------------------"
if [ $FAILURE -eq 0 ]; then echo -e "${GREEN}SUCCESS!${NC}"; else echo -e "${RED}FAILURE!${NC}"; fi
