#!/bin/bash

. ./env.sh
WORKBASE=$HOST_VOLUME_BASE
WORKDIR=$HOST_VOLUME_WORKDIR

docker-compose -f $WORKDIR/ca.yaml down -v

rm -rf $WORKBASE
