#!/bin/bash

. ./chaincode.env

echo "Current chaincode name: $CC_NAME"

WORK_BASE=$PATH_BASE/chaincode
BUILDER_CC=$WORK_BASE/builder

VM_PATH=$CC_HOST_BUILDER
DST_CC_PATH=$VM_PATH
mkdir -p $DST_CC_PATH
rm -rf $DST_CC_PATH/*

CC_BUILDER_PATH=$HOST_NODE_VOLUME/ccbuild
CC_FILE=$CC_BUILDER_PATH/connection.json
if [ -f $CC_FILE ]; then
    echo "chaincode has been built already, just copy to current peer"
    cp -r $CC_BUILDER_PATH/* $DST_CC_PATH
    echo "copy done"
    exit 0
fi

# no build cc files, try to build it
mkdir -p $CC_BUILDER_PATH

cp -r $BUILDER_CC/* $CC_BUILDER_PATH
cd $CC_BUILDER_PATH

sed "s|\$CC_HOST|$CC_LB_HOST_NAME|g; s|\$CC_PORT|$CC_LB_PORT|g" ./connection_template.json > ./connection.json
sed "s|\$CC_NAME|$CC_NAME|g" ./metadata_template.json > ./metadata.json

CC_PKG_NAME=$CC_NAME.tgz

tar zcvf code.tar.gz connection.json
tar zcvf $CC_PKG_NAME metadata.json code.tar.gz

cp -r $CC_BUILDER_PATH/* $DST_CC_PATH
