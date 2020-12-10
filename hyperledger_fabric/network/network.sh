#!/bin/bash

export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=mychannel

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network.sh <mode>"
  echo "    <mode> - one of 'up', 'down', 'restart', 'generate', 'explorerUp', 'explorerDown'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "      - 'explorerUp' - bring up the hyperledger explorer with docker-compose up"
  echo "      - 'explorerStop' - stop the hyperledger explorer with docker-compose down"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel\")"
  echo
  echo "Taking all defaults:"
  echo "	network.sh generate"
  echo "	network.sh up"
  echo "	network.sh down"
}

function clearContainers() {
  echo
  echo "===================== Remove the local state ===================== "
  rm -f ~/.hfc-key-store/*
  
  echo
  echo "===================== Remove docker containers ====================="
  echo
  DOCKER_CONTAINER_IDS=$(docker ps -aq)
  if [ -z "$DOCKER_CONTAINER_IDS" -o "$DOCKER_CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $DOCKER_CONTAINER_IDS
  fi
}

function removeUnwantedImages() {
  echo
  echo "===================== Remove docker imgaes ====================="
  echo

  DOCKER_IMAGE_IDS=$(docker images dev-* -q)
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
    echo
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

function networkUp() {
  set -ev

  if [ ! -e "crypto-config" ]; then
      generateCerts
      replacePrivateKey
      generateChannel
  fi

  echo
  echo "===================== Create docker containers ====================="
  echo
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA up -d

  echo
  docker ps -a

  export FABRIC_START_TIMEOUT=10
  sleep ${FABRIC_START_TIMEOUT}

  # now run the end to end script
  docker exec cli scripts/createToChannel.sh $CHANNEL_NAME
  if [ $? -ne 0 ]; then
      echo "ERROR !!!! Test failed"
      exit 1
  fi
}

function networkDown() {
  echo
  echo "===================== Tear down running network ====================="
  echo
  
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA -f $COMPOSE_EXPLORER down -v

  if [ "$MODE" != "restart" ]; then
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages

    # Remove previous crypto material and config transactions
    rm -rf config
    rm -rf crypto-config
    rm -f docker-compose-ca.yaml
    rm -f connection.yaml
    
    # Remove hyperledger-explorer.json
    rm -rf ./explorer/connection-profile
  fi
}

function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
      echo "cryptogen tool not found. exiting"
      exit 1
  fi

  if [ ! -d "config" ]; then
      mkdir config
  fi

  if [ -d "crypto-config" ]; then
    rm -rf crypto-config
  fi

  # Generating crypto material
  echo
  echo "===================== Generating crypto material =====================" 
  cryptogen generate --config=./crypto-config.yaml
  if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
  fi
  echo
}

function replacePrivateKey() {
  echo "CA Key file exchange"

  cp ./base/docker-compose-ca-template.yaml docker-compose-ca.yaml

  PRIV_KEY=$(ls crypto-config/peerOrganizations/org1.example.com/ca/ | grep _sk)
  sed -i "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-ca.yaml
  PRIV_KEY=$(ls crypto-config/peerOrganizations/org2.example.com/ca/ | grep _sk)
  sed -i "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-ca.yaml
  PRIV_KEY=$(ls crypto-config/peerOrganizations/org3.example.com/ca/ | grep _sk)
  sed -i "s/CA3_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-ca.yaml

  echo "ORG AdminPrivate Key file exchange"

  cp ./base/connection-base.yaml connection.yaml

  PRIV_KEY=$(ls crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/ | grep _sk)
  sed -i "s/ORG1_ADMIN_PRIVATE_KEY/${PRIV_KEY}/g" connection.yaml
  PRIV_KEY=$(ls crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/ | grep _sk)
  sed -i "s/ORG2_ADMIN_PRIVATE_KEY/${PRIV_KEY}/g" connection.yaml
  PRIV_KEY=$(ls crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/keystore/ | grep _sk)
  sed -i "s/ORG3_ADMIN_PRIVATE_KEY/${PRIV_KEY}/g" connection.yaml

  echo ${PWD}
  sed -i "s|PWD|${PWD}|g" connection.yaml
}

function generateChannel() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
      echo "configtxgen tool not found. exiting"
      exit 1
  fi

  # Generating genesis block for orderer
  echo
  echo "Generating genesis block for orderer"
  configtxgen -profile ThreeOrgOrdererGenesis -outputBlock ./config/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  # Generating channel configuration transaction 'channel.tx'
  echo
  echo "Generating channel configuration transaction 'channel.tx'"
  configtxgen -profile ThreeOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  # Generating anchor peer update for Org1MSP
  echo
  echo "Generating anchor peer update for Org1MSP"
  configtxgen -profile ThreeOrgChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi

  # Generate anchor peer update for Org2MSP
  echo
  echo "Generating anchor peer update for Org2MSP"
  configtxgen -profile ThreeOrgChannel -outputAnchorPeersUpdate ./config/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2MSP..."
    exit 1
  fi

  # Generate anchor peer update for Org3MSP
  echo
  echo "Generating anchor peer update for Org3MSP"
  configtxgen -profile ThreeOrgChannel -outputAnchorPeersUpdate ./config/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org3MSP..."
    exit 1
  fi
  echo
}

function explorerUp() {
  echo
  echo "===================== Create Hyperledger Explorer containers ====================="
  echo
  
  if [ ! -d "explorer/connection-profile" ]; then
    echo "CA Key file & IPAddress exchange"
    mkdir ./explorer/connection-profile
    cp ./base/hyperledger-explorer-base.json ./explorer/connection-profile/hyperledger-explorer.json
    
    PRIV_KEY=$(ls crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/ | grep _sk)
    sed -i "s/ORG1_ADMIN_PRIVATE_KEY/${PRIV_KEY}/g" ./explorer/connection-profile/hyperledger-explorer.json

    # There are two bridges in the docker network, the 127.0.0.1 address remains an error when using the https protocol.
    IPADDRESS=$(docker inspect orderer.example.com | grep IPAddress |awk 'NR == 3 {print $2}' | tr -d '",')
    sed -i "s/ORDERER_IP/${IPADDRESS}/g" ./explorer/connection-profile/hyperledger-explorer.json
    IPADDRESS=$(docker inspect peer0.org1.example.com | grep IPAddress | awk 'NR == 3 {print $2}' | tr -d '",')
    sed -i "s/PEER0ORG1_IP/${IPADDRESS}/g" ./explorer/connection-profile/hyperledger-explorer.json
    IPADDRESS=$(docker inspect ca_peerOrg1 | grep IPAddress | awk 'NR == 3 {print $2}' | tr -d '",')
    sed -i "s/CAORG1_IP/${IPADDRESS}/g" ./explorer/connection-profile/hyperledger-explorer.json
  fi

  docker-compose -f $COMPOSE_EXPLORER up -d explorerdb.mynetwork.com
  sleep 10

  docker-compose -f $COMPOSE_EXPLORER up -d explorer.mynetwork.com
}

function explorerStop() {
  echo
  echo "===================== Stop running Hyperledger Explorer ====================="
  echo

  docker-compose -f $COMPOSE_EXPLORER stop
}

COMPOSE_FILE=docker-compose-cli.yaml
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
COMPOSE_FILE_CA=docker-compose-ca.yaml
COMPOSE_EXPLORER=docker-compose-explorer.yaml

CHANNEL_NAME="mychannel"

while getopts "h?c" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  c)
    CHANNEL_NAME=$OPTARG
    ;;
  esac
done

MODE=$1

if [ "${MODE}" == "up" ]; then # Create the network using docker compose
  networkUp
elif [ "${MODE}" == "down" ]; then # Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then # Generate Artifacts
  generateCerts
  replacePrivateKey
  generateChannel
elif [ "${MODE}" == "restart" ]; then # Restart the network
  networkDown
  networkUp
elif [ "${MODE}" == "explorerUp" ]; then # Create the hyperledger explorer using docker compose
  explorerUp
elif [ "${MODE}" == "explorerStop" ]; then # Clear the hyperledger explorer
  explorerStop
else
  printHelp
  exit 1
fi
