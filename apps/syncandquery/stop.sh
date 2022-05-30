#!/bin/bash

. ./versions

export TIMEZONE=Asia/Shanghai

# mongodb info
export MONGODB_VERSION=$VERSION_MONGODB
export MONGODB_PORT=27017
export MONGODB_CONTAINER_NAME=mongodb-syncandquery-$MONGODB_PORT
export MONGODB_ROOT_USER=rootuser
export MONGODB_ROOT_PASSWD=rootpasswd
export MONGODB_APP_DATABASE=dev

# sync and query service info
export SYNC_AND_QUERY_IMAGE_VERSION=$VERSION_SYNC_AND_QUERY
export SYNC_AND_QUERY_PORT=3001
export SYNC_AND_QUERY_CONTAINER_NAME=syncandquery-$SYNC_AND_QUERY_PORT
export SYNC_AND_QUERY_CONFIG_FILE=./apiconfig.yaml
export SYNC_AND_QUERY_LOG=./logs/event_server.log

export FABRIC_CONNECTION_FILE=./connection.yaml
export FABRIC_WALLET=./wallet


if [ ! -f $FABRIC_CONNECTION_FILE ]; then
    echo "No fabric connection file, please make sure the connection file path: $FABRIC_CONNECTION_FILE"
    exit 1
fi

if [ ! -f $SYNC_AND_QUERY_CONFIG_FILE ]; then
    echo "No service config file, please make sure the service config file path: $SYNC_AND_QUERY_CONFIG_FILE"
    exit 1
fi

docker-compose -f docker-compose.yaml down -v
