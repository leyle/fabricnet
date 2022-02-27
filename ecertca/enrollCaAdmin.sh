#!/bin/bash

# enroll ca server admin account, export msp to ../volume/admin

. ./env.sh

# set environment values for fabric-ca-client
# in order to be more clearly, we use absolute path
export FABRIC_CA_CLIENT_HOME=$HOST_VOLUME_CLIENT/ca/admin
export FABRIC_CA_CLIENT_MSP=$FABRIC_CA_CLIENT_HOME/msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=$HOST_VOLUME_SERVER/ca-cert.pem

# if exist admin's msp, delete it 
rm -rf $FABRIC_CA_CLIENT_HOME

fabric-ca-client enroll -d -u https://$FABRIC_ECERT_CA_ADMIN:$FABRIC_ECERT_CA_PASSWD@$ECERT_CA_HOST_PORT

# rename private key and certificate
mv $FABRIC_CA_CLIENT_MSP/cacerts/* $FABRIC_CA_CLIENT_MSP/cacerts/ca-cert.pem
mv $FABRIC_CA_CLIENT_MSP/keystore/*_sk $FABRIC_CA_CLIENT_MSP/keystore/key.pem
cp $BASE_PATH/ecertca/config/mspconfig.yaml $FABRIC_CA_CLIENT_MSP/config.yaml
