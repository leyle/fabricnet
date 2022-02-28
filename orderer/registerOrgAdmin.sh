#!/bin/bash
. ./env.sh

. $ECERT_CA_ENV_FILE

HOST_VOLUME_BASE=$HOST_NODE_VOLUME
ADMIN_HOST_VOLUME=$HOST_VOLUME_BASE/users/$NODE_ADMIN_NAME

mkdir -p $ADMIN_HOST_VOLUME

# register user
# set ca admin msp info
export FABRIC_CA_CLIENT_HOME=$ECERT_FABRIC_CA_CLIENT_HOME
export FABRIC_CA_CLIENT_MSPDIR=$ECERT_FABRIC_CA_CLIENT_MSP
export FABRIC_CA_CLIENT_TLS_CERTFILES=$ECERT_ROOT_CERT
fabric-ca-client register -d --id.name $NODE_ADMIN_NAME --id.secret $NODE_ADMIN_PASSWD --id.type admin --id.attrs $NODE_ADMIN_ATTRS -u https://$ECERT_CA_HOST_PORT

# enroll admin user, set admin msp info
export FABRIC_CA_CLIENT_HOME=$ADMIN_HOST_VOLUME
export FABRIC_CA_CLIENT_MSPDIR=$FABRIC_CA_CLIENT_HOME/msp
export FABRIC_CA_CLIENT_TLS_CERTFILES=$ECERT_ROOT_CERT
fabric-ca-client enroll -d -u https://$NODE_ADMIN_NAME:$NODE_ADMIN_PASSWD@$ECERT_CA_HOST_PORT
mv $FABRIC_CA_CLIENT_MSPDIR/cacerts/* $FABRIC_CA_CLIENT_MSPDIR/cacerts/ca-cert.pem
mv $FABRIC_CA_CLIENT_MSPDIR/keystore/*_sk $FABRIC_CA_CLIENT_MSPDIR/keystore/key.pem
cp ./config/mspconfig.yaml $FABRIC_CA_CLIENT_MSPDIR/config.yaml

