#!/bin/bash

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  extendNetwork.sh <mode>"
  echo "    <mode> - one of 'up', 'down', 'restart', 'generate'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel\")"
  echo "    -n <chaincode name> - chaincode name to use (defaults to \"mysacc\")"
  echo "    -v <chaincode version> - chaincode verstion to use (defaults to \"v1.0.0\")"
  echo
  echo "Taking all defaults:"
  echo "	extendNetwork.sh generate"
  echo "	extendNetwork.sh up"
  echo "	extendNetwork.sh down"
}


# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers () {
  echo
  echo "===================== Remove docker containers ====================="
  echo
  DOCKER_CONTAINER_IDS=$(docker ps -a | awk '($13 ~ /.*.org4/) {print $1}')
  if [ -z "$DOCKER_CONTAINER_IDS" -o "$DOCKER_CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $DOCKER_CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
  echo
  echo "===================== Remove docker imgaes ====================="
  echo

  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-.*.org4/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
    echo
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp () {
  # generate artifacts if they don't exist
  if [ ! -d "org4-artifacts/crypto-config" ]; then
    generateCerts
    generateChannelArtifacts
    createConfigTx
  fi
  
  # start org4 peers
  docker-compose -f $COMPOSE_FILE_ORG4 up -d

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start Org4 network"
    exit 1
  fi

  echo
  echo "###############################################################"
  echo "############### Have Org4 peers join network ##################"
  echo "###############################################################"
  docker exec cli_Org4 ./scripts/joinToChannel.sh $CHANNEL_NAME $CHAINCODE_NAME $VERSION
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to have Org4 peers join network"
    exit 1
  fi
}

# Tear down running network
function networkDown () {
  docker-compose -f $COMPOSE_FILE_ORG4 down
  
  docker volume rm $(docker volume ls | awk '($2 ~ /net_.*.org4/) {print $2}')
  

  # Don't remove containers, images, etc if restarting
  if [ "$MODE" != "restart" ]; then
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    rm -rf ./org4-artifacts/crypto-config/ ./config/org4.json
  fi
}

# Use the CLI container to create the configuration transaction needed to add
# Org3 to the network
function createConfigTx () {
  echo
  echo "###############################################################"
  echo "####### Generate and submit config tx to add Org4 #############"
  echo "###############################################################"
  docker exec cli scripts/addOrgToNetwork.sh $CHANNEL_NAME
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to create config tx"
    exit 1
  fi
}

# Generates Org4 certs using cryptogen tool
function generateCerts (){
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "###############################################################"
  echo "##### Generate Org4 certificates using cryptogen tool #########"
  echo "###############################################################"

  if [ -d "org4-artifacts/crypto-config" ]; then
      rm -rf ./org4-artifacts/crypto-config/*
    fi

  (cd org4-artifacts
   set -x
   cryptogen generate --config=./crypto-config-org4.yaml
   res=$?
   set +x
   if [ $res -ne 0 ]; then
     echo "Failed to generate certificates..."
     exit 1
   fi
  )
  echo
}

# Generate channel configuration transaction
function generateChannel() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  echo "##########################################################"
  echo "#########  Generating Org4 config material ###############"
  echo "##########################################################"
  (cd org4-artifacts
   export FABRIC_CFG_PATH=$PWD
   set -x
   configtxgen -printOrg Org4MSP > ../config/org4.json
   res=$?
   set +x
   if [ $res -ne 0 ]; then
     echo "Failed to generate Org3 config material..."
     exit 1
   fi
  )
  cp -r crypto-config/ordererOrganizations org4-artifacts/crypto-config/
  echo
}


# If network wasn't run abort
if [ ! -d crypto-config ]; then
  echo
  echo "ERROR: Please, run network.sh first."
  echo
  exit 1
fi

COMPOSE_FILE=docker-compose-cli.yaml
COMPOSE_FILE_ORG4=docker-compose-org4.yaml
COMPOSE_FILE_COUCH=docker-compose-couch.yaml

CHANNEL_NAME="mychannel"
CHAINCODE_NAME="mysacc"
VERSION="v1.0.0"

# Parse commandline args
if [ "$1" = "-m" ];then	# supports old usage, muscle memory is powerful!
    shift
fi

while getopts "h?c:n:v" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  c)
    CHANNEL_NAME=$OPTARG
    ;;
  n)
    CHAINCODE_NAME=$OPTARG
    ;;
  v)
    VERSION=$OPTARG
    ;;
  esac
done

MODE=$1

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateCerts
  generateChannel
  createConfigTx
elif [ "${MODE}" == "restart" ]; then ## Restart the network
  networkDown
  networkUp
else
  printHelp
  exit 1
fi
