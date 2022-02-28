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
    
    HOST_VOLUME_BASE=$HOST_NODE_VOLUME
    PEER_HOST_VOLUME=$HOST_VOLUME_BASE/$PEER_NAME

    mkdir -p $PEER_HOST_VOLUME

    # register/enroll peer to tls ca
    # set tls ca admin msp info
    export FABRIC_CA_CLIENT_HOME=$TLS_FABRIC_CA_CLIENT_HOME
    export FABRIC_CA_CLIENT_MSPDIR=$TLS_FABRIC_CA_CLIENT_MSP
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$TLS_CA_ROOT_CERT
    fabric-ca-client register -d --id.name $PEER_NAME --id.secret $PEER_PASSWD --id.type orderer -u https://${TLS_CA_HOST_PORT}

    # enroll peer tls, set peer msp info
    export FABRIC_CA_CLIENT_HOME=$PEER_HOST_VOLUME
    export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CA_CLIENT_HOME/tls-msp
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$TLS_CA_ROOT_CERT
    fabric-ca-client enroll -d -u https://$PEER_NAME:$PEER_PASSWD@$TLS_CA_HOST_PORT --enrollment.profile tls --csr.hosts localhost --csr.hosts $PEER_NAME
    mv $FABRIC_CA_CLIENT_MSPDIR/keystore/*_sk $FABRIC_CA_CLIENT_MSPDIR/keystore/key.pem
    mv $FABRIC_CA_CLIENT_MSPDIR/tlscacerts/*.pem $FABRIC_CA_CLIENT_MSPDIR/tlscacerts/tls-ca-cert.pem

    # register peer to ecert ca
    # set ecert ca admin msp info
    export FABRIC_CA_CLIENT_HOME=$ECERT_FABRIC_CA_CLIENT_HOME
    export FABRIC_CA_CLIENT_MSPDIR=$ECERT_FABRIC_CA_CLIENT_MSP
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$ECERT_ROOT_CERT
    fabric-ca-client register -d --id.name $PEER_NAME --id.secret $PEER_PASSWD --id.type orderer -u https://${ECERT_CA_HOST_PORT}

    # enroll peer ecert credentials, set peer msp info
    export FABRIC_CA_CLIENT_HOME=$PEER_HOST_VOLUME
    export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CA_CLIENT_HOME/msp
    export FABRIC_CA_CLIENT_TLS_CERTFILES=$ECERT_ROOT_CERT
    fabric-ca-client enroll -d -u https://$PEER_NAME:$PEER_PASSWD@$ECERT_CA_HOST_PORT
    mv $FABRIC_CA_CLIENT_MSPDIR/cacerts/* $FABRIC_CA_CLIENT_MSPDIR/cacerts/ca-cert.pem
    mv $FABRIC_CA_CLIENT_MSPDIR/keystore/*_sk $FABRIC_CA_CLIENT_MSPDIR/keystore/key.pem
    cp ./config/mspconfig.yaml $FABRIC_CA_CLIENT_MSPDIR/config.yaml
done
