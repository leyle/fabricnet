#!/bin/bash

# this script run in cli container

. ./chaincode.env

. ./last.env

echo "HOST: $CC_HOST_NAME"
echo "PORT: $CC_PORT"
echo $CC_HOST_NAME:$CC_PORT

echo "query installed chaincode ------------->"
peer lifecycle chaincode queryinstalled

echo "query approved chaincode -------------->"
PEER_LIST=" --peerAddresses $PEER_CONTAINER_NAME:$PEER_PORT --tlsRootCertFiles $TLS_CA_FILE"
peer lifecycle chaincode queryapproved --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --tls --cafile ${TLS_CA_FILE} $PEER_LIST


echo "query committed chaincodes, name: $CC_NAME, ----------------->"
peer lifecycle chaincode querycommitted --channelID ${APP_CHANNEL_NAME} --name ${CC_NAME} --tls --cafile ${TLS_CA_FILE}
