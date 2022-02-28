#!/bin/bash

. ./env.sh
. $TLS_CA_ENV_FILE
. $ECERT_CA_ENV_FILE

END_IDX=$((PEER_NUM - 1))
echo $END_IDX

for idx in $(seq 0 $END_IDX);
do
    PEER_IDX=orderer${idx}
    PEER_NAME=${PEER_IDX}.${ORG_NAME}.${TLD}
    echo $PEER_NAME
    PEER_CONTAINER_NAME=$PEER_NAME
    
    HOST_VOLUME_BASE=$HOST_NODE_VOLUME
    PEER_HOST_VOLUME=$HOST_VOLUME_BASE/$PEER_NAME
    PEER_DOCKER_COMPOSE_FILE=$PEER_HOST_VOLUME/orderer-compose.yaml

    # genereate peer docker compose file
    sed "s|\$PEER_CONTAINER_NAME|$PEER_CONTAINER_NAME|g; " ./orderer_template.yaml > $PEER_DOCKER_COMPOSE_FILE

    # generate peer env file
    PEER_ENV_FILE=$PEER_HOST_VOLUME/orderer.env
    echo "export PEER_HOST_VOLUME=$PEER_HOST_VOLUME" >> $PEER_ENV_FILE 
    echo "export PEER_CONTAINER_NAME=$PEER_CONTAINER_NAME" >> $PEER_ENV_FILE
    echo "export ORDERER_PORT=$ORDERER_PORT" >> $PEER_ENV_FILE
    echo "export ORDERER_OSN_PORT=$ORDERER_OSN_PORT" >> $PEER_ENV_FILE

    # copy env.sh to peer's folder
    cp ./env.sh $PEER_HOST_VOLUME/env.sh

    # copy start.sh to peer's folder
    cp ./ordererStart.sh $PEER_HOST_VOLUME/start.sh

    chmod +x $PEER_HOST_VOLUME/env.sh
    chmod +x $PEER_HOST_VOLUME/orderer.env
    chmod +x $PEER_HOST_VOLUME/start.sh

    chmod 777 -R $PEER_HOST_VOLUME
done
