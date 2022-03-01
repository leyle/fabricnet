#!/bin/bash

. ./env.sh
. $TLS_CA_ENV_FILE
. $ECERT_CA_ENV_FILE

END_IDX=$((PEER_NUM - 1))
echo $END_IDX

for idx in $(seq 0 $END_IDX);
do
    PEER_BASE=$((idx * 10))
    CUR_PEER_PORT1=$((PEER_PORT + PEER_BASE))
    CUR_PEER_PORT2=$((PEER_PORT2 + PEER_BASE))
    CUR_PEER_PORT3=$((PEER_PORT3 + PEER_BASE))

    PEER_IDX=peer${idx}
    PEER_NAME=${PEER_IDX}.${ORG_NAME}.${TLD}
    echo $PEER_NAME
    PEER_CONTAINER_NAME=$PEER_NAME
    
    HOST_VOLUME_BASE=$HOST_NODE_VOLUME
    PEER_HOST_VOLUME=$HOST_VOLUME_BASE/$PEER_NAME
    PEER_CORE_FILE=$PEER_HOST_VOLUME/core.yaml
    CC_HOST_BUILDER=$PEER_HOST_VOLUME/chaincode

    PEER_DOCKER_COMPOSE_FILE=$PEER_HOST_VOLUME/peer-compose.yaml

    cp ./config/core.yaml $PEER_CORE_FILE

    # genereate peer docker compose file
    sed "s|\$PEER_CONTAINER_NAME|$PEER_CONTAINER_NAME|g; " ./peer_template.yaml > $PEER_DOCKER_COMPOSE_FILE

    # generate peer env file
    PEER_ENV_FILE=$PEER_HOST_VOLUME/peer.env
    echo "export PEER_HOST_VOLUME=$PEER_HOST_VOLUME" >> $PEER_ENV_FILE 
    echo "export PEER_CORE_FILE=$PEER_CORE_FILE" >> $PEER_ENV_FILE
    echo "export CC_HOST_BUILDER=$CC_HOST_BUILDER" >> $PEER_ENV_FILE
    echo "export PEER_CONTAINER_NAME=$PEER_CONTAINER_NAME" >> $PEER_ENV_FILE
    echo "export PEER_PORT=$CUR_PEER_PORT1" >> $PEER_ENV_FILE
    echo "export PEER_PORT2=$CUR_PEER_PORT2" >> $PEER_ENV_FILE
    echo "export PEER_PORT3=$CUR_PEER_PORT3" >> $PEER_ENV_FILE

    # copy env.sh to peer's folder
    cp ./env.sh $PEER_HOST_VOLUME/env.sh

    # copy start.sh to peer's folder
    cp ./peerStart.sh $PEER_HOST_VOLUME/start.sh

    chmod +x $PEER_HOST_VOLUME/env.sh
    chmod +x $PEER_HOST_VOLUME/peer.env
    chmod +x $PEER_HOST_VOLUME/start.sh

    chmod 775 -R $PEER_HOST_VOLUME
done
