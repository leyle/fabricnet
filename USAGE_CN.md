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

### 运行环境



---

### 依赖的基础软件及版本



----

### 本 fabricnet 使用的 fabric 相关程序版本



---

### 不满足需求可能产生的问题



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



---

### 启动 TLS CA



---

### 启动 enrollment CA



---

### 生成 orderer/peer nodes 配置

#### 生成 orderer nodes 配置



---

#### 生成 peer nodes 配置



---

### 启动 orderer/peer nodes

#### 启动 orderer nodes



---

#### 启动 peer nodes



---

### orderer 创建 channel



---

### 各个 peer 加入 channel



---

### 安装 chaincode



---

### chaincode smoke testing



---

## 脚本设计与实现细节



---

## 常见问题及解决方法



---

## 参考命令



---

## 其他

