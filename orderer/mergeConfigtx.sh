#!/bin/bash

ORGS=$*

BASE_FILE=./configtx_base.yaml
DST_FILE=./configtx.yaml

for name in ${ORGS[@]}
do
    echo $name
    python mergeConfigtx.py --base $BASE_FILE --peer $name/configtx.yaml --filepath $BASE_FILE
done

cp $BASE_FILE $DST_FILE
