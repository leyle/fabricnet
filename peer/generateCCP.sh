#!/bin/bash

. ./env.sh
. $TLS_CA_ENV_FILE
. $ECERT_CA_ENV_FILE

NETWORK_NAME=$DOCKER_NETWORK_NAME
END_IDX=$((PEER_NUM - 1))
echo $END_IDX

USER_PASSWD=$NODE_ADMIN_NAME:$NODE_ADMIN_PASSWD

for idx in $(seq 0 $END_IDX);
do
    PORT_BASE=$((idx * 10))
    CUR_PEER_PORT1=$((PEER_PORT + PORT_BASE))
    CUR_PEER_PORT2=$((PEER_PORT2 + PORT_BASE))
    CUR_PEER_PORT3=$((PEER_PORT3 + PORT_BASE))

    PEER_IDX=peer${idx}
    PEER_NAME=${PEER_IDX}.${ORG_NAME}.${TLD}
    PEER_HOST_PORT=$PEER_NAME:$CUR_PEER_PORT1
    echo $PEER_NAME
    
    HOST_VOLUME_BASE=$HOST_NODE_VOLUME
    PEER_HOST_VOLUME=$HOST_VOLUME_BASE/$PEER_NAME
    PEER_RCA_CERT=$PEER_HOST_VOLUME/msp/cacerts/ca-cert.pem
    PEER_TLS_CERT=$PEER_HOST_VOLUME/tls-msp/tlscacerts/tls-ca-cert.pem

    echo $PEER_HOST_VOLUME

    python ./pyscripts/generateConnectionFile.py --project $NETWORK_NAME \
        --orgname $ORG_NAME \
        --mspid $ORG_MSPID \
        --peer $PEER_HOST_PORT \
        --peertlscert $PEER_TLS_CERT \
        --rca $ECERT_CA_HOST_PORT \
        --rcacert $PEER_RCA_CERT \
        --tlsca $TLS_CA_HOST_PORT \
        --tlscacert $TLS_CA_ROOT_CERT \
        --userpasswd $USER_PASSWD \
        --filepath $PEER_HOST_VOLUME

done
