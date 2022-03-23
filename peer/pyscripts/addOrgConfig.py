#!/usr/bin/env python
#-*-coding:utf-8-*-
import json
import argparse
import sys

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--peers', help=u'peer host ports, e.g peer0.org1.fabric.test:7051,peer1.org1.fabric.test:7051')
    parser.add_argument('--rawjson', help=u'configtx.yaml generated json')
    parser.add_argument('--addorgpath', help=u'add org file path')
    parser.add_argument('--resultpath', help=u'result file path')

    args = parser.parse_args()
    return args

def generate_values(peers):
    anchor_peers = []
    peers = peers.split(',')
    for peer in peers:
        host, port = peer.split(':')
        hp = {
            "host": host,
            "port": int(port)
        }
        anchor_peers.append(hp)

    delta = {
        "mod_policy": "Admins",
        "value": {
            "anchor_peers": anchor_peers,
        },
        "version": 0,
    }
    return delta

def modify_json(raw_json, delta):
    with open(raw_json, 'r') as f:
        raw_data = f.read()

    data = json.loads(raw_data)
    data['values']['AnchorPeers'] = delta

    return data

def write_to_json_file(path, data):
    with open(path, 'w') as f:
        f.write(data)

def run():
    args = parse_args()
    raw_json = args.rawjson
    peers = args.peers
    result_path = args.resultpath

    if not any([raw_json, peers, result_path]):
        print("usage: ./addOrgConfig.py -h")
        sys.exit(1)

    delta = generate_values(peers)
    result = modify_json(raw_json, delta)
    write_to_json_file(result_path, json.dumps(result, indent=4))

if __name__ == "__main__":
    run()

