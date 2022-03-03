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

echo "done"
