#!/bin/bash
set -e

./init.sh

. ./env.sh

# generate org msp
echo "generateOrgMSP.sh"
./generateOrgMSP.sh

# register org admin
./registerOrgAdmin.sh

# register peers
./registerPeers.sh

# generate client connection file
./generateCCP.sh

# generate org's configtx file
./generateOrgConfigTX.sh

# generate peer startup files
./generatePeerDockerFile.sh

# copy explorer
EXPLORER_SRC=$BASE_PATH/explorer
EXPLORER_DST=$HOST_NODE_VOLUME/explorer
rm -rf $EXPLORER_DST
cp -r $EXPLORER_SRC $EXPLORER_DST

echo "done"
