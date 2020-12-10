#!/bin/bash

# This is a collection of bash functions used by different scripts

# cli working directory 
CONFIG_ROOT=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto

ORDERER_CA=${CONFIG_ROOT}/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
PEER0_ORG1_CA=${CONFIG_ROOT}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
PEER0_ORG2_CA=${CONFIG_ROOT}/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
PEER0_ORG3_CA=${CONFIG_ROOT}/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
PEER0_ORG4_CA=${CONFIG_ROOT}/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt

setOrdererGlobals() {
    CORE_PEER_LOCALMSPID="OrdererMSP"
    CORE_PEER_TLS_ROOTCERT_FILE=${CONFIG_ROOT}/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
    CORE_PEER_MSPCONFIGPATH=${CONFIG_ROOT}/ordererOrganizations/example.com/users/Admin@example.com/msp
}

setGlobals() {
    PEER=$1
    ORG=$2
    if [ $ORG -eq 1 ]; then
        CORE_PEER_LOCALMSPID="Org1MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
        CORE_PEER_MSPCONFIGPATH=${CONFIG_ROOT}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        if [ $PEER -eq 0 ]; then
            CORE_PEER_ADDRESS=peer0.org1.example.com:7051
        elif [ $PEER -eq 1 ]; then
            CORE_PEER_ADDRESS=peer1.org1.example.com:7151
        else
            CORE_PEER_ADDRESS=peer2.org1.example.com:7251
        fi
    elif [ $ORG -eq 2 ]; then
        CORE_PEER_LOCALMSPID="Org2MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
        CORE_PEER_MSPCONFIGPATH=${CONFIG_ROOT}/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
        if [ $PEER -eq 0 ]; then
            CORE_PEER_ADDRESS=peer0.org2.example.com:8051
        elif [ $PEER -eq 1 ]; then
            CORE_PEER_ADDRESS=peer1.org2.example.com:8151
        else
            CORE_PEER_ADDRESS=peer2.org2.example.com:8251
        fi
    elif [ $ORG -eq 3 ]; then
        CORE_PEER_LOCALMSPID="Org3MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
        CORE_PEER_MSPCONFIGPATH=${CONFIG_ROOT}/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
        if [ $PEER -eq 0 ]; then
            CORE_PEER_ADDRESS=peer0.org3.example.com:9051
        elif [ $PEER -eq 1 ]; then
            CORE_PEER_ADDRESS=peer1.org3.example.com:9151
        else
            CORE_PEER_ADDRESS=peer2.org3.example.com:9251
        fi
    elif [ $ORG -eq 4 ]; then
        CORE_PEER_LOCALMSPID="Org4MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG4_CA
        CORE_PEER_MSPCONFIGPATH=${CONFIG_ROOT}/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
        if [ $PEER -eq 0 ]; then
            CORE_PEER_ADDRESS=peer0.org4.example.com:10051
        elif [ $PEER -eq 1 ]; then
            CORE_PEER_ADDRESS=peer1.org4.example.com:10151
        else
            CORE_PEER_ADDRESS=peer2.org4.example.com:10251
        fi
    else
        echo "================== ERROR !!! ORG Unknown =================="
    fi
}

updateAnchorPeers() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
        peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./configtx/${CORE_PEER_LOCALMSPID}anchors.tx
        res=$?
        set +x
    else
        set -x
        peer channel update \
            -o orderer.example.com:7050 \
            -c $CHANNEL_NAME \
            -f ./configtx/${CORE_PEER_LOCALMSPID}anchors.tx \
            --tls $CORE_PEER_TLS_ENABLED \
            --cafile $ORDERER_CA
        res=$?
        set +x
    fi

    echo
    echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
    sleep $DELAY
    echo
}

installChaincode() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    set -x
    peer chaincode install -n $CHAINCODE_NAME -v $VERSION -p $CC_SRC_PATH
    res=$?
    set +x

    echo
    echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
    echo
}

instantiateChaincode() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    PRINCIPAL_ARRAY=($3)
    conversionStringToPrincipal ${PRINCIPAL_ARRAY[@]}

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
        peer chaincode instantiate \
            -o orderer.example.com:7050 \
            -C $CHANNEL_NAME \
            -n $CHAINCODE_NAME \
            -v $VERSION \
            -c '{"Args":[]}' \
            -P "${PRINCIPAL_CTOR}"
        res=$?0
        set +x
    else
        set -x
        peer chaincode instantiate \
            -o orderer.example.com:7050 \
            --tls $CORE_PEER_TLS_ENABLED \
            --cafile $ORDERER_CA \
            -C $CHANNEL_NAME \
            -n $CHAINCODE_NAME \
            -v $VERSION \
            -c '{"Args":[]}' \
            -P "${PRINCIPAL_CTOR}"
        res=$?
        set +x
    fi

    echo
    echo "===================== Chaincode is instantiated on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
    echo
}

upgradeChaincode() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    PRINCIPAL_ARRAY=($3)
    conversionStringToPrincipal ${PRINCIPAL_ARRAY[@]}

    set -x
    peer chaincode upgrade \
        -o orderer.example.com:7050 \
        --tls $CORE_PEER_TLS_ENABLED \
        --cafile $ORDERER_CA \
        -C $CHANNEL_NAME \
        -n $CHAINCODE_NAME \
        -v $VERSION \
        -c '{"Args":[]}' \
        -P "${PRINCIPAL_CTOR}"
    res=$?
    set +x

    echo
    echo "===================== Chaincode is upgraded on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
    echo
}

chaincodeQuery() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    JSON_ARRAY=($3)
    conversionStringToJson ${JSON_ARRAY[@]}

    echo
    peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c $JSON_CTOR
    echo
    echo "===================== Query successful on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
    echo
}

joinChannelWithRetry() {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    set -x
    peer channel join -b $CHANNEL_NAME.block
    res=$?
    set +x

    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
        COUNTER=$(expr $COUNTER + 1)
        echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
        sleep $DELAY
        joinChannelWithRetry $PEER $ORG
    else
        COUNTER=1
    fi
}

fetchChannelConfig() {
  CHANNEL=$1
  OUTPUT=$2

  setOrdererGlobals

  echo "Fetching the most recent configuration block for the channel"
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL --cafile $ORDERER_CA
    set +x
  else
    set -x
    peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL --tls --cafile $ORDERER_CA
    set +x
  fi

  echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >"${OUTPUT}"
  set +x
}

signConfigtxAsPeerOrg() {
  PEERORG=$1
  TX=$2
  setGlobals 0 $PEERORG
  set -x
  peer channel signconfigtx -f "${TX}"
  set +x
}

createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config >original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config >modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb >config_update.pb
  configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"${OUTPUT}"
  set +x
}

parsePeerConnectionParameters() {
    # check for uneven number of peer and org parameters
    if [ $(($# % 2)) -ne 0 ]; then
        exit 1
    fi

    PEER_CONN_PARMS=""
    PEERS=""
    while [ "$#" -gt 0 ];
    do
        setGlobals $1 $2
        PEER="peer$1.org$2"
        PEERS="$PEERS $PEER"
        PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
        
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "true" ]; then
            TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$1_ORG$2_CA")
            PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
        fi
        shift
        shift
    done

    PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

chaincodeInvoke() {
    echo
    PEER_ARRAY=($1)
    JSON_ARRAY=($2)

    parsePeerConnectionParameters ${PEER_ARRAY[@]}
    conversionStringToJson ${JSON_ARRAY[@]} 

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
        peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n $CHAINCODE_NAME $PEER_CONN_PARMS -c $JSON_CTOR
        res=$?
        set +x
    else
        set -x
        peer chaincode invoke \
            -o orderer.example.com:7050 \
            --tls $CORE_PEER_TLS_ENABLED \
            --cafile $ORDERER_CA \
            -C $CHANNEL_NAME \
            -n $CHAINCODE_NAME $PEER_CONN_PARMS \
            -c $JSON_CTOR
        res=$?
        set +x
    fi

    echo
    echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
    echo
}

conversionStringToJson() {
    JSON_CTOR='{"Args":["'"$1"'"'

    shift
    while [ "$#" -gt 0 ];
    do
        JSON_CTOR="${JSON_CTOR},\"$1\""
	    shift
    done

    JSON_CTOR="${JSON_CTOR}]}"
}

conversionStringToPrincipal() {
    PRINCIPAL_CTOR="$1 ('$2'"
    shift
    shift

    while [ "$#" -gt 0 ];
    do
        PRINCIPAL_CTOR="${PRINCIPAL_CTOR}, '$1'"
        shift
    done

    PRINCIPAL_CTOR="${PRINCIPAL_CTOR})"
}