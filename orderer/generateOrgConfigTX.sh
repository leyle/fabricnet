#!/bin/bash

. ./env.sh

END_IDX=$((PEER_NUM - 1))
echo $END_IDX

PEERS=""

for idx in $(seq 0 $END_IDX);
do
    PEER_IDX=orderer${idx}
    PEER_NAME=${PEER_IDX}.${ORG_NAME}.${TLD}
    echo $PEER_NAME
    PEER_HOST_PORT=$PEER_NAME:$ORDERER_PORT
    if [ -z "$PEERS" ]; then
        PEERS=$PEER_HOST_PORT
    else
        PEERS=$PEERS,$PEER_HOST_PORT
    fi
done

ORG_BASE=$HOST_NODE_VOLUME/$ORG_NAME
ORG_MSP=$ORG_BASE/msp
python ./pyscripts/generateConfigTX.py --mspid $ORG_MSPID --mspdir $ORG_MSP --peers $PEERS --filepath $ORG_BASE/configtx.yaml
