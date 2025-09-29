"""VPC provisioning helpers for Vultr."""

from __future__ import annotations

from typing import Any, Dict, Mapping

import pulumi
import ediri_vultr as vultr


def create_vpcs(
    network_config: Mapping[str, Any],
    default_region: str | None,
) -> Dict[str, vultr.Vpc]:
    """Create Vultr VPC networks from configuration."""
    vpc_results: Dict[str, vultr.Vpc] = {}

    vpcs = network_config.get("vpcs", [])
    if not isinstance(vpcs, list):
        pulumi.log.warn("network.vpcs 配置不是列表，将跳过 VPC 创建")
        return vpc_results

    for index, vpc_conf in enumerate(vpcs):
        if not isinstance(vpc_conf, Mapping):
            pulumi.log.warn(f"忽略索引 {index} 的 VPC 配置，因其不是字典结构")
            continue

        name = vpc_conf.get("name") or f"vpc-{index}"
        region = vpc_conf.get("region", default_region)
        if not region:
            raise ValueError(f"VPC '{name}' 缺少 region 参数且未设置默认 region")

        v4_subnet = vpc_conf.get("v4_subnet")
        v4_subnet_mask = vpc_conf.get("v4_subnet_mask")
        if not (v4_subnet and v4_subnet_mask is not None):
            raise ValueError(
                f"VPC '{name}' 需要提供 v4_subnet 与 v4_subnet_mask 用于定义网络范围"
            )

        description = vpc_conf.get("description", f"VPC network for {name}")
        resource_name = vpc_conf.get("resource_name", name.replace("_", "-"))

        vpc = vultr.Vpc(
            resource_name,
            region=region,
            description=description,
            v4_subnet=v4_subnet,
            v4_subnet_mask=int(v4_subnet_mask),
        )
        vpc_results[name] = vpc
        pulumi.export(f"vpc::{name}::id", vpc.id)

    return vpc_results
