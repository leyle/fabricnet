#!/bin/bash

. ./chaincode.env

CC_PKG_NAME=$CC_NAME.tgz

CC_PATH=$CC_HOST_BUILDER
cd $CC_PATH

echo "install chaincode at ${CC_PATH}"
peer lifecycle chaincode install ${CC_PKG_NAME}
