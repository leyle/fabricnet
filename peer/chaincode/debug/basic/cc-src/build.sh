#!/bin/bash

echo "try to build external chaincode: asset-transfer-basic"

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "No version, usage: ./build.sh v1.0.0"
    exit 1
fi

docker build -t leyle123456/asset-transfer-basic:$VERSION .
