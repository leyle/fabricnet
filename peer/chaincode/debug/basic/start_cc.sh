#!/bin/bash

# start chaincode asset transfer basic

# base path means current peer node work dir(e.g $SOMEPATH/nodevolume/peer0.dev.emali.dev)
DEBUG_BASE_PATH=$PWD/../../../

ENV_FILE=$DEBUG_BASE_PATH/env.sh
PEER_ENV_FILE=$DEBUG_BASE_PATH/peer.env
CC_LAST_ENV_FILE=$DEBUG_BASE_PATH/chaincode/last.env

. $ENV_FILE
. $PEER_ENV_FILE
. $CC_LAST_ENV_FILE

sed "s|\$CC_HOST_NAME|$CC_HOST_NAME|g; " ./cc_template.yaml > cc.yaml

echo "try to get cd id..."
CC_LABEL=$CC_NAME
CC_PKG_ID=$(peer lifecycle chaincode queryinstalled -O json | jq --arg LABEL $CC_LABEL -r '.installed_chaincodes[] | select(.label==$LABEL).package_id')
echo "package id is: $CC_PKG_ID"
if [ -z "$CC_PKG_ID" ]; then
    echo "get chaincode package id failed"
    exit 1
fi

export CC_ID=$CC_PKG_ID
export CC_VERSION=v1.0.5

docker-compose -f cc.yaml up

