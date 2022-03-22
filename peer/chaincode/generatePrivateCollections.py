#!/usr/bin/env python
#-*-coding:utf-8-*-
import sys
import json

def no_share_collection(org_name):
    data = {
        "name": f"{org_name}mspnoshare",
        "policy": f"OR('{org_name}MSP.member')",
        "requiredPeerCount": 0,
        "maxPeerCount": 1,
        "blockToLive": 0,
        "memberOnlyRead": True,
        "memberOnlyWrite": True,
    }

    return data

def share_write_collection(org_name):
    data = no_share_collection(org_name)
    data['name'] = f"{org_name}mspsharewrite"
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

def generate_connections_json(org_num, file_path):
    datas = []
    # generate data for operator node
    org_name = "operator"
    no_share = no_share_collection(org_name)
    share_write = share_write_collection(org_name)
    datas.append(no_share)
    datas.append(share_write)

    for num in range(2, org_num + 1):
        org_name = f"org{num}"
        no_share = no_share_collection(org_name)
        share_write = share_write_collection(org_name)
        datas.append(no_share)
        datas.append(share_write)

    write_to_json(file_path, datas)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("invalid argument, usage: python generateConnectionsJson.py ORG_NUM TARGET_FILE")
        sys.exit(1)

    org_num = sys.argv[1]
    file_path = sys.argv[2]
    generate_connections_json(int(org_num), file_path)
