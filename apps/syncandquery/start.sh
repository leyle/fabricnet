#!/bin/bash

. ./envs.sh

if [ ! -f $FABRIC_CONNECTION_FILE ]; then
    echo "No fabric connection file, please make sure the connection file path: $FABRIC_CONNECTION_FILE"
    exit 1
fi

if [ ! -f $SYNC_AND_QUERY_CONFIG_FILE ]; then
    echo "No service config file, please make sure the service config file path: $SYNC_AND_QUERY_CONFIG_FILE"
    exit 1
fi

DEBUG=$1
if [ -z "$DEBUG" ]; then
    docker-compose -f docker-compose.yaml up -d
else
    docker-compose -f docker-compose.yaml up
fi
