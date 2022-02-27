#!/bin/bash

. ./env.sh
. ./peer.env

docker-compose -f peer-compose.yaml up -d

sudo chown -R ${USER}:${GROUP} ./
