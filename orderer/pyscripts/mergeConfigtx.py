#!/usr/bin/env python
#-*-coding:utf-8-*-
import sys
import argparse
import yaml

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--base', help=u'configtx template base file path')
    parser.add_argument('--peer', help=u'peers configtx.yaml file path')
    parser.add_argument('--filepath', help=u'result configtx.yaml file path')

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


def append_org(full_data, org_data):
    full_data['Organizations'].append(org_data[0])
    app_orgs = full_data['Profiles']['DefaultProfile']['Application']['Organizations']
    if not app_orgs:
        full_data['Profiles']['DefaultProfile']['Application']['Organizations'] = org_data
    else:
        full_data['Profiles']['DefaultProfile']['Application']['Organizations'].append(org_data[0])

def run():
    args = parse_args()
    base_file = args.base
    peer_file = args.peer
    filepath = args.filepath
    if not all([base_file, peer_file, filepath]):
        print('python mergeConfigtx.py -h for more info')
        sys.exit(1)

    base_data = load_yaml(base_file)
    peer_data = load_yaml(peer_file)

    append_org(base_data, peer_data)

    write_yaml(filepath, base_data)

if __name__ == "__main__":
    run()
