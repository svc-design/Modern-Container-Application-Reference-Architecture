#!/usr/bin/env python3

import json
import subprocess
import os
import yaml
from collections import defaultdict

def get_pulumi_outputs():
    output = subprocess.check_output(["pulumi", "stack", "output", "--json"])
    return json.loads(output)

def merge_instance_config(config_dir="config"):
    merged = {}
    for fname in os.listdir(config_dir):
        if fname.endswith(".yaml"):
            with open(os.path.join(config_dir, fname)) as f:
                data = yaml.safe_load(f)
                if isinstance(data, dict):
                    merged.update(data)
    return merged.get("instances", [])

def build_inventory(pulumi_outputs, instance_cfgs):
    inventory = {"_meta": {"hostvars": {}}}
    groups = defaultdict(list)

    for inst in instance_cfgs:
        name = inst["name"]
        public_ip = pulumi_outputs.get(f"{name}_ip")

        if not public_ip:
            continue  # skip not created instances

        # 默认分组：all
        groups["all"].append(name)

        # 根据 subnet 或 lifecycle 添加分组
        if "subnet" in inst:
            groups[inst["subnet"]].append(name)
        if "lifecycle" in inst:
            groups[inst["lifecycle"]].append(name)

        # hostvars
        inventory["_meta"]["hostvars"][name] = {
            "ansible_host": public_ip,
            "ansible_user": "ubuntu",
            "instance_type": inst.get("type"),
            "ttl": inst.get("ttl", "none"),
            "lifecycle": inst.get("lifecycle", "ondemand"),
        }

    # 将分组注入 inventory
    for group, hosts in groups.items():
        inventory[group] = {"hosts": hosts}

    return inventory

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true')
    args = parser.parse_args()

    if args.list:
        pulumi_data = get_pulumi_outputs()
        instance_cfgs = merge_instance_config()
        inventory = build_inventory(pulumi_data, instance_cfgs)
        print(json.dumps(inventory, indent=2))
    else:
        print(json.dumps({}))

if __name__ == "__main__":
    main()
