#!/bin/bash

BASE_PATH=$PWD 

NODE_TYPE=$1
if [ -z "$NODE_TYPE" ]; then
    echo "usage: ./.debug_startall.sh orderer"
    echo "usage: ./.debug_startall.sh peer"
    exit 1
fi

NODE_PATH=$BASE_PATH/$NODE_TYPE
if [ ! -d "$NODE_PATH" ]; then
    echo "wrong node type, valid node types are: orderer / peer"
    exit 1
fi

CUR_ORG_NAME=$2
if [ -z "$CUR_ORG_NAME" ]; then
    echo "No org name"
    exit 1
fi

CUR_NODE_NUM=$3
if [ -z "$CUR_NODE_NUM" ]; then
    echo "No node number"
    echo "NODE NUM: $CUR_NODE_NUM"
    exit 1
fi

echo "org name:[$CUR_ORG_NAME], node type:[$NODE_TYPE], node num:[$CUR_NODE_NUM]"

# prepare env.org
ENV_ORG=$BASE_PATH/sharedvolume/env.org
sed "s|=org1|=$CUR_ORG_NAME|g;" ./env.org.sample > $ENV_ORG

# start tlsca
TLSCA_PATH=$BASE_PATH/tlsca
cd $TLSCA_PATH
./start.sh

# start ecert ca
ECERTCA_PATH=$BASE_PATH/ecertca
cd $ECERTCA_PATH
./start.sh

# start node path
cd $NODE_PATH

echo "export PEER_NUM=$CUR_NODE_NUM" >> user.env
echo "export ORG_NAME=$CUR_ORG_NAME" >> user.env
./start.sh

# start nodes
. $ENV_ORG

END_IDX=$((CUR_NODE_NUM -1))
for idx in $(seq 0 $END_IDX);
do
    peer_dir=${NODE_TYPE}${idx}.${ORG_NAME}.${TLD}
    node_path=$BASE_PATH/nodevolume/$peer_dir
    echo "start node: $node_path"
    cd $node_path
    ./start.sh
done

echo "done"


