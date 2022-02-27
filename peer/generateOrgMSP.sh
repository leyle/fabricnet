#!/bin/bash

. ./env.sh

. $TLS_CA_ENV_FILE
. $ECERT_CA_ENV_FILE

ORG_BASE=$HOST_NODE_VOLUME

ORG_MSP_DIR=$ORG_BASE/$ORG_NAME/msp
mkdir -p ${ORG_MSP_DIR}/{cacerts,tlscacerts,users}

# tls ca cert
cp $TLS_CA_ROOT_CERT ${ORG_MSP_DIR}/tlscacerts/tls-ca-cert.pem

# ecert cert
cp $ECERT_ROOT_CERT ${ORG_MSP_DIR}/cacerts/ca-cert.pem

# node OU config
cp ./config/mspconfig.yaml $ORG_MSP_DIR/config.yaml

