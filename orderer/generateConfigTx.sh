#!/bin/bash

. ./env.sh

WORKDIR=$HOST_CHANNEL_VOLUME

END_IDX=$((PEER_NUM - 1))
echo $END_IDX
NODES_PATH=""
for idx in $(seq 0 $END_IDX);
do
    PORT_BASE=$((idx * 10))
    CUR_ORDERER_PORT=$((ORDERER_PORT + PORT_BASE))
    CUR_ORDERER_OSN_PORT=$((ORDERER_OSN_PORT + PORT_BASE))

    PEER_IDX=orderer${idx}
    ORDERER_NAME=${PEER_IDX}.${ORG_NAME}.${TLD}
    echo $ORDERER_NAME
    ORDERER_ADDRESS=$ORDERER_NAME:$CUR_ORDERER_PORT
    
    HOST_VOLUME_BASE=$HOST_NODE_VOLUME
    ORDERER_HOST_VOLUME=$HOST_VOLUME_BASE/$ORDERER_NAME

    # copy tls file to channel path
    TLS_CERT_FILE=$ORDERER_HOST_VOLUME/tls-msp/signcerts/cert.pem
    DST=$WORKDIR/$PEER_IDX
    mkdir -p $DST
    cp $TLS_CERT_FILE $DST/cert.pem
    if [ -z $NODES_PATH ]; then
        NODES_PATH=$DST
    else
        NODES_PATH=${NODES_PATH},$DST
    fi

    # generate env.orderer file
    ENV_FILE=$DST/env.orderer
    echo "export HOST=$ORDERER_NAME" > $ENV_FILE
    echo "export ORDERER_HOST=$ORDERER_NAME" >> $ENV_FILE
    echo "export ORDERER_PORT=$CUR_ORDERER_PORT" >> $ENV_FILE
    echo "export ORDERER_OSN_PORT=$CUR_ORDERER_OSN_PORT" >> $ENV_FILE
    echo "export CLIENT_TLS_CERT=$DST/cert.pem" >> $ENV_FILE
    echo "export SERVER_TLS_CERT=$DST/cert.pem" >> $ENV_FILE

    chmod +x $ENV_FILE
done

# generate channel configtx.yaml template file
ORDERE_CONFIG_TX=$HOST_NODE_VOLUME/$ORG_NAME/configtx.yaml
RESULT_FILE=$HOST_CHANNEL_VOLUME/configtx_base.yaml

python ./pyscripts/createDefaultTX.py --base $CONFIGTX_BASE \
   --org $ORDERE_CONFIG_TX \
  --nodes $NODES_PATH \
 --filepath $RESULT_FILE 

# copy env.sh to channel path
cp ./env.sh $HOST_CHANNEL_VOLUME/env.sh
