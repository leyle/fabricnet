#!/bin/bash

. ./env.sh
. ./orderer.env

docker-compose -f orderer-compose.yaml up -d

sudo chown -R ${USER}:${GROUP} ./
