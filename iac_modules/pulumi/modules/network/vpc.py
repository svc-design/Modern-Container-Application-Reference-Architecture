from __future__ import annotations

from typing import Dict, Mapping, Optional

import pulumi
import pulumi_alicloud as alicloud

from ..common.tags import merge_tags


def create_vpc_topology(
    network_conf: Mapping[str, object],
    default_tags: Optional[Mapping[str, str]] = None,
) -> Dict[str, Dict[str, pulumi.Resource]]:
    """Create VPCs and VSwitches as described in the network configuration."""
    vpcs_conf = network_conf.get("vpcs", []) or []

    vpcs: Dict[str, pulumi.Resource] = {}
    vswitches: Dict[str, pulumi.Resource] = {}

    for vpc_conf in vpcs_conf:
        name = vpc_conf["name"]
        vpc_tags = merge_tags(default_tags, vpc_conf.get("tags"))
        vpc = alicloud.vpc.Network(
            name,
            vpc_name=vpc_conf.get("display_name", name),
            cidr_block=vpc_conf["cidr_block"],
            description=vpc_conf.get("description"),
            **({"tags": vpc_tags} if vpc_tags else {}),
        )
        vpcs[name] = vpc

        for switch_conf in vpc_conf.get("vswitches", []) or []:
            switch_name = switch_conf["name"]
            switch_tags = merge_tags(vpc_tags, switch_conf.get("tags"))
            vswitch = alicloud.vpc.Switch(
                switch_name,
                vswitch_name=switch_conf.get("display_name", switch_name),
                vpc_id=vpc.id,
                cidr_block=switch_conf["cidr_block"],
                zone_id=switch_conf["zone_id"],
                description=switch_conf.get("description"),
                **({"tags": switch_tags} if switch_tags else {}),
                opts=pulumi.ResourceOptions(depends_on=[vpc]),
            )
            vswitches[switch_name] = vswitch

    pulumi.export("vpc_ids", {name: vpc.id for name, vpc in vpcs.items()})
    pulumi.export("vswitch_ids", {name: sw.id for name, sw in vswitches.items()})

    return {"vpcs": vpcs, "vswitches": vswitches}
