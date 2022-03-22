#!/bin/bash

. ../env.sh

export PATH_BASE=${PWD}/../${HOST_VOLUME_CLIENT}
export BASE_FABRIC_CFG_PATH=${FABRIC_CLIENT_BIN_PATH}/config

export TLS_CA_FILE=${PATH_BASE}/peers/${PEER_NAME}/tls-msp/tlscacerts/tls-ca-cert.pem

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=$ORG_MSPID
export CORE_PEER_TLS_ROOTCERT_FILE=${PATH_BASE}/peers/${PEER_NAME}/tls-msp/tlscacerts/tls-ca-cert.pem
export CORE_PEER_MSPCONFIGPATH=${PATH_BASE}/users/${ORG_ADMIN_USER_NAME}/msp
export CORE_PEER_ADDRESS=${PEER_CONTAINER_NAME}:${PEER_PORT}

CHANNEL_NAME=$1
if [ -z "$CHANNEL_NAME" ]; then
    echo "No channel name"
    exit 1
fi

NEW_ORG_NAME=$2
if [ -z "$NEW_ORG_NAME" ]; then
    echo "No new Organization name"
    exit 1
fi

NEW_MSPID=$3
if [ -z "$NEW_MSPID" ]; then
    echo "No new msp id"
    exit 1
fi

NEW_PEER_HOST=$4
if [ -z "$NEW_PEER_HOST" ]; then
    echo "No new peer host"
    exit 1
fi

NEW_PEER_PORT=$5
if [ -z "$NEW_PEER_PORT" ]; then
    echo "No new peer port"
    exit 1
fi

# 1. generate new org config policy json file
echo "1. generate new org config policy json"
# check if tmp/orgX/configtx.yaml exist
TX_FILE=tmp/$NEW_ORG_NAME/configtx.yaml
if [ ! -f "$TX_FILE" ]; then
    echo "No $TX_FILE, user should copy the newtxconfig.yaml it to $TX_FILE, then modify it"
    exit 1
fi

# check if new org's msp exist
NEW_ORG_MSPDIR=$(awk '/MSPDir:/{print $NF}' $TX_FILE)
echo "NEW_ORG_MSPDIR"
if [ ! -d "$NEW_ORG_MSPDIR" ]; then
    echo "No $NEW_ORG_MSPDIR, please copy the new org's msp to $NEW_ORG_MSPDIR"
    exit 1
fi

cd tmp/$NEW_ORG_NAME
export FABRIC_CFG_PATH=$PWD
configtxgen -printOrg $NEW_MSPID > ${NEW_MSPID}_tmp.json

# append anchor peer config into new org's policy json
ANCHOR_VALUES='.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "PEERHOST","port": PEERPORT}]},"version": "0"}}'
ANCHOR_VALUES=${ANCHOR_VALUES/PEERHOST/$NEW_PEER_HOST}
ANCHOR_VALUES=${ANCHOR_VALUES/PEERPORT/$NEW_PEER_PORT}
jq "$ANCHOR_VALUES" ${NEW_MSPID}_tmp.json > ${NEW_MSPID}.json
rm ${NEW_MSPID}_tmp.json

cd ../../
export FABRIC_CFG_PATH=${FABRIC_CLIENT_BIN_PATH}/config


# 2. get newest channel config protobuf data
echo "2. fetch $CHANNEL_NAME config"
peer channel fetch config tmp/$NEW_ORG_NAME/config_block.pb -o ${ORDERER_HOSTPORT} -c ${CHANNEL_NAME} --tls --cafile $TLS_CA_FILE

# 3. decode pb to json
echo "3. decode channel config protobuf file to json file"
configtxlator proto_decode --input tmp/$NEW_ORG_NAME/config_block.pb --type common.Block | jq .data.data[0].payload.data.config > tmp/$NEW_ORG_NAME/config.json

# 4. add new org to channel config
echo "4. append new org channel config policy to the $CHANNEL_NAME config"
JQARG='.[0] * {"channel_group":{"groups":{"Application":{"groups": {"MSPID":.[1]}}}}}'
JQARG=${JQARG/MSPID/$NEW_MSPID}
jq -s "$JQARG" tmp/$NEW_ORG_NAME/config.json tmp/$NEW_ORG_NAME/${NEW_MSPID}.json > tmp/$NEW_ORG_NAME/modified_config.json

# 5. translate config.json to config.pb
echo "5. translate config.json to config.pb"
configtxlator proto_encode --input tmp/$NEW_ORG_NAME/config.json --type common.Config --output tmp/$NEW_ORG_NAME/config.pb

# 6. translate modified_config.json to modified_config.pb
echo "6. translate modified_config.json to modified_config.pb"
configtxlator proto_encode --input tmp/$NEW_ORG_NAME/modified_config.json --type common.Config --output tmp/$NEW_ORG_NAME/modified_config.pb

# 7. calculate the delta between these two config protobufs
echo "7. calculate the delta between these two config protobufs"
configtxlator compute_update --channel_id $CHANNEL_NAME --original tmp/$NEW_ORG_NAME/config.pb --updated tmp/$NEW_ORG_NAME/modified_config.pb --output tmp/$NEW_ORG_NAME/${NEW_MSPID}_update.pb

# 8. decode the delta protobuf to json format
echo "8. decode the delta protobuf to json format"
configtxlator proto_decode --input tmp/$NEW_ORG_NAME/${NEW_MSPID}_update.pb --type common.ConfigUpdate | jq . > tmp/$NEW_ORG_NAME/${NEW_MSPID}_update.json

# 9. envelop the delta data
echo "9. envelop the delta data"
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat tmp/$NEW_ORG_NAME/${NEW_MSPID}_update.json)'}}}' | jq . > tmp/$NEW_ORG_NAME/${NEW_MSPID}_update_in_envelope.json

# 10. re encode the enveloped delta data into protobuf type
echo "10. re encode the enveloped delta data into protobuf type"
mkdir -p /tmp/signdata/$NEW_ORG_NAME
configtxlator proto_encode --input tmp/$NEW_ORG_NAME/${NEW_MSPID}_update_in_envelope.json --type common.Envelope --output tmp/$NEW_ORG_NAME/${NEW_MSPID}_update_in_envelope.pb 
cp tmp/$NEW_ORG_NAME/${NEW_MSPID}_update_in_envelope.pb /tmp/signdata/$NEW_ORG_NAME

# write env to signdata/last.env
LAST_ENV=/tmp/signdata/$NEW_ORG_NAME/last.env
echo "export NEW_MSPID=$NEW_MSPID" > $LAST_ENV
echo "export CHANNEL_NAME=$CHANNEL_NAME" >> $LAST_ENV

echo "Channel config file update done, next step is sign this update file one by one."
