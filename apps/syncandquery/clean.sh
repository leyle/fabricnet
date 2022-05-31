#!/bin/bash

. ./envs.sh

docker-compose -f docker-compose.yaml down -v

rm -f $FABRIC_CONNECTION_FILE
rm -f $FABRIC_WALLET/*

sudo rm -rf $MONGODB_DATA_HOST_PATH
sudo rm -f $SYNC_AND_QUERY_LOG
