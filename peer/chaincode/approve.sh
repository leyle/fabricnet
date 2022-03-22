#!/bin/bash
set -e

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

# --cafile Path to file containing PEM-encoded trusted certificate(s) for the ordering endpoint 
ORDERER_TLS_CA_FILE=$5
if [ ! -f "$ORDERER_TLS_CA_FILE" ]; then
    echo "No orderer tls ca file"
    exit 1
fi

# orderer info
ORDERER_HOSTPORT=$ORDERER_HOST:$ORDERER_PORT

echo " " > last.env
echo "export APP_CHANNEL_NAME=$APP_CHANNEL_NAME" >> last.env
echo "export CC_SEQUENCE=$CC_SEQUENCE" >> last.env
echo "export ORDERER_HOST=$ORDERER_HOST" >> last.env
echo "export ORDERER_PORT=$ORDERER_PORT" >> last.env
echo "export ORDERER_HOSTPORT=$ORDERER_HOSTPORT" >> last.env
echo "export ORDERER_TLS_CA_FILE=$ORDERER_TLS_CA_FILE" >> last.env

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

# before approves, try to get all orgs' mspid from channel config and generate private data connections json
# get channel config block
peer channel fetch config ${APP_CHANNEL_NAME}.block -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride ${ORDERER_HOST} -c ${APP_CHANNEL_NAME} --tls --cafile ${ORDERER_TLS_CA_FILE}

# decode to json
configtxlator proto_decode --input ${APP_CHANNEL_NAME}.block --type common.Block > ${APP_CHANNEL_NAME}.json

# get orgs mspid list
MSPIDS=$(jq -r '.data.data[0].payload.data.config.channel_group.groups.Application.groups | keys[]' ${APP_CHANNEL_NAME}.json)
echo $MSPIDS
if [[ "$MSPIDS" = "" ]]; then
    echo "get orgs mspid failed"
    exit 1
fi

# generate private data collections json
python ./generatePrivateCollections.py $MSPIDS
# private collections json filename comes from generatePrivateCollections.py
PRIVATE_COLLECTIONS_JSON="./private_collections.json"

peer lifecycle chaincode approveformyorg -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride ${ORDERER_HOST} --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --version ${CC_PKG_VER} --package-id ${CC_PKG_ID} --sequence ${CC_SEQUENCE} --tls --cafile ${ORDERER_TLS_CA_FILE} --collections-config $PRIVATE_COLLECTIONS_JSON

peer lifecycle chaincode checkcommitreadiness --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --version ${CC_PKG_VER} --sequence ${CC_SEQUENCE} --tls --cafile ${ORDERER_TLS_CA_FILE} --collections-config $PRIVATE_COLLECTIONS_JSON
