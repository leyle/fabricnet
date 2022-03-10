#!/bin/bash

. ./env.sh

./generateConnectionFile.sh

DEBUG=$1
if [ -z "$DEBUG" ]; then
  docker-compose -f explorer.yaml up -d
else
  docker-compose -f explorer.yaml up
fi
