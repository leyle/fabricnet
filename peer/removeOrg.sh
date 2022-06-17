#!/bin/bash

set -e 

. ./env.sh
. ./peer.env

# remove org
REMOVE_MSPID=$1
if [ -z "$REMOVE_MSPID" ]; then
    echo "No mspid"
    exit 1
fi
echo "MSPID: $MSPID"

TARGET_CHANNEL_NAME=$2
if [ -z "$TARGET_CHANNEL_NAME" ]; then
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
REMOVE_ORG_DIR=$PWD/delorgtmp
rm -rf $REMOVE_ORG_DIR
mkdir -p $REMOVE_ORG_DIR

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
echo "2. fetch $TARGET_CHANNEL_NAME config"
peer channel fetch config $REMOVE_ORG_DIR/raw_config.block -o ${ORDERER_HOSTPORT} -c ${TARGET_CHANNEL_NAME} --tls --cafile $ORDERER_TLS_CA_FILE

# decode protobuf to json
echo "3. decode channel config protobuf file to json file"
configtxlator proto_decode --input $REMOVE_ORG_DIR/raw_config.block --type common.Block | jq .data.data[0].payload.data.config > $REMOVE_ORG_DIR/raw_config.json

# remove org msp info
echo "4. delete $REMOVE_MSPID from channel($TARGET_CHANNEL_NAME) config"
JQARG='del(.channel_group.groups.Application.groups.MSPID)'
JQARG=${JQARG/MSPID/$REMOVE_MSPID}
echo $JQARG
jq "$JQARG" $REMOVE_ORG_DIR/raw_config.json > $REMOVE_ORG_DIR/modified_config.json

# translate config.json to config.block
echo "5. translate raw_config.json to config.block"
configtxlator proto_encode --input $REMOVE_ORG_DIR/raw_config.json --type common.Config --output $REMOVE_ORG_DIR/config.block

# translate modified_config.json to modified_config.pb
echo "6. translate modified_config.json to modified_config.pb"
configtxlator proto_encode --input $REMOVE_ORG_DIR/modified_config.json --type common.Config --output $REMOVE_ORG_DIR/modified_config.block

# calculate the delta between these two config protobufs
echo "7. calculate the delta between these two config protobufs"
configtxlator compute_update --channel_id $TARGET_CHANNEL_NAME --original $REMOVE_ORG_DIR/config.block --updated $REMOVE_ORG_DIR/modified_config.block --output $REMOVE_ORG_DIR/update.block

# decode the delta protobuf to json format
echo "8. decode the delta protobuf to json format"
configtxlator proto_decode --input $REMOVE_ORG_DIR/update.block --type common.ConfigUpdate | jq . > $REMOVE_ORG_DIR/update.json

# envelop the delta data
echo "9. envelop the delta data"
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$TARGET_CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat $REMOVE_ORG_DIR/update.json)'}}}' | jq . > $REMOVE_ORG_DIR/update_envelope.json

# re encode the enveloped delta data into protobuf type
echo "10. re encode the enveloped delta data into protobuf type"
configtxlator proto_encode --input $REMOVE_ORG_DIR/update_envelope.json --type common.Envelope --output $REMOVE_ORG_DIR/update_envelope.block

# sign this update channel config
echo "11. siging the updated channel config"
peer channel signconfigtx -f $REMOVE_ORG_DIR/update_envelope.block

# update channel
echo "12. update channel config, sends updated data to orderer"
peer channel update -f $REMOVE_ORG_DIR/update_envelope.block -c $TARGET_CHANNEL_NAME -o ${ORDERER_HOSTPORT} --ordererTLSHostnameOverride $ORDERER_HOST --tls --cafile $ORDERER_TLS_CA_FILE
