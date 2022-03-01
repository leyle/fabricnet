#!/bin/bash

# this script executed in cli docker container

. ./env.sh
. ./peer.env

# check channel.tx file exist

NEW_CHANNEL_NAME=$1
if [ -z "$NEW_CHANNEL_NAME" ]; then
    echo "No channel name"
    exit 1
fi
CHANNEL_NAME=$NEW_CHANNEL_NAME

PATH_BASE=${PWD}

export FABRIC_CFG_PATH=$PWD
export CORE_PEER_LOCALMSPID=$ORG_MSPID
export CORE_PEER_ADDRESS=${PEER_CONTAINER_NAME}:${PEER_PORT}
ADMIN_PATH=$HOST_NODE_VOLUME/users/$NODE_ADMIN_NAME/msp
export CORE_PEER_MSPCONFIGPATH=$ADMIN_PATH
# export CORE_PEER_MSPCONFIGPATH=${PATH_BASE}/users/${ORG_ADMIN_USER_NAME}/msp
# tls 
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=${PATH_BASE}/tls-msp/signcerts/cert.pem
export CORE_PEER_TLS_KEY_FILE=${PATH_BASE}/tls-msp/keystore/key.pem
export CORE_PEER_TLS_ROOTCERT_FILE=${PATH_BASE}/tls-msp/tlscacerts/tls-ca-cert.pem
export TLS_CA_FILE=$CORE_PEER_TLS_ROOTCERT_FILE

# peer channel join -b $CHANNEL_BLOCK
ORDERER_HOSTPORT=orderer0.org0.emali.dev:6006
ORDERER_HOST=orderer0.org0.emali.dev
peer channel fetch 0 ${CHANNEL_NAME}.block -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride $ORDERER_HOST -c $CHANNEL_NAME --tls --cafile $TLS_CA_FILE
peer channel join -b ${CHANNEL_NAME}.block
# 
sleep 6
echo $ORG_NAME
echo $PEER_CONTAINER_NAME:$PEER_PORT
peer channel list
