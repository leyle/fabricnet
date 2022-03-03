#!/bin/bash

. ./chaincode.env

APP_CHANNEL_NAME=$1
if [ -z "$APP_CHANNEL_NAME" ]; then
    echo "No channel name"
    exit 1
fi

CC_SEQUENCE=$2
if [ -z "$CC_SEQUENCE" ]; then
    echo "No sequence"
    exit 1
fi

ORDERER_HOST=$3
if [ -z "$ORDERER_HOST" ]; then
    echo "No orderer host"
    exit 1
fi

ORDERER_PORT=$4
if [ -z "$ORDERER_PORT" ]; then
    echo "No orderer port"
    exit 1
fi

# orderer info
ORDERER_HOSTPORT=$ORDERER_HOST:$ORDERER_PORT

echo "export APP_CHANNEL_NAME=$APP_CHANNEL_NAME" > last.env
echo "export CC_SEQUENCE=$CC_SEQUENCE" > last.env
echo "export ORDERER_HOST=$ORDERER_HOST" >> last.env
echo "export ORDERER_PORT=$ORDERER_PORT" >> last.env
echo "export ORDERER_HOSTPORT=$ORDERER_HOSTPORT" >> last.env

# approve chaincode definition
# https://stedolan.github.io/jq/manual/
echo "try to approve external chaincode"
peer lifecycle chaincode queryinstalled
CC_LABEL=$CC_NAME

export CC_PKG_ID=$(peer lifecycle chaincode queryinstalled -O json | jq --arg LABEL $CC_LABEL -r '.installed_chaincodes[] | select(.label==$LABEL).package_id')
echo "package id is: $CC_PKG_ID"
if [ -z "$CC_PKG_ID" ]; then
    echo "Get package id failed"
    exit 1
fi

peer lifecycle chaincode approveformyorg -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride ${ORDERER_HOST} --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --version ${CC_PKG_VER} --package-id ${CC_PKG_ID} --sequence ${CC_SEQUENCE} --tls true --cafile ${TLS_CA_FILE}

peer lifecycle chaincode checkcommitreadiness --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --version ${CC_PKG_VER} --sequence ${CC_SEQUENCE} --tls true --cafile ${TLS_CA_FILE}
