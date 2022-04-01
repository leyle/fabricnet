#!/bin/bash
. ./env.sh

export NGINX_CONF=$HOST_NODE_VOLUME/ccproxy/nginx.conf

docker-compose -f nginx_compose.yaml up -d
