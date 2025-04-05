#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import argparse
from pathlib import Path
from jinja2 import Template
from collections import defaultdict

# ========== Pulumi Output ==========
def get_pulumi_outputs(pulumi_dir: Path):
    try:
        output = subprocess.check_output(
            ["pulumi", "stack", "output", "--json"],
            cwd=pulumi_dir,
            env=os.environ
        )
        return json.loads(output)
    except subprocess.CalledProcessError as e:
        print("[ERROR] Failed to get Pulumi outputs.")
        print(e.output.decode(), file=sys.stderr)
        return {}
    except FileNotFoundError:
        print("[ERROR] 'pulumi' command not found.")
        sys.exit(1)

# ========== Build JSON Inventory ==========
def build_inventory_from_outputs(outputs):
    inventory = {"_meta": {"hostvars": {}}}
    groups = defaultdict(list)

    for key, value in outputs.items():
        if key.endswith("_public_ip"):
            name = key.replace("_public_ip", "")
            ip = value
            groups["all"].append(name)
            inventory["_meta"]["hostvars"][name] = {
                "ansible_host": ip,
                "ansible_user": os.getenv("SSH_USER", "ubuntu"),
                "cloud": "aws"  # 默认值，可扩展为智能识别
            }

    for group, hosts in groups.items():
        inventory[group] = {"hosts": hosts}

    return inventory

# ========== Static INI Inventory ==========
inventory_template = """\
{% set max_len = groups['all'] | map(attribute='name') | map('length') | max %}
{% for group, hosts in groups.items() %}
[{{ group }}]
{% for host in hosts -%}
{{ "{:<{width}}".format(host.name, width=max_len) }} ansible_host={{ host.ip }}
{% endfor %}

{% endfor -%}
[all:vars]
ansible_port=22
ansible_ssh_user={{ ssh_user }}
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_host_key_checking=False
"""

def build_static_inventory(outputs):
    groups = defaultdict(list)
    for key, value in outputs.items():
        if key.endswith("_public_ip"):
            name = key.replace("_public_ip", "")
            groups["all"].append({"name": name, "ip": value})
    return groups

# ========== Main ==========
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true', help="Output dynamic inventory (JSON)")
    parser.add_argument('--host', help="Output host-specific variables")
    parser.add_argument('--export-static', action='store_true', help="Export static inventory to hosts/inventory")
    parser.add_argument('--pulumi-dir', default="iac_modules/pulumi", help="Path to Pulumi stack directory")
    parser.add_argument('--passphrase-file', default="~/.pulumi-passphrase", help="Path to Pulumi config passphrase file")
    args = parser.parse_args()

    # 解析目录
    base_dir = Path(__file__).resolve().parent.parent
    pulumi_dir = (base_dir / args.pulumi_dir).resolve()
    passphrase_file = Path(args.passphrase_file).expanduser().resolve()

    # 设置默认 Pulumi 密码环境变量
    if "PULUMI_CONFIG_PASSPHRASE_FILE" not in os.environ and "PULUMI_CONFIG_PASSPHRASE" not in os.environ:
        if not passphrase_file.exists():
            print(f"[ERROR] Pulumi passphrase file not found at {passphrase_file}")
            sys.exit(1)
        os.environ["PULUMI_CONFIG_PASSPHRASE_FILE"] = str(passphrase_file)

    # 获取 Pulumi 输出
    outputs = get_pulumi_outputs(pulumi_dir)
    inventory = build_inventory_from_outputs(outputs)

    if args.list:
        print(json.dumps(inventory, indent=2))
        return

    if args.host:
        hostvars = inventory.get('_meta', {}).get('hostvars', {})
        print(json.dumps(hostvars.get(args.host, {}), indent=2))
        return

    if args.export_static:
        groups = build_static_inventory(outputs)
        ssh_user = os.getenv("SSH_USER", "ubuntu")
        template = Template(inventory_template)
        output = template.render(groups=groups, ssh_user=ssh_user)
        os.makedirs("hosts", exist_ok=True)
        with open("hosts/inventory", "w") as f:
            f.write(output)
        print("✅ Static inventory written to hosts/inventory")
        return

    print(json.dumps({}))  # fallback

if __name__ == "__main__":
    main()
