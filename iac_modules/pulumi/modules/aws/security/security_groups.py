from __future__ import annotations

from typing import Dict, Iterable, Mapping, Optional

import pulumi
import pulumi_aws as aws

from ..common.tags import merge_tags

RuleConfig = Mapping[str, object]


def _normalize_rules(rules: Optional[Iterable[RuleConfig]]) -> Iterable[RuleConfig]:
    return rules or []


def _protocol_value(protocol: str) -> str:
    proto = protocol.lower()
    if proto in {"all", "any", "-1"}:
        return "-1"
    return proto


def _port_bounds(rule: RuleConfig) -> tuple[int, int]:
    if "from_port" in rule or "to_port" in rule:
        return int(rule.get("from_port", -1)), int(rule.get("to_port", -1))
    port_range = rule.get("port_range")
    if isinstance(port_range, str) and "/" in port_range:
        start, end = port_range.split("/", 1)
        return int(start), int(end)
    ports = rule.get("ports")
    if isinstance(ports, Iterable) and not isinstance(ports, (str, bytes)):
        values = [int(p) for p in ports]
        if values:
            return min(values), max(values)
    # Default ICMP or all traffic
    return -1, -1


def _cidr_blocks(rule: RuleConfig, key: str = "cidr_blocks") -> list[str]:
    cidrs = rule.get(key)
    if isinstance(cidrs, str):
        return [cidrs]
    if isinstance(cidrs, Iterable):
        return [str(cidr) for cidr in cidrs]
    cidr_ip = rule.get("cidr_ip")
    if cidr_ip:
        return [str(cidr_ip)]
    return ["0.0.0.0/0"]


def _build_ingress(rule: RuleConfig) -> aws.ec2.SecurityGroupIngressArgs:
    protocol = _protocol_value(str(rule.get("protocol", "tcp")))
    from_port, to_port = _port_bounds(rule)
    if protocol == "icmp":
        from_port = to_port = -1
    return aws.ec2.SecurityGroupIngressArgs(
        protocol=protocol,
        from_port=from_port,
        to_port=to_port,
        cidr_blocks=_cidr_blocks(rule),
        description=rule.get("description"),
    )


def _build_egress(rule: RuleConfig) -> aws.ec2.SecurityGroupEgressArgs:
    protocol = _protocol_value(str(rule.get("protocol", "all")))
    from_port, to_port = _port_bounds(rule)
    if protocol == "icmp":
        from_port = to_port = -1
    return aws.ec2.SecurityGroupEgressArgs(
        protocol=protocol,
        from_port=from_port,
        to_port=to_port,
        cidr_blocks=_cidr_blocks(rule),
        description=rule.get("description"),
    )


def create_security_groups(
    security_conf: Mapping[str, object],
    vpcs: Mapping[str, aws.ec2.Vpc],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, aws.ec2.SecurityGroup]:
    """Create security groups inside the provided VPC map."""

    groups_conf = security_conf.get("groups", []) or []
    security_groups: Dict[str, aws.ec2.SecurityGroup] = {}

    for group_conf in groups_conf:
        group_name = group_conf["name"]
        vpc_name = group_conf.get("vpc")
        if vpc_name not in vpcs:
            pulumi.log.warn(
                f"Security group '{group_name}' references unknown VPC '{vpc_name}', skipping"
            )
            continue
        vpc = vpcs[vpc_name]
        group_tags = merge_tags(default_tags, group_conf.get("tags"))

        ingress = [
            _build_ingress(rule) for rule in _normalize_rules(group_conf.get("ingress"))
        ]
        egress_rules = list(_normalize_rules(group_conf.get("egress")))
        if not egress_rules:
            egress_rules = [
                {
                    "protocol": "all",
                    "from_port": 0,
                    "to_port": 0,
                    "cidr_blocks": ["0.0.0.0/0"],
                    "description": "Baseline allow all egress",
                }
            ]
        egress = [_build_egress(rule) for rule in egress_rules]

        security_group = aws.ec2.SecurityGroup(
            group_name,
            name=group_conf.get("display_name", group_name),
            description=group_conf.get(
                "description", f"Security group for {group_name}"
            ),
            vpc_id=vpc.id,
            ingress=ingress,
            egress=egress,
            **({"tags": group_tags} if group_tags else {}),
            opts=pulumi.ResourceOptions(depends_on=[vpc]),
        )

        security_groups[group_name] = security_group

    pulumi.export(
        "security_groups",
        {name: sg.id for name, sg in security_groups.items()},
    )

    return security_groups
