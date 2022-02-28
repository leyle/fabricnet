#!/bin/bash

. ./env.sh

# check if configtx.yaml file exists
BASE_PATH=$HOST_CHANNEL_VOLUME
TX_FILE=$BASE_PATH/configtx.yaml
echo $TX_FILE

if [ ! -f "$TX_FILE" ]; then
    echo "No $TX_FILE, please create it first"
    exit 1
fi

USER_CHANNEL_NAME=$1
if [ ! -z $USER_CHANNEL_NAME ]; then
    DEFAULT_CHANNEL_NAME=$USER_CHANNEL_NAME
fi

WORKDIR=$BASE_PATH
cd $WORKDIR
export FABRIC_CFG_PATH=$WORKDIR

# 1. generate app channel block
configtxgen -profile $DEFAULT_CHANNEL_PROFILE -outputBlock ${DEFAULT_CHANNEL_NAME}.tx -channelID $DEFAULT_CHANNEL_NAME

# 2. join orderer into the channel
export ORDERER_ADMIN_HOSTPORT=orderer0.${ORG_NAME}.${TLD}:${ORDERER_OSN_PORT}
osnadmin channel join --channelID $DEFAULT_CHANNEL_NAME --config-block ${DEFAULT_CHANNEL_NAME}.tx -o $ORDERER_ADMIN_HOSTPORT 
