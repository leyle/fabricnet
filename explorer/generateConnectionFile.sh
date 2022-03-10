#!/bin/bash

# get peer0 path

ORG_ENV_FILE=../../sharedvolume/env.org

. $ORG_ENV_FILE

PEER0=peer0.${ORG_NAME}.${TLD}
echo $PEER0

# check if peer0 path exists
PEER0_PATH=../$PEER0
if [ ! -d "$PEER0_PATH" ]; then
    echo "No peer0 path: $PEER0_PATH, can't generate explorer connection file"
    exit 1
fi

PEER0_ENV_FILE1=$PEER0_PATH/env.sh
PEER0_ENV_FILE2=$PEER0_PATH/peer.env

. $PEER0_ENV_FILE1
. $PEER0_ENV_FILE2

PEER_HOST=$PEER0

TLS_FILE=$PEER0_PATH/tls-msp/tlscacerts/tls-ca-cert.pem
cp $TLS_FILE ./

TEMP_FILE=./peer_conn_template.json
DST_FILE=./connection-profile/fabricapp.json

sed "s|\$PEER_HOST|$PEER_HOST|g; s|\$PEER_PORT|$PEER_PORT|g; s|\$ORG_MSPID|$ORG_MSPID|g; " $TEMP_FILE > $DST_FILE

