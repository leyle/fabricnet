#!/bin/bash

. ./env.sh
. ./peer.env

docker-compose -f peer-compose.yaml down -v
