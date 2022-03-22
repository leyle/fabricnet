#!/bin/bash

. ./chaincode.env

. ./last.env

PEER_LIST=" --peerAddresses $PEER_CONTAINER_NAME:$PEER_PORT --tlsRootCertFiles $TLS_CA_FILE"
echo $PEER_LIST

# private collections json filename comes from generatePrivateCollections.py
PRIVATE_COLLECTIONS_JSON="./private_collections.json"

peer lifecycle chaincode commit -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride ${ORDERER_HOST} --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --version ${CC_PKG_VER} --sequence ${CC_SEQUENCE} --tls --cafile ${ORDERER_TLS_CA_FILE} $PEER_LIST --collections-config $PRIVATE_COLLECTIONS_JSON

peer lifecycle chaincode querycommitted --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --tls --cafile ${ORDERER_TLS_CA_FILE}
