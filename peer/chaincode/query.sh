#!/bin/bash

# this script run in cli container

. ./chaincode.env

echo "HOST: $CC_HOST"
echo "PORT: $CC_PORT"
echo $CC_HOST:$CC_PORT

peer lifecycle chaincode queryinstalled
