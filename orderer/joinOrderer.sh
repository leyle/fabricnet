#!/bin/bash

. ./env.sh

USER_CHANNEL_NAME=$1
if [ -z $USER_CHANNEL_NAME ]; then
    echo "using default channel name: $DEFAULT_CHANNEL_NAME, use: ./joinOrderer.sh CHANNEL_NAME to join new channel"
else
    DEFAULT_CHANNEL_NAME=$USER_CHANNEL_NAME
fi

END_IDX=$((PEER_NUM - 1)) 
for idx in $(seq 1 $END_IDX)
do
    ENV_FILE=$HOST_CHANNEL_VOLUME/orderer${idx}/env.orderer
    echo $ENV_FILE
    . $ENV_FILE
    
    ORDERER_ADMIN_HOSTPORT=$ORDERER_HOST:$ORDERER_OSN_PORT
    echo $ORDERER_ADMIN_HOSTPORT
    osnadmin channel join --channelID $DEFAULT_CHANNEL_NAME --config-block ${DEFAULT_CHANNEL_NAME}.tx -o $ORDERER_ADMIN_HOSTPORT 
    sleep 1
done

