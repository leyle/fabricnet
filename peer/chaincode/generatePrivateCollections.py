#!/usr/bin/env python
#-*-coding:utf-8-*-
import sys
import json

def no_share_collection(mspid: str):
    mspid_lower = mspid.lower()
    data = {
        "name": f"{mspid_lower}noshare",
        "policy": f"OR('{mspid}.member')",
        "requiredPeerCount": 0,
        "maxPeerCount": 1,
        "blockToLive": 0,
        "memberOnlyRead": True,
        "memberOnlyWrite": True,
    }

    return data

def share_write_collection(mspid):
    mspid_lower = mspid.lower()
    data = no_share_collection(mspid)
    data['name'] = f"{mspid_lower}sharewrite"
    data['memberOnlyWrite'] = False
    return data

def read_from_json(file_path):
    with open(file_path, 'r') as f:
        data = f.read()

    jdata = json.loads(data)
    return jdata

def write_to_json(file_path, data):
    json_data = json.dumps(data, indent=4)
    with open(file_path, 'w') as f:
        f.write(json_data)

def generate_connections_json(mspids, file_path):
    datas = []
    for mspid in mspids[:]:
        no_share = no_share_collection(mspid)
        share_write = share_write_collection(mspid)
        datas.append(no_share)
        datas.append(share_write)

    write_to_json(file_path, datas)

if __name__ == "__main__":
    if len(sys.argv) <= 2:
        print("invalid argument, usage: python generateConnectionsJson.py mspidA mspidB ...")
        sys.exit(1)

    mspids = sys.argv[1:]
    print(mspids)
    file_path = "./private_collections.json"
    generate_connections_json(mspids, file_path)
