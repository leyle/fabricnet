# fabric explorer usage

## build explorer docker image

- git clone https://github.com/hyperledger/blockchain-explorer.git /tmp/blockchain-explorer
- cd /tmp/blockchain-explorer
- npm install
- cd client
- npm install
- npm run build
- git clone https://github.com/leyle/fabricapp.git /tmp/fabricapp
- cp -r /tmp/fabricapp/explorer/dockerbuild/* /tmp/blockchain-explorer/
- cd /tmp/blockchain-explorer/
- (optional) if you're in China, set some proxy tricks
- (optional) export http_proxy=http://someip:port
- (optional) export https_proxy=http://someip:port
- ./build_docker_image.sh
- docker tag hyperledger/explorer-db:latest leyle123456/explorer-db:v1.1.8 # v1.1.8 is current explorer version
- docker tag hyperledger/explorer:latest leyle123456/explorer-web:v1.1.8
- (optional) push images to docker hub

---
## start/run fabric explorer
**notice: these scripts have some default values**
- explorer web default user/password: exploreradmin / exploreradminpw
- explorer web default listen port: 8080 (you can change it in explorer.yaml)
- default channel: emalidev
- default org: org1
- default org msp: org1MSP
- default peer name: peer0.org1.emali.dev
- default peer address: peer0.org1.emali.dev:6013

if anything is different from above in you environment, please modify it in `connection-profile/fabricapp.json`

```shell
cd $SOMEPATH/fabricapp/explorer

# prepare tls credential file and admin user's credential files
cp -r crypto_template crypto
# copy tls ca cert file
cp $SOMEPATH/tls-ca-cert.pem crypto/tls/tls-ca-cert.pem

# cp admin user's public and private credential files
rm -r crypto/users/admin/*
cp -r $SOMEPATH/signcerts crypto/users/admin/signcerts
cp -r $SOMEPATH/keystore crypto/users/admin/keystore

# start in foreground
./start.sh debug

# start in background
./start.sh

# stop
./stop.sh

```