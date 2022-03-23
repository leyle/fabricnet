#!/bin/bash
set -e

. ./chaincode.env
. ./last.env

# update chaincode definition, only update sequence value
CC_SEQUENCE=$((CC_SEQUENCE + 1))
echo $CC_SEQUENCE

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

# when updates success, update CC_SEQUENCE value in last.env
# in order to be simple, just append it to the file
echo "export CC_SEQUENCE=$CC_SEQUENCE" >> last.env
