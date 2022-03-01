#!/bin/bash

CIDS=$(docker container ls -a|grep -Ev "logspout|CONTAINER" | awk '{print $1}')
if [[ "$CIDS" = "" ]]; then
    echo "No container needs to be cleaned"
else
    docker rm -f $CIDS
fi

. ./global.env

sudo rm -rf $HOST_SHARED_VOLUME/*
sudo rm -rf $HOST_NODE_VOLUME/*
