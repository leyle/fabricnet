#!/usr/bin/env python
#-*-coding:utf-8-*-
# python3 only, do not support python2
import os
import argparse
import json
import yaml

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mspid', help=u'org msp id')
    parser.add_argument('--mspdir', help=u'org msp path')

    parser.add_argument('--peers', help=u'peer host ports, e.g peer0.org1.fabric.test:7051,peer1.org1.fabric.test:7051')

    parser.add_argument('--filepath', help=u'configtx.yaml file path')
    parser.add_argument('--addorgpath', help=u'add org file path')

    args = parser.parse_args()
    return args

def json_format(mspid, mspdir, peers):
    anchor_peers = []
    peers = peers.split(',')
    for peer in peers:
        host, port = peer.split(':')
        hp = {
            "Host": host,
            "Port": int(port)
        }
        anchor_peers.append(hp)

    one_tx = {
        "Name": mspid,
        "ID": mspid,
        "MSPDir": mspdir,
        "Policies": {
            "Readers": {
                "Type": "Signature",
                "Rule": f"OR('{mspid}.admin', '{mspid}.peer', '{mspid}.client')"
            },
            "Writers": {
                "Type": "Signature",
                "Rule": f"OR('{mspid}.admin', '{mspid}.peer', '{mspid}.client')"
            },
            "Admins": {
                "Type": "Signature",
                "Rule": f"OR('{mspid}.admin')"
            },
            "Endorsement": {
                "Type": "Signature",
                "Rule": f"OR('{mspid}.peer')"
            }
        },
        "AnchorPeers": anchor_peers,
    }

    return [one_tx]

def add_org_json_format(data):
    # format is: {Organizations: data}
    data[0]['MSPDir'] = "../msp"
    jdata = {
        "Organizations": data,
    }
    return jdata

def write_yaml_format(path, data):
    with open(path, 'w') as f:
        f.write(data)

def run():
    args = parse_args()

    mspid = args.mspid
    mspdir = args.mspdir
    peers = args.peers
    filepath = args.filepath

    data = json_format(mspid, mspdir, peers)
    write_yaml_format(filepath, yaml.dump(data))

    # write to add org add_org_configtx.yaml
    addorgpath = args.addorgpath
    add_data = add_org_json_format(data)
    write_yaml_format(addorgpath, yaml.dump(add_data))

if __name__ == "__main__":
    run()
