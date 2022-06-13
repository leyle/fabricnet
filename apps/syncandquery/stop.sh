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

docker-compose -f docker-compose.yaml down -v
