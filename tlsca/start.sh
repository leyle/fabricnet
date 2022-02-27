#!/bin/bash

# import system wide env.sh
./init.sh

. ./env.sh

# work path check
WORKDIR=$HOST_VOLUME_WORKDIR
mkdir -p $WORKDIR
cp ./env.sh $WORKDIR

# start ca docker
sed "s|\$CA_CONTAINER_NAME|$CA_CONTAINER_NAME|g" ca_template.yaml > $WORKDIR/ca.yaml

docker-compose -f $WORKDIR/ca.yaml up -d

echo "Fabric CA Server started..."
echo "sleep 3s"
sleep 3 
sudo chown -R ${USER}:${GROUP} $HOST_VOLUME_BASE

# enroll ca admin
./enrollCaAdmin.sh

# share local env
./shareEnv.sh

echo "Start done."
