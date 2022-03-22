#!/bin/bash

. ./env.sh

END_IDX=$((PEER_NUM - 1))
echo $END_IDX

PEERS=""

for idx in $(seq 0 $END_IDX);
do
    PEER_IDX=peer${idx}
    PEER_NAME=${PEER_IDX}.${ORG_NAME}.${TLD}
    echo $PEER_NAME
    PORT_BASE=$((idx * 10))
    CUR_PEER_PORT1=$((PEER_PORT + PORT_BASE))
    PEER_HOST_PORT=$PEER_NAME:$CUR_PEER_PORT1
    if [ -z "$PEERS" ]; then
        PEERS=$PEER_HOST_PORT
    else
        PEERS=$PEERS,$PEER_HOST_PORT
    fi
done

ORG_BASE=$HOST_NODE_VOLUME/$ORG_NAME
ORG_MSP=$ORG_NAME/msp
ORG_ADD_WORKDIR=$ORG_BASE/addorg
mkdir -p $ORG_ADD_WORKDIR
python ./pyscripts/generateConfigTX.py --mspid $ORG_MSPID --mspdir $ORG_MSP --peers $PEERS --filepath $ORG_BASE/configtx.yaml --addorgpath $ORG_ADD_WORKDIR/configtx.yaml

# generate add org json data
export FABRIC_CFG_PATH=$ORG_ADD_WORKDIR
RAW_JSON=$ORG_ADD_WORKDIR/base.json
RESULT_JSON=$ORG_ADD_WORKDIR/${ORG_MSPID}.json
configtxgen -printOrg $ORG_MSPID > $RAW_JSON

python ./pyscripts/addOrgConfig.py --peers $PEERS --rawjson $RAW_JSON --resultpath $RESULT_JSON

rm $RAW_JSON
