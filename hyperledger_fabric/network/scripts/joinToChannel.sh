#!/bin/bash

DELAY="3"
TIMEOUT="10"
COUNTER=1
MAX_RETRY=10

echo
echo "========= Creating config transaction to add org4 to network =========== "
echo

# Import shell script
. scripts/utils.sh

echo "Fetching channel config block from orderer..."
set -x
peer channel fetch 0 $CHANNEL_NAME.block -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
set +x

sleep ${DELAY}

joinChannelWithRetry 0 4
echo "===================== peer0.org4 joined channel '$CHANNEL_NAME' ===================== "
joinChannelWithRetry 1 4
echo "===================== peer1.org4 joined channel '$CHANNEL_NAME' ===================== "
joinChannelWithRetry 2 4
echo "===================== peer2.org4 joined channel '$CHANNEL_NAME' ===================== "