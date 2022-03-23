#!/bin/bash

set -e 

. ./env.sh
. ./peer.env

# join new org to channel
NEW_ORG_CONFIG_JSON=$1
if [ ! -f "$NEW_ORG_CONFIG_JSON" ]; then
    echo "No new org's config json"
    exit 1
fi

# read new org mspid from config json
NEW_MSPID=$(basename $NEW_ORG_CONFIG_JSON .json)
echo "MSPID: $NEW_MSPID"

JOIN_CHANNEL_NAME=$2
if [ -z "$JOIN_CHANNEL_NAME" ]; then
    echo "No channel name"
    exit 1
fi

ORDERER_HOST=$3
if [ -z "$ORDERER_HOST" ]; then
    echo "No orderer host"
    exit 1
fi

ORDERER_PORT=$4
if [ -z "$ORDERER_PORT" ]; then
    echo "No orderer port"
    exit 1
fi

# --cafile Path to file containing PEM-encoded trusted certificate(s) for the ordering endpoint 
ORDERER_TLS_CA_FILE=$5
if [ ! -f "$ORDERER_TLS_CA_FILE" ]; then
    echo "No orderer tls ca file"
    exit 1
fi

# orderer info
ORDERER_HOSTPORT=$ORDERER_HOST:$ORDERER_PORT

WORK_DIR_BASE=$PWD
ADD_ORG_DIR=$PWD/addorgtmp
rm -rf $ADD_ORG_DIR
mkdir -p $ADD_ORG_DIR

# set peer base info
export FABRIC_CFG_PATH=$WORK_DIR_BASE
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=$ORG_MSPID
export CORE_PEER_TLS_ROOTCERT_FILE=${WORK_DIR_BASE}/tls-msp/tlscacerts/tls-ca-cert.pem
export CORE_PEER_ADDRESS=${PEER_CONTAINER_NAME}:${PEER_PORT}

export TLS_CA_FILE=${WORK_DIR_BASE}/tls-msp/tlscacerts/tls-ca-cert.pem
ADMIN_PATH=$HOST_NODE_VOLUME/users/$NODE_ADMIN_NAME/msp
export CORE_PEER_MSPCONFIGPATH=$ADMIN_PATH

# fetch channel config from fabric network
echo "2. fetch $JOIN_CHANNEL_NAME config"
peer channel fetch config $ADD_ORG_DIR/raw_config.block -o ${ORDERER_HOSTPORT} -c ${JOIN_CHANNEL_NAME} --tls --cafile $ORDERER_TLS_CA_FILE

# decode protobuf to json
echo "3. decode channel config protobuf file to json file"
configtxlator proto_decode --input $ADD_ORG_DIR/raw_config.block --type common.Block | jq .data.data[0].payload.data.config > $ADD_ORG_DIR/raw_config.json

# merge new org config into channel config
echo "4. append new org channel config policy to the $JOIN_CHANNEL_NAME config"
JQARG='.[0] * {"channel_group":{"groups":{"Application":{"groups": {"MSPID":.[1]}}}}}'
JQARG=${JQARG/MSPID/$NEW_MSPID}
jq -s "$JQARG" $ADD_ORG_DIR/raw_config.json $NEW_ORG_CONFIG_JSON > $ADD_ORG_DIR/modified_config.json

# translate config.json to config.block
echo "5. translate raw_config.json to config.block"
configtxlator proto_encode --input $ADD_ORG_DIR/raw_config.json --type common.Config --output $ADD_ORG_DIR/config.block

# translate modified_config.json to modified_config.pb
echo "6. translate modified_config.json to modified_config.pb"
configtxlator proto_encode --input $ADD_ORG_DIR/modified_config.json --type common.Config --output $ADD_ORG_DIR/modified_config.block

# calculate the delta between these two config protobufs
echo "7. calculate the delta between these two config protobufs"
configtxlator compute_update --channel_id $JOIN_CHANNEL_NAME --original $ADD_ORG_DIR/config.block --updated $ADD_ORG_DIR/modified_config.block --output $ADD_ORG_DIR/update.block

# decode the delta protobuf to json format
echo "8. decode the delta protobuf to json format"
configtxlator proto_decode --input $ADD_ORG_DIR/update.block --type common.ConfigUpdate | jq . > $ADD_ORG_DIR/update.json

# envelop the delta data
echo "9. envelop the delta data"
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$JOIN_CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat $ADD_ORG_DIR/update.json)'}}}' | jq . > $ADD_ORG_DIR/update_envelope.json

# re encode the enveloped delta data into protobuf type
echo "10. re encode the enveloped delta data into protobuf type"
configtxlator proto_encode --input $ADD_ORG_DIR/update_envelope.json --type common.Envelope --output $ADD_ORG_DIR/update_envelope.block

# sign this update channel config
echo "11. siging the updated channel config"
peer channel signconfigtx -f $ADD_ORG_DIR/update_envelope.block

# update channel
echo "12. update channel config, sends updated data to orderer"
peer channel update -f $ADD_ORG_DIR/update_envelope.block -c $JOIN_CHANNEL_NAME -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride $ORDERER_HOST --tls --cafile $ORDERER_TLS_CA_FILE
