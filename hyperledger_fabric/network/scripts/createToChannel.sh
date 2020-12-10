#!/bin/bash
echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo "                                         "
echo

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel"}
DELAY="3"
TIMEOUT="10"
COUNTER=1
MAX_RETRY=10

# Import shell script
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./configtx/channel.tx
		res=$?
        set +x
	else
		set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./configtx/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
		res=$?
		set +x
	fi
	echo

	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2 3; do
	    for peer in 0 1 2; do
            joinChannelWithRetry $peer $org
            echo
			echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
            sleep $DELAY
            echo
	    done
	done
}

echo "Channel name : "$CHANNEL_NAME
echo

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 0 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 0 2
echo "Updating anchor peers for org3..."
updateAnchorPeers 0 3
# echo "Updating anchor peers for org4..."
# updateAnchorPeers 0 4

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo "                        "
echo

exit 0
