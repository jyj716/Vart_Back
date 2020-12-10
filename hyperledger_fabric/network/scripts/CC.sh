#!/bin/bash

echo
echo "====================Testing Chaincode vart===================="
echo

docker exec cli ./scripts/vart/CC_vart_install.sh
# docker exec cli ./scripts/vart/CC_vart_upgrade.sh
# docker exec cli ./scripts/vart/CC_vart_instructions.sh

echo
echo "====================Testing Chaincode disclosure===================="
echo

docker exec cli ./scripts/disclosure/CC_disclosure_install.sh
# docker exec cli ./scripts/disclosure/CC_disclosure_upgrade.sh
# docker exec cli ./scripts/disclosure/CC_disclosure_instructions.sh
