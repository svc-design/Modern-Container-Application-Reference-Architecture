"""Compute provisioning helpers for Vultr."""

from __future__ import annotations

from typing import Any, Dict, Mapping

import pulumi
import ediri_vultr as vultr

from ..common import merge_tags


def create_instances(
    compute_config: Mapping[str, Any],
    default_region: str | None,
    default_tags: Mapping[str, str] | None,
    firewall_groups: Mapping[str, Dict[str, object]],
    vpcs: Mapping[str, vultr.Vpc],
) -> Dict[str, vultr.Instance]:
    """Provision baseline compute instances."""
    results: Dict[str, vultr.Instance] = {}

    instances = compute_config.get("instances", [])
    if not isinstance(instances, list):
        pulumi.log.warn("compute.instances 配置不是列表，将跳过实例创建")
        return results

    for index, inst_conf in enumerate(instances):
        if not isinstance(inst_conf, Mapping):
            pulumi.log.warn(f"忽略索引 {index} 的实例配置，因其不是字典结构")
            continue

        name = inst_conf.get("name") or f"instance-{index}"
        region = inst_conf.get("region", default_region)
        plan = inst_conf.get("plan")
        if not (region and plan):
            raise ValueError(f"实例 {name} 缺少必要的 region 或 plan 参数")

        resource_name = inst_conf.get("resource_name", name.replace("_", "-"))

        instance_args: Dict[str, Any] = {
            "region": region,
            "plan": plan,
        }

        optional_fields = [
            "os_id",
            "image_id",
            "hostname",
            "label",
            "enable_ipv6",
            "backups",
            "user_data",
            "activation_email",
            "ddos_protection",
            "disable_public_ipv4",
            "reserved_ip_id",
            "script_id",
            "snapshot_id",
            "user_scheme",
        ]
        for field in optional_fields:
            if field in inst_conf:
                instance_args[field] = inst_conf[field]

        if ssh_keys := inst_conf.get("ssh_key_ids"):
            instance_args["ssh_key_ids"] = ssh_keys

        tags = merge_tags(default_tags, inst_conf.get("tags"))
        if tags:
            instance_args["tags"] = tags

        firewall_group_name = inst_conf.get("firewall_group")
        if firewall_group_name:
            group = firewall_groups.get(firewall_group_name)
            if not group:
                raise KeyError(
                    f"实例 {name} 引用了未定义的防火墙组 '{firewall_group_name}'"
                )
            instance_args["firewall_group_id"] = group["group"].id

        vpc_names = inst_conf.get("vpcs", [])
        if vpc_names:
            resolved_vpc_ids = []
            for vpc_name in vpc_names:
                vpc_resource = vpcs.get(vpc_name)
                if not vpc_resource:
                    raise KeyError(
                        f"实例 {name} 引用了未定义的 VPC '{vpc_name}'"
                    )
                resolved_vpc_ids.append(vpc_resource.id)
            instance_args["vpc_ids"] = resolved_vpc_ids

        instance = vultr.Instance(resource_name, **instance_args)
        results[name] = instance
        pulumi.export(f"instance::{name}::id", instance.id)

    return results
