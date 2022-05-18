# fabric 网络多机分布式部署使用文档

[TOC]

本文档的大纲如下

- 前言
- 系统需求与各软件版本等信息
- 启动步骤
- 脚本设计与实现细节
- 常见问题及解决方法
- 参考命令
- 其他



---

## 前言

本脚本主要解决的是快速将 fabric 部署到多个服务器上，每一个 organization 包含多个 peer/orderer node，这些 peer/orderer node 也可以部署到不同的服务器上。

本套脚本的主要文件/目录结构如下所示，下文将对各个文件/目录做相关解释说明。

```shell
├── bin/
├── clean.sh
├── debug_startall.sh
├── dns/
├── ecertca/
├── env.org.sample
├── explorer/
├── global.env
├── monitordocker.sh
├── nodevolume/
├── orderer/
├── peer/
├── README.md
├── samples/
├── sharedvolume/
└── tlsca/
```

- bin/ 此目录主要存放 fabric 相关的二进制程序
- clean.sh 此脚本清理掉当前 docker 中的所有运行中的 container，非常危险的脚本，慎重执行，且仅做 dev/debug/test 使用
- debug_startall.sh 此脚本是为了 dev/debug 时快速启动环境使用
- dns/ 此为 dnsmasq 的启动脚本目录
- ecertca/ 此为启动 enrollement ca 的脚本的目录
- env.org.sample 此文件为整个 organization 的基本信息配置，比如 top level domain name，org name etc
- explorer/ 此为 blockchain explorer 的启动脚本目录
- global.env 全局环境变量
- monitordocker.sh 查看 docker container stdout/stderr 日志
- nodevolume/ 此目录存放的是运行中的 peer/orderer node 的信息
- orderer/ 此为启动 orderer 的目录
- peer/ 此为启动 peer 的目录
- samples/ 此为本系统可能产生的配置等的示例文件
- sharedvolume/ 此为 ca 等共享信息存放的目录
- tlsca/ 此为提供 TLS 通信的 ca 启动目录



---

## 系统需求与各软件版本等信息

### 运行环境及相关软件版本

- OS: linux .eg ubuntu 20.04/22.04

- docker version: 20.10.2 or greater

- docker-compose version: 1.27.4 or greater

- bash shell: 5.0 or greater

- fabric

  - client version: 2.3.3
  - ca version: 1.5.2

- couchdb: 3.1.1

- python: 3.7+

- golang: 1.17+

  

----

### 本 fabricnet 使用的 fabric 相关程序版本

本脚本基于 fabric 的 `2.3.3` 进行构建的。

其中 `fabric-ca`使用的版本是 `1.5.2`

需要使用到的部分 binary 程序，放在 `$PROJECT/bin/2.3.3/` 目录下



---

### 不满足需求可能产生的问题

如果 docker 或者 docker-compose 版本过低，可能导致无法正常启动 container，或者不支持当前版本的 compose yaml 文件。

如果 python 版本过低，无法生成恰当的 fabric 相关的配置文件，比如 fabric collection json/yaml 文件等。

所以，在执行前，先检查依赖的程序版本是否符合需求，否则可能会产生一些错误情况。



---

## 网络启动步骤

### 步骤概览

启动步骤大概如下所述:

1. 启动 TLS CA
2. 启动 enrollment ca
3. 生成 orderer/peer nodes 配置
4. 启动 orderer/peer nodes
5. orderer 创建 channel
6. 各个 peer 加入 channel
7. 安装 chaincode
8. chaincode smoke testing

下面具体描述各个步骤。

```shell
# 为了描述方便，我们采用了一个环境变量来控制整个项目的 base path 值，
# 这个 base path 值的默认值是 ~/github/fabricnet
# 这个值写在 ~/github/fabricnet/global.env 文件中
# 定义为 export BASE_PATH=~/github/fabricnet
# 所以，如果您的脚本存放路径不是这个，需要修改这个值为合适的值，否则脚本执行可能出错。
# 一般建议，创建一个这样的目录来存放相关脚本，减少错误的可能性。
# 后文中描述相关路径/目录时，以 $BASE 用来代替这里的 $BASE_PATH 值
# 比如，要进入 peer 目录，即 cd $BASE/peer

# 同时，我们有一个 operator 机器，这个机器的目的是在一个地方生成所有的网络配置，同时进行一些后续的操作。
# 比如后续的创建 channel 的操作，基本上就是在 operator 机器上即可。
```



---

### 域名配置与网络规划

在实际生成/启动 fabric 网络之前，需要先规划好 fabric 各个组件/节点的网络/域名信息。

在我们的设计中，一个机构的域名包含至少两部分内容

1. Top Level Domain， 即 TLD 值；
2. organization name， 即区分此机构的子域名；

然后在此两个值之下的子域名，即为各个 node 的域名。

例子：

假设 TLD 值是 `emali.io`，organization name 是 `dev`。那么其 node 的节点默认值是

```shell
# tls ca 域名
tlsca.dev.emali.dev

# enrollemnt ca 域名是
ecert.dev.emali.dev

# peer 节点的域名是
# 根据 peer 的数量，从 peer0、peer1 依次类推
peer0.dev.emali.dev
peer1.dev.emali.dev
peer2.dev.emali.dev

# 每一个 peer 都会有一个对应的 couchdb，其名字命名逻辑与对应 peer 一致
couchdb0.dev.emali.dev
couchdb1.dev.emali.dev
couchdb2.dev.emali.dev

# orderer node 的命名一致，比如
orderer0.dev.emali.dev
orderer1.dev.emali.dev
orderer2.dev.emali.dev
```

以上例子的这些值，分为两个地方配置

- 全局配置，全局配置文件是 `$BASE/sharedvolume/env.org`，此 env.org 文件从 `$BASE/env.org.sample`文件复制而来，复制后，修改其中的对应的值即可。
- node 中的定义配置，在 $BASE/{peer,tlsca/ecertca/orderer} 下， 都可以创建一个 `user.env` 文件，写入需要覆盖的 env 变量即可。

当此步骤配置好后，确保域名与 ip 的映射关系，如果是 debug 使用的自定义本地域名，可以通过启动 `$BASE/dns`中的 `dnsmasq` 来提供域名解析。



#### （必做的设置）带 operator 的 fabric 网络

为了简化我们的 fabric 网络的部分操作，我们在 channel 的相关 policy 中，配置了 `operator` 这一名字的角色。

这就要求我们的必须设置一个机构，其机构名为 `operator`，其 mspid 值为 `operatorMSP`。

那么相关的域名、node 等信息配置，也是需要做好配置的。

如果不做此配置，那么后续的 chaincode commit 操作、新的机构的 join 操作等，一定会失败。

如果不喜欢 `operator`这个名字，可以在 configtx.yaml 文件中进行修改，后续的 orderer 中有关于生成 configtx.yaml 的描述。



---

### 启动 TLS CA

```shell
# tls ca 及 enrollment ca 两个 ca 的 ca 程序一致，只是他们负责的功能不同。具体配置有细微差别
# 默认的 tls ca 的 admin 账户密码定义在 $BASE/global.env 文件中
# export FABRIC_TLS_CA_ADMIN=tlscaadmin
# export FABRIC_TLS_CA_PASSWD=capasswd
# 如果要修改此值，在 $BASE/tlsca/user.env 文件中添加上述内容，并修改其值即可
# 假设已配置好正确的网络域名

cd $BASE/tlsca
./start.sh

# 上面执行成功后，生成的文件存放在 $BASE/sharedvolume/ 目录下
# 包含一个 env 文件 env.tlsca 及 tlsca/ 目录
```





---

### 启动 enrollment CA

```shell
# 与启动 tls ca 操作一致
# 其中 ecert ca 的 admin 账户密码定义在 $BASE/global.env 文件中
# export FABRIC_ECERT_CA_ADMIN=ecertadmin
# export FABRIC_ECERT_CA_PASSWD=capasswd
# 如果要修改此值，在 $BASE/tlsca/user.env 文件中添加上述内容，并修改其值即可

cd $BASE/ecertca
./start.sh

# 上面执行成功后，生成的文件存放在 $BASE/sharedvolume/ 目录下
# 包含一个 env 文件 env.ecert 及 ecertca/ 目录
```



---

### 生成 orderer/peer nodes 配置及多机部署启动

#### 生成 orderer nodes 配置及多机部署步骤

在本版本的脚本中，为了方便的将 node 部署到多个地方，采用了先生成启动脚本及配置，后进行启动的操作。

所以，当我们执行相关操作后，实际是在执行机器上生成了启动 node 所需的所有文件，然后将这些文件发送到各个机器上，再在各个机器上进行启动，这样简化了多机部署的复杂度。

```shell
# 关于相关端口、地址等信息的配置，默认由两个环境变量控制
# $BASE/global.env
# $BASE/orderer/local.env

# 默认情况下，生成 5 个 orderer node 配置
# 这个值定义在 $BASE/orderer/local.env 中的 export PEER_NUM=5
# 如果需要修改这个值，创建 $BASE/orderer/user.env 并写入合适的值，比如 export PEER_NUM=3
# 默认情况下，直接执行
cd $BASE/orderer
./start.sh

# 执行成功后，生成的目录/文件保存在 $BASE/nodevolume 中
# 包含有
# 1. 以 organization name 为目录名的 org msp 信息目录
# 以 dev 这个 name 为例，会生成一个目录叫做
$BASE/nodevolume/dev/
# 这个目录中包含如下内容
├── configtx.yaml
└── msp
    ├── cacerts
    │   └── ca-cert.pem
    ├── config.yaml
    ├── tlscacerts
    │   └── tls-ca-cert.pem
    └── users

# 2. 生成各个 orderer node 的配置/脚本目录，这个用于各自的启动使用
# 比如
$BASE/nodevolume/orderer0.dev.emali.dev/
$BASE/nodevolume/orderer1.dev.emali.dev/
$BASE/nodevolume/orderer2.dev.emali.dev/
$BASE/nodevolume/orderer3.dev.emali.dev/
$BASE/nodevolume/orderer4.dev.emali.dev/

# 3. 在执行机器上启动 node 节点
# 这里需要注意，当我们复制这些启动脚本到一个新的机器上时，也要保证路径是一致的，否则脚本找不到相关文件会导致启动失败
# 当发送脚本到一个新的机器上时，需要复制如下内容

# 3.1 ca 信息，包含三个文件
$BASE/sharedvolume/env.ecert
$BASE/sharedvolume/env.tlsca
$BASE/sharedvolume/env.org

# 3.2 本 org 信息，比如 organization name 是 dev 时
$BASE/nodevolume/dev/ 

# 3.3 要启动的 node 信息，比如要发送 orderer1 到新的机器
$BASE/nodevolume/orderer1.dev.emali.dev/

# 当上述文件准备好后，即可进入 node 目录进行启动操作，比如
cd $BASE/nodevolume/orderer1.dev.emali.dev/
./start.sh

```



---

#### 生成 peer nodes 配置及多机部署步骤

```shell
# 生成及启动 peer nodes 与 orderer nodes 基本一致
# 都是先生成配置、然后按需分发配置、启动 node
# 主要的区别是执行目录不同

# 关于相关端口、地址等信息的配置，默认由两个环境变量控制
# $BASE/global.env
# $BASE/peer/local.env

# 默认情况下，生成 3 个 peer nodes 配置
# 这个值定义在 $BASE/peer/local.env 中的 export PEER_NUM=3
# 如果需要修改这个值，创建 $BASE/peer/user.env 并写入合适的值，比如 export PEER_NUM=1
# 默认情况下，直接执行
cd $BASE/peer
./start.sh

# 执行成功后，生成的目录/文件保存在 $BASE/nodevolume 中
# 包含有
# 1. 以 organization name 为目录名的 org msp 信息目录
# 以 dev 这个 name 为例，会生成一个目录叫做
$BASE/nodevolume/dev/
# 这个目录中包含如下内容
├── configtx.yaml
└── msp
    ├── cacerts
    │   └── ca-cert.pem
    ├── config.yaml
    ├── tlscacerts
    │   └── tls-ca-cert.pem
    └── users

# 2. 生成各个 orderer node 的配置/脚本目录，这个用于各自的启动使用
# 比如
$BASE/nodevolume/peer0.dev.emali.dev/
$BASE/nodevolume/peer1.dev.emali.dev/
$BASE/nodevolume/peer2.dev.emali.dev/

# 3. 在执行机器上启动 node 节点
# 这里需要注意，当我们复制这些启动脚本到一个新的机器上时，也要保证路径是一致的，否则脚本找不到相关文件会导致启动失败
# 当发送脚本到一个新的机器上时，需要复制如下内容

# 3.1 ca 信息，包含三个文件
$BASE/sharedvolume/env.ecert
$BASE/sharedvolume/env.tlsca
$BASE/sharedvolume/env.org

# 3.2 本 org 信息，比如 organization name 是 dev 时
$BASE/nodevolume/dev/ 

# 3.3 要启动的 node 信息，比如要发送 orderer1 到新的机器
$BASE/nodevolume/peer1.dev.emali.dev/

# 当上述文件准备好后，即可进入 node 目录进行启动操作，比如
cd $BASE/nodevolume/peer1.dev.emali.dev/
./start.sh

```



---

### orderer 创建 channel

```shell
# 1. 收集参与机构的 msp 信息
# 创建 channel 需要收集各个参与机构的 msp 信息
# 各个机构的 msp 信息默认保存在 $BASE/nodevolume/$ORG_NAME 里
# 所以，需要先把各个机构的这个 msp 目录发送给 orderer 的操作节点，
# 存放在 $BASE/nodevolume/channel/ 目录下
# 存放时，一般不要重命名相关 org 的目录名字
# 当收集好了 org 的 msp 信息后

# 2. 生成 channel configuration 文件，即 configtx.yaml
cd $BASE/nodevolume/channel
./mergeConfigtx.sh $NAME1 $NAME2 ...

# 上面的 $NAME1 $NAME2 ... 指的是本目录下存在地各个 org msp 的目录名
# 假设参与机构有 dev  abcbank icbc，那么此处的目录应该存在 dev/ abcbank/ icbc/
# 传参就是 (参数顺序无所谓)
./mergeConfigtx.sh dev abcbank icbc

# 3. 创建 genesis block
./createGenesisChannelBlock.sh
# 默认创建的 channel name 是 fabricapp
# 如果要创建其他名字的 channel，在脚本后增加一个 channel name 参数即可，比如 emalidev
./createGenesisChannelBlock.sh emalidev

# 4. 各个 orderer node 加入 channel 中
./joinOrderer.sh

# 如果使用了非默认的 channel name，那么需要在这里添加一个自定义的 channel name 参数，比如 emalidev
./joinOrderer.sh emalidev

# 5. 分发 orderer TLSCA 证书给各个 peer
# 为了各个 peer 能够 join channel 及后续的一些操作，需要 peer 收到 orderer 提供的 TLSCA 证书
# 此证书存放于 $BASE/nodevolume/$ORG_NAME/msp/tlscacerts/tls-ca-cert.pem
# 复制分发给各个 peer 即可
```



---

### 各个 peer 加入 channel

```shell
# 当上一步的 orderer 构建好了 channel 后，各个 peer 节点都可以 join 到网络中
# 各个 peer 想要 join 到指定的 channel，需要有一些前置信息的收集
# 1. orderer 提供的 TLSCA 证书
# 2. 任意一个 orderer 节点的地址及对应的端口
# 3. 要加入的 channel 的 name

# 进入各个 peer 的工作目录，比如
cd $BASE/nodevolume/peer0.dev.emali.dev/

# joinChannel.sh 支持的参数依次是 CHANNEL_NAME TLS_CA ORDERER_ADDR ORDERER_PORT
# 这个参数是有顺序的，不要搞错了

./joinChannel.sh fabricapp /tmp/tls-ca-cert.pem orderer0.org0.emali.dev 6006
```



---

### 安装 chaincode

```shell
# chaincode 的安装需要注意三点
# 1. 同一个机构中，chaincode 的打包(package)只需要做一次，否则会导致 chaincode 不是同一个 chaincode
# 2. 同一个机构中，每一个 peer 都需要进行 chaincode 的 install 操作
# 3. 同一个机构中，仅需其中一个 peer 进行 chaincode 的 approve 操作

# 工作目录是各个 peer 的工作目录之下，
# 比如 $BASE/nodevolume/peer0.dev.emali.dev/chaincode
# 1. 执行 package 操作
./packcc.sh

# 执行成功后，会在 $BASE/nodevolume/ccbuild/ 目录下存放相关信息
# 所以，如果多个 peer 不在同一个机器上，那么需要复制此目录到对应的机器上的对应位置上去

# 2. install chaincode
# 需要在同一个机构的各个 peer 上执行
./install.sh

# 3. approve chaincode
# 此步骤仅续在一个机器上执行即可
# approve.sh 需要的参数依次是 channel_name sequence orderer_host orderer_port orderer_tls_ca
# 下面是一个例子
./approve.sh fabricapp 1 orderer0.org0.emali.dev 6006 /tmp/tls-ca-cert.pem

# 4. 启动 external chaincode service
# 需要注意，必须在 operator 进行 commit chaincode definition 之前，进行 chaincode 的启动
# chaincode 的启动，需要在每一个 peer 上都进行
# 同时需要注意，可能同一个 org 的多个 peer 之间，没有进行 approve 操作的 peer 会缺少一个 last.env 的环境变脸，这个值可以从已有的 peer 的 chaincode 工作目录下复制过来
./start_cc.sh

# 5. 启动 external chaincode service 的 nginx proxy
# 进入目录 $BASE/nodevolume/ccproxy
./start.sh 

# 6. commit chaincode
# 当所有的机构的所有的 peer 都进行相关的 install/approve 操作后，operator 节点可以进行 commit chaincode 操作
./commit.sh


```



---

### chaincode smoke testing

// TODO



---

### 启动 blockchain explorer

```shell
# 进入到 $BASE/nodevolume/explorer
# 默认情况下，执行 ./start.sh 即可

# 默认情况下的配置的 channel name 是 fabricapp
# 如果默认的 channel name 不是此值，那么需要修改
# 首先执行 ./generateConnectionFile.sh 生成下面这个配置
# $BASE/nodevolume/explorer/connection-profile/faricapp.json

# 后面再修改上面的文件，修改 channels 项下面的 key 名字为 fabricapp 名字为具体的 channel name

# 然后再执行 
. ./env.explorer
docker-compose -f explorer.yaml up -d

```



---

## 新增一个 org 到已有网络中

**主要步骤**

新增一个 org 到已有网络中，主要包含如下四步骤：

1. 规划此 org 的网络及节点布局，启动 ca/peer 等程序，生成相关证书配置等文件；
2. 提交此 org 的相关证书及 configtx.yaml 等文件给已有网络的 operator；
3. 已有网络的 operator 将此 org 的相关信息添加到相关 channel 配置中，并分发 tlsca、orderer address、channel name 等信息给申请者；
4. 申请者拿到了相关信息后，加入指定 channel，安装 chaincode，同步数据，参与 transaction 等；



**交互文件及信息**

将角色分为管理网络的 operator 及申请加入网络的 applicant。

`applicant 需要提交给 operator 的文件及信息清单`

- configtx.yaml 文件
- org config json 文件（包含了各种证书及 peer 连接信息）

`operator 需要提交给 applicant 的文件及信息清单`

- orderer tls ca 证书
- orderer host port 连接地址
- channel name
- chaincode name
- 当前网络中正在运行的 chaincode 的 sequence



下面分别描述各个步骤

###  1. 规划新 org 的网络布局及相关节点启动，生成配置

```shell
# 见上一节 网络启动步骤 中的前面几步，至加入网络之前的步骤。
# 需要注意的是，需要确保本机构的 peer 节点、tlsca、ca 等节点的域名可以被其他网络节点访问到
```



---

### 2. 提交此 org 的相关证书及 configtx.yaml 文件给已有网络的 operator

```shell
# 在上一步的操作成功后，会产生一个关于本机构的增量配置
# 其位置为
$BASE/nodevolume/$ORG_NAME/addorg

# 将这整个目录发送给 operator

# 建议，以被 org 的 name 作为目录名，其内包含 addorg 目录
# 比如本 org name 为 org3，那么创建一个 org3 的目录后，内部再存放 addorg/ 目录
# 目的是让 operator 更好地识别谁是谁。
```



---

### 3. operator 操作更新网络 channel 配置，将新的 org 加入到网络中

```shell
# operator 收到了上一步的增量配置文件后，进入自己的 peer 节点配置中，进行相关的配置操作
# 此处假设在 peer0 节点上操作

# 假设收到的新 org 的配置信息存放在 /tmp/org3

# peer 的路径是
$BASE/nodevolume/peer0.operator.emali.dev/

# 进入此 peer 内部后，执行如下命令
# ./addNewOrg.sh $ORG_CONFIG_JSON $CHANNEL_NAME $ORDERER_HOST $ORDERER_PORT $ORDERER_TLS_CA
./addNewOrg.sh /tmp/org3/addorg/org3MSP.json fabricapp orderer0.org0.emali.dev 6006 /tmp/tls-ca-cert.pem

# 执行成功的结果大概如下所示（见下一个代码块）
# 当其执行成功后，新的 org 可以在自己的 peer 上进行 join channel 等操作

```

update channel configuration 成功，加入新的 org 配置的大概提示例子

```shell
axel@org1:~/github/fabricnet/nodevolume/peer0.operator.emali.dev$ ./addNewOrg.sh /tmp/org3/addorg/org3MSP.json fabricapp orderer0.org0.emali.dev 6006 /tmp/tls-ca-cert.pem 
MSPID: org3MSP
2. fetch fabricapp config
2022-05-12 07:42:54.803 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2022-05-12 07:42:54.805 UTC [cli.common] readBlock -> INFO 002 Received block: 14
2022-05-12 07:42:54.805 UTC [channelCmd] fetch -> INFO 003 Retrieving last config block: 0
2022-05-12 07:42:54.807 UTC [cli.common] readBlock -> INFO 004 Received block: 0
3. decode channel config protobuf file to json file
4. append new org channel config policy to the fabricapp config
5. translate raw_config.json to config.block
6. translate modified_config.json to modified_config.pb
7. calculate the delta between these two config protobufs
8. decode the delta protobuf to json format
9. envelop the delta data
10. re encode the enveloped delta data into protobuf type
11. siging the updated channel config
2022-05-12 07:42:54.983 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
12. update channel config, sends updated data to orderer
2022-05-12 07:42:55.008 UTC [channelCmd] InitCmdFactory -> INFO 001 Endorser and orderer connections initialized
2022-05-12 07:42:55.022 UTC [channelCmd] update -> INFO 002 Successfully submitted channel update
```



---

### 4. 新的 org 在自己的 peer 上操作 join channel/install chaincode 等操作

join channel

```shell
# 在执行 join channel 操作之前，需要从 operator 那里收到如下信息

# 1. orderer tls ca 证书
# 2. orderer host port 值

# 假设 orderer tls ca 证书已收到，放在本地 /tmp/tls-ca-cert.pem
# 假设 orderer host port 值为 orderer0.org0.emali.dev 6006

# 进入本 org 的各个 peer 节点，执行相关 join channel 的操作
# 注意，有几个 peer 节点，需要在每一个 peer 节点都执行 join channel 的操作
# 此处仅展示一个节点的操作
# 此处的 join channel 与上一节 网络启动步骤 中的 “各个 peer 加入 channel“操作一致
# 比如进入如下目录
$BASE/nodevolume/peer0.org3.emali.dev
# 执行类似于如下命令
# joinChannel.sh 支持的参数依次是 CHANNEL_NAME TLS_CA ORDERER_ADDR ORDERER_PORT
./joinChannel.sh fabricapp /tmp/tls-ca-cert.pem orderer0.org0.emali.dev 6006
```

install/approve chaincode

```shell
# 当我们进行 chaincode 的 approve 时，需要知道 chaincode name、 sequence 值，此值是从 operator 处得来的。
# 需要注意的是，因为加入了新的 org，所以 private data 的 collections.json 的定义变了（添加了新的 org 的 collection names）
# 所以，需要 update 整个网络所有的 org 的 chaincode 的 sequence 值。

# 这是一个复杂的操作，不要每一个参与 org 都要进行 approve 操作，最后由 operator 进行 commit 操作

# 1. 在新的 org 上进行 pack、install、approve 操作
# pack 及 install 不再赘述，仅说明 approve 操作
# approve 时，需要在当前 chaincode sequence 值的基础上 +1，比如当前是 1，那么此时需要输入 2
# 比如
./approve.sh fabricapp 2 orderer0.org0.emali.dev 6006 /tmp/tls-ca-cert.pem

# 当在新的 org 进行了 approve 操作后，需要立刻进行 chaincode 的 start 操作，同时起动器来 chaincode 的 nginx 服务，否则可能会出现，operator commit 了此定义，而其他机构进行交易时，数据发送到了此新的 org，而此 org 的 chaincode server 并没有启动，整个 transaction 处理失败。

# 1.1 启动 chaincode service 及 chaincode service 的 nginx proxy
# 见上面的 “网络启动步骤” 的 安装 chaincode 小节

# 2. 在各个旧有的 org 上执行 approve 新的 sequence 的操作
# 需要在每一个 org 进行此操作，包括 operator
./approve.sh fabricapp 2 orderer0.org0.emali.dev 6006 /tmp/tls-ca-cert.pem

# 3. 在 operator 上，进行 commit 此新的 chaincode definition 操作
./commit.sh

```







## 脚本设计与实现细节



---

## 常见问题及解决方法



---

## 参考命令

```shell
alias dockerps='docker ps -a --format "table {{.Names}}\t{{.Ports}}\t{{.Networks}}\t{{.Status}}"'

alias dockerinto='function _dockerinto(){ docker exec -it $1 sh; };_dockerinto'

alias opensslinfo='function _opensslinfo(){ openssl x509 -in $1 -noout -subject -issuer -dates; };_opensslinfo'

```



---

## 其他

