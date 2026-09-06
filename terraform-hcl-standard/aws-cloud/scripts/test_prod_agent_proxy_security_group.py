#!/usr/bin/env python3
"""Contract check for the production Agent Proxy public ingress declaration."""

import os
import pathlib
import re
import sys

import yaml
from jinja2 import Environment, FileSystemLoader


root = pathlib.Path(__file__).resolve().parents[1]
config = root / "config/resources/prod/agent-proxy.yaml"
template_dir = root / "templates"

os.environ.setdefault("TARGET_DOMAIN_BASE", "svc.plus")
os.environ.setdefault("SSH_PUBLIC_DEPLOY_KEY", "ssh-ed25519 AAAAcontract")
from jinja2 import Template

data = yaml.safe_load(Template(config.read_text()).render(env=os.environ))
host = next(item for item in data["hosts"] if item["name"] == "agent-proxy-node-prod")
rules = host.get("security_group_ingress", [])
assert {(
    rule["port"], rule["protocol"], rule["cidr"]
) for rule in rules} >= {(1443, "tcp", "0.0.0.0/0")}

environment = Environment(loader=FileSystemLoader(template_dir))
environment.filters["tf_id"] = lambda value: re.sub(r"[^0-9a-zA-Z_]", "_", str(value))
template = environment.get_template("hosts.tf.j2")
rendered = template.render(ssh_keys=data["ssh_keys"], hosts=data["hosts"], true=True, false=False)
assert 'from_port   = 1443' in rendered
assert 'to_port     = 1443' in rendered
assert 'protocol    = "tcp"' in rendered
assert 'cidr_blocks = ["0.0.0.0/0"]' in rendered

us_host = next(item for item in data["hosts"] if item["name"] == "agent-proxy-node-prod-us")
assert us_host["aws_provider"] == "us"
assert us_host["aws_region"] == "us-east-1"
assert us_host["spot_instance"] is True
assert us_host["max_runtime_minutes"] == 60
assert us_host["elastic_ip"] is False
assert "agent-proxy-us.svc.plus" in us_host["host_vars"]["service_domains"]
assert "provider = aws.us" in rendered
assert "spot_instance       = true" in rendered
assert "max_runtime_minutes = 60" in rendered

print("test_prod_agent_proxy_security_group: PASS")
