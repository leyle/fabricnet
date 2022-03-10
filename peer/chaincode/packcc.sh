#!/bin/bash

. ./chaincode.env

echo "Current chaincode name: $CC_NAME"


WORK_BASE=$PATH_BASE/chaincode

BUILDER_CC=$WORK_BASE/builder

TMP=$WORK_BASE/tmp
mkdir -p $TMP

cp -r $BUILDER_CC $TMP/builder
cd $TMP/builder

sed "s|\$CC_HOST|$CC_HOST_NAME|g; s|\$CC_PORT|$CC_PORT|g" ./connection_template.json > ./connection.json
sed "s|\$CC_NAME|$CC_NAME|g" ./metadata_template.json > ./metadata.json

CC_PKG_NAME=$CC_NAME.tgz

tar zcvf code.tar.gz connection.json
tar zcvf $CC_PKG_NAME metadata.json code.tar.gz

VM_PATH=$CC_HOST_BUILDER
DST_CC_PATH=$VM_PATH
mkdir -p $DST_CC_PATH
rm -rf $DST_CC_PATH/*

cd $WORK_BASE
cp -r $TMP/builder/* $DST_CC_PATH
rm -r $TMP
