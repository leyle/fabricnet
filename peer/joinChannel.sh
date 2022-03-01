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

ORDERER_TLS_CA_FILE=$2
if [ ! -f "$ORDERER_TLS_CA_FILE" ]; then
    echo "No orderer tls ca file"
    exit 1
fi

ORDERER_HOST=$3
if [ -z "$ORDERER_HOST"]; then
    echo "No orderer host"
    exit 1
fi

ORDERER_PORT=$4
if [ -z "$ORDERER_PORT" ]; then
    echo "No orderer port"
    exit 1
fi

PATH_BASE=${PWD}

export FABRIC_CFG_PATH=$PWD
export CORE_PEER_LOCALMSPID=$ORG_MSPID
export CORE_PEER_ADDRESS=${PEER_CONTAINER_NAME}:${PEER_PORT}
ADMIN_PATH=$HOST_NODE_VOLUME/users/$NODE_ADMIN_NAME/msp
export CORE_PEER_MSPCONFIGPATH=$ADMIN_PATH

# tls 
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=${PATH_BASE}/tls-msp/signcerts/cert.pem
export CORE_PEER_TLS_KEY_FILE=${PATH_BASE}/tls-msp/keystore/key.pem
export CORE_PEER_TLS_ROOTCERT_FILE=${PATH_BASE}/tls-msp/tlscacerts/tls-ca-cert.pem

# orderer info
export TLS_CA_FILE=$ORDERER_TLS_CA_FILE
ORDERER_HOSTPORT=$ORDERER_HOST:$ORDERER_PORT

# peer channel join -b $CHANNEL_BLOCK
peer channel fetch 0 ${CHANNEL_NAME}.block -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride $ORDERER_HOST -c $CHANNEL_NAME --tls --cafile $TLS_CA_FILE
peer channel join -b ${CHANNEL_NAME}.block

# 
sleep 5
echo $ORG_NAME
echo $PEER_CONTAINER_NAME:$PEER_PORT
peer channel list
