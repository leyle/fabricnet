#!/bin/bash

CIDS=$(docker container ls -a|grep -Ev "logspout|CONTAINER" | awk '{print $1}')
if [[ "$CIDS" = "" ]]; then
    echo "No container needs to be cleaned"
else
    docker rm -f $CIDS
fi

. ./global.env

TMP_ENV_FILE=$HOST_SHARED_VOLUME/env.org
if [ -f "$TMP_ENV_FILE" ]; then
    mv $TMP_ENV_FILE /tmp/env.org
fi

sudo rm -rf $HOST_SHARED_VOLUME/*
sudo rm -rf $HOST_NODE_VOLUME/*

if [ -f "/tmp/env.org" ]; then
    mv /tmp/env.org $TMP_ENV_FILE
fi
