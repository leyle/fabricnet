# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

ARG GO_VER=1.14.4
ARG ALPINE_VER=3.12

FROM golang:${GO_VER}-alpine${ALPINE_VER}

WORKDIR /ccsrc
COPY . .

RUN go get -d -v ./...
RUN go build -v

EXPOSE 9999
CMD ["./chaincode-external"]
