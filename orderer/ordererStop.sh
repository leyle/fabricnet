#!/bin/bash

. ./env.sh
. ./orderer.env

docker-compose -f orderer-compose.yaml down -v
