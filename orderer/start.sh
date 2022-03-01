#!/bin/bash

./init.sh

. ./env.sh

# generate org msp
./generateOrgMSP.sh

# register org admin
./registerOrgAdmin.sh

# register orderers
./registerOrderers.sh

# generate org's configtx file
./generateOrgConfigTX.sh

# generate orderer docker startup scripts
./generateOrdererDockerFile.sh

# generate channel configtx base file
./generateConfigTx.sh

# copy essential files to create channel
DST=$HOST_CHANNEL_VOLUME
mkdir -p $DST
cp ./createGenesisChannelBlock.sh $DST/createGenesisChannelBlock.sh
cp ./joinOrderer.sh $DST/joinOrderer.sh
cp ./pyscripts/mergeConfigtx.py $DST/mergeConfigtx.py
