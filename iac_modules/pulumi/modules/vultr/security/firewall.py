"""Firewall provisioning helpers for Vultr."""

from __future__ import annotations

import ipaddress
from typing import Any, Dict, List, Mapping

import pulumi
import ediri_vultr as vultr


def create_firewall_groups(
    security_config: Mapping[str, Any],
) -> Dict[str, Dict[str, object]]:
    """Create Vultr firewall groups and rules."""
    results: Dict[str, Dict[str, object]] = {}

    groups = security_config.get("firewall_groups", [])
    if not isinstance(groups, list):
        pulumi.log.warn("security.firewall_groups 配置不是列表，将跳过防火墙创建")
        return results

    for index, group_conf in enumerate(groups):
        if not isinstance(group_conf, Mapping):
            pulumi.log.warn(f"忽略索引 {index} 的防火墙配置，因其不是字典结构")
            continue

        name = group_conf.get("name") or f"firewall-{index}"
        description = group_conf.get("description", f"Baseline firewall group {name}")
        resource_name = group_conf.get("resource_name", name.replace("_", "-"))

        firewall_group = vultr.FirewallGroup(resource_name, description=description)

        rules_conf = group_conf.get("rules", [])
        if not isinstance(rules_conf, list):
            pulumi.log.warn(f"防火墙 {name} 的 rules 配置不是列表，将跳过规则创建")
            rules_conf = []

        rules: List[vultr.FirewallRule] = []
        for rule_index, rule_conf in enumerate(rules_conf):
            if not isinstance(rule_conf, Mapping):
                pulumi.log.warn(
                    f"忽略防火墙 {name} 中索引 {rule_index} 的规则配置，因其不是字典结构"
                )
                continue

            cidr = rule_conf.get("cidr")
            ip_type = rule_conf.get("ip_type", "v4")
            if not cidr:
                pulumi.log.warn(
                    f"防火墙 {name} 规则 {rule_conf.get('name', rule_index)} 缺少 cidr，将跳过"
                )
                continue

            network = ipaddress.ip_network(cidr, strict=False)
            if (ip_type == "v6" and network.version != 6) or (
                ip_type == "v4" and network.version != 4
            ):
                pulumi.log.warn(
                    f"防火墙 {name} 规则 {rule_conf.get('name', rule_index)} 的 cidr 与 ip_type 不匹配"
                )
                continue

            rule_name = rule_conf.get("name") or f"rule-{rule_index}"
            rule_resource_name = f"{resource_name}-{rule_name}".replace("_", "-")

            rule = vultr.FirewallRule(
                rule_resource_name,
                firewall_group_id=firewall_group.id,
                protocol=rule_conf.get("protocol", "tcp"),
                ip_type=ip_type,
                subnet=str(network.network_address),
                subnet_size=network.prefixlen,
                port=rule_conf.get("port"),
                notes=rule_conf.get("notes"),
                source=rule_conf.get("source"),
            )
            rules.append(rule)

        results[name] = {"group": firewall_group, "rules": rules}
        pulumi.export(f"firewall::{name}::id", firewall_group.id)
        pulumi.export(f"firewall::{name}::rule_count", len(rules))

    return results
