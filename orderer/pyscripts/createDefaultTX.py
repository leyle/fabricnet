#!/usr/bin/env python
#-*-coding:utf-8-*-
import os
import sys
import argparse
import yaml

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('--base', help=u'configtx template base file path')
    parser.add_argument('--org', help='org configtx.yaml file')
    parser.add_argument('--nodes', help='orderer node info folder, contains tls cert and env.orderer')

    parser.add_argument('--filepath', help='result file path')

    args = parser.parse_args()
    return args

def load_yaml(file):
    with open(file, 'r') as f:
        data = f.read()
    ydata = yaml.load(data, Loader=yaml.Loader)
    return ydata

def write_yaml(file_path, data):
    tyaml = yaml.dump(data)
    with open(file_path, 'w') as f:
        f.write(tyaml)

def add_orderer_org(full_data, org_data):
    # section -> Organizations:
    organizations = full_data['Organizations']
    if not organizations:
        full_data['Organizations'] = org_data
    else:
        full_data['Organizations'].append(org_data)

    # section -> Orderer.Organizations
    orderer_org = full_data['Orderer']['Organizations']
    print("orderer_org", orderer_org)
    if not orderer_org:
        full_data['Orderer']['Organizations'] = org_data
        full_data['Profiles']['DefaultProfile']['Orderer']['Organizations'] = org_data

def config_orderer_addrs(full_data, orderer_addrs):
    full_data['Orderer']['Addresses'] = orderer_addrs
    full_data['Profiles']['DefaultProfile']['Orderer']['Addresses'] = orderer_addrs

def config_orderer_consenters(full_data, consenters):
    full_data['Orderer']['EtcdRaft']['Consenters'] = consenters

def process_nodes_info(nodes):
    # nodes: node config path
    nodes = nodes.split(',')
    data = []
    for node in nodes:
        # env_file = f"{node}/env.orderer"
        env_file = os.path.join(node, 'env.orderer')
        node_data = _parse_env_file(env_file)
        data = _generate_consenter(data, node_data)

    return data

def _generate_consenter(data, node_info):
    info = {
        "Host": node_info['HOST'],
        "Port": int(node_info['ORDERER_PORT']),
        "ClientTLSCert": node_info['CLIENT_TLS_CERT'],
        "ServerTLSCert": node_info['SERVER_TLS_CERT'],
    }
    if not data:
        data = [info]
    else:
        data.append(info)

    return data

def _parse_env_file(file):
    print("file path", file)
    with open(file, 'r') as f:
        lines = f.readlines()
    lines = [line.strip() for line in lines]
    lines = [line.replace('export ', '') for line in lines]
    data = {}
    for line in lines:
        key, val = line.split('=')
        key = key.strip()
        val = val.strip()
        data[key] = val
    return data

def json_to_yaml(jdata):
    return yaml.dump(jdata)

def run():
    args = parse_args()
    base_file = args.base
    org_file = args.org
    nodes = args.nodes
    if not all([base_file, org_file, nodes]):
        print('python mergeConfigtx.py -h for more info')
        sys.exit(1)

    base_data = load_yaml(base_file)
    orderer_data = load_yaml(org_file)

    add_orderer_org(base_data, orderer_data)

    consenters = process_nodes_info(nodes)
    config_orderer_consenters(base_data, consenters)


    addrs = []
    for c in consenters:
        host = c.get('Host')
        port = c.get('Port')
        host_port = f"{host}:{port}"
        addrs.append(host_port)

    config_orderer_addrs(base_data, addrs)

    filepath = args.filepath

    write_yaml(filepath, base_data)

if __name__ == "__main__":
    run()
