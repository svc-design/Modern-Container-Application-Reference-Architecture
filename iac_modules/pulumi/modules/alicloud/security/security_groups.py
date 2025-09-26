from __future__ import annotations

from typing import Dict, Mapping, Optional

import pulumi
import pulumi_alicloud as alicloud

from ..common.tags import merge_tags


def create_security_groups(
    security_conf: Mapping[str, object],
    vpcs: Mapping[str, pulumi.Resource],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, pulumi.Resource]:
    groups_conf = security_conf.get("groups", []) or []
    security_groups: Dict[str, pulumi.Resource] = {}

    for group_conf in groups_conf:
        name = group_conf["name"]
        vpc_name = group_conf.get("vpc")
        vpc = vpcs.get(vpc_name) if vpc_name else None
        if vpc is None:
            pulumi.log.warn(f"Skip security group '{name}' because VPC '{vpc_name}' was not found")
            continue

        tags = merge_tags(default_tags, group_conf.get("tags"))
        sg = alicloud.ecs.SecurityGroup(
            name,
            security_group_name=group_conf.get("display_name", name),
            description=group_conf.get("description"),
            security_group_type=group_conf.get("type", "normal"),
            vpc_id=vpc.id,
            **({"tags": tags} if tags else {}),
            opts=pulumi.ResourceOptions(depends_on=[vpc]),
        )
        security_groups[name] = sg

        for index, rule in enumerate(group_conf.get("ingress", []) or []):
            _create_rule(sg, rule, "ingress", index)

        for index, rule in enumerate(group_conf.get("egress", []) or []):
            _create_rule(sg, rule, "egress", index)

    pulumi.export("security_group_ids", {name: sg.id for name, sg in security_groups.items()})
    return security_groups


def _create_rule(
    sg: pulumi.Resource,
    rule_conf: Mapping[str, object],
    rule_type: str,
    index: int,
) -> None:
    protocol = rule_conf.get("protocol", "all")
    cidr_ip = rule_conf.get("cidr_ip")
    ipv6_cidr_ip = rule_conf.get("ipv6_cidr_ip")
    source_sg = rule_conf.get("source_security_group_id")
    prefix_list_id = rule_conf.get("prefix_list_id")

    if not any([cidr_ip, ipv6_cidr_ip, source_sg, prefix_list_id]):
        pulumi.log.warn(
            f"Security group {sg._name} {rule_type} rule #{index} does not define a source/destination; skipping"
        )
        return

    args = {
        "security_group_id": sg.id,
        "type": rule_type,
        "ip_protocol": protocol,
        "port_range": rule_conf.get("port_range", "-1/-1"),
        "cidr_ip": cidr_ip,
        "ipv6_cidr_ip": ipv6_cidr_ip,
        "source_security_group_id": source_sg,
        "prefix_list_id": prefix_list_id,
        "policy": rule_conf.get("policy", "accept"),
        "description": rule_conf.get("description"),
        "priority": rule_conf.get("priority"),
        "nic_type": rule_conf.get("nic_type"),
    }
    args = {key: value for key, value in args.items() if value is not None}
    alicloud.ecs.SecurityGroupRule(
        f"{sg._name}-{rule_type}-{index}",
        **args,
        opts=pulumi.ResourceOptions(depends_on=[sg]),
    )
