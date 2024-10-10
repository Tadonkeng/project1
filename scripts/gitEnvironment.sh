#!/bin/bash


BB_IP=`curl -s http://$METADATA_IP/latest/meta-data/local-ipv4`
KNOWN_HOST=`cat /root/.ssh/known_hosts | grep $BB_IP`

echo "{"
echo "  \"known_host\": \"$KNOWN_HOST\"",
echo "  \"bastion_ip\": \"$BB_IP\""
echo "}"


